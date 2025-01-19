package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/joho/godotenv"
	"github.com/lib/pq"
	"github.com/rs/cors"
	"golang.org/x/crypto/bcrypt"
)

var db *sql.DB

type User struct {
	ID        string `json:"id"`
	FirstName string `json:"firstName"`
	LastName  string `json:"lastName"`
	Email     string `json:"email"`
	Password  string `json:"password,omitempty"`
	Role      string `json:"role"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// Add JWT claims struct
type Claims struct {
	UserID string `json:"userId"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

// Add JWT response
type LoginResponse struct {
	User  User   `json:"user"`
	Token string `json:"token"`
}

func initDB() error {
	if err := godotenv.Load(); err != nil {
		return fmt.Errorf("error loading .env file: %v", err)
	}

	connStr := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_NAME"),
	)

	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		return fmt.Errorf("error opening database: %v", err)
	}

	if err = db.Ping(); err != nil {
		return fmt.Errorf("error connecting to database: %v", err)
	}

	return nil
}

func generateToken(user User) (string, error) {
	claims := Claims{
		user.ID,
		user.Role,
		jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(os.Getenv("JWT_SECRET")))
}

func setTokenCookie(w http.ResponseWriter, token string) {
	http.SetCookie(w, &http.Cookie{
		Name:     "token",
		Value:    token,
		Path:     "/",
		HttpOnly: true,
		Secure:   false,
		SameSite: http.SameSiteLaxMode,
		MaxAge:   86400,
	})
	w.Header().Set("Access-Control-Allow-Credentials", "true")
}

func main() {
	if err := initDB(); err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// Setup CORS
	corsMiddleware := cors.New(cors.Options{
		AllowedOrigins:   []string{os.Getenv("CORS_ORIGIN")},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "Origin"},
		AllowCredentials: true,
		ExposedHeaders:   []string{"Set-Cookie"},
	})

	const port = "8080"
	mux := http.NewServeMux()

	mux.HandleFunc("/api/register", createAccountHandler)
	mux.HandleFunc("/api/login", loginHandler)
	mux.HandleFunc("/api/verify", verifyHandler)

	handler := corsMiddleware.Handler(mux)

	server := &http.Server{
		Addr:    ":" + port,
		Handler: handler,
	}

	log.Printf("Server running on port: %s\n", port)
	log.Fatal(server.ListenAndServe())
}

func createAccountHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var user User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate required fields
	if user.Email == "" || user.Password == "" || user.FirstName == "" || user.LastName == "" || user.Role == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("Password hashing error: %v", err)
		http.Error(w, "Error creating account", http.StatusInternalServerError)
		return
	}

	// Insert user into database
	query := `
		INSERT INTO users (first_name, last_name, email, password_hash, role)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING user_id`

	var userID string
	err = db.QueryRow(query, user.FirstName, user.LastName, user.Email, string(hashedPassword), user.Role).Scan(&userID)
	if err != nil {
		if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" {
			http.Error(w, "Email already exists", http.StatusConflict)
			return
		}
		log.Printf("Database error: %v", err)
		http.Error(w, "Error creating account", http.StatusInternalServerError)
		return
	}

	user.ID = userID
	user.Password = "" // Remove password from response

	// Generate JWT token
	token, err := generateToken(user)
	if err != nil {
		log.Printf("Token generation error: %v", err)
		http.Error(w, "Error creating account", http.StatusInternalServerError)
		return
	}

	setTokenCookie(w, token)

	response := LoginResponse{
		User:  user,
		Token: "", // Don't send token in response body
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

func loginHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var loginReq LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&loginReq); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	var user User
	var hashedPassword string
	query := `
		SELECT user_id, first_name, last_name, email, password_hash, role 
		FROM users 
		WHERE email = $1`

	err := db.QueryRow(query, loginReq.Email).Scan(
		&user.ID,
		&user.FirstName,
		&user.LastName,
		&user.Email,
		&hashedPassword,
		&user.Role,
	)

	if err == sql.ErrNoRows {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	} else if err != nil {
		log.Printf("Database error: %v", err)
		http.Error(w, "Error processing request", http.StatusInternalServerError)
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(loginReq.Password)); err != nil {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	// Generate JWT token
	token, err := generateToken(user)
	if err != nil {
		log.Printf("Token generation error: %v", err)
		http.Error(w, "Error processing request", http.StatusInternalServerError)
		return
	}

	setTokenCookie(w, token)

	response := LoginResponse{
		User:  user,
		Token: "", // Don't send token in response body
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func verifyHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	cookie, err := r.Cookie("token")
	if err != nil {
		fmt.Println("Invalid cookie")
		fmt.Printf("Token %v", cookie)
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	token, err := jwt.ParseWithClaims(cookie.Value, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(os.Getenv("JWT_SECRET")), nil
	})

	if err != nil || !token.Valid {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	claims, ok := token.Claims.(*Claims)
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	// Fetch user data
	var user User
	query := `SELECT user_id, first_name, last_name, email, role FROM users WHERE user_id = $1`
	err = db.QueryRow(query, claims.UserID).Scan(&user.ID, &user.FirstName, &user.LastName, &user.Email, &user.Role)
	if err != nil {
		http.Error(w, "User not found", http.StatusUnauthorized)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}
