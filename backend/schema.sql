-- Enable UUID extension first
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Custom Types
CREATE TYPE user_role AS ENUM ('coach', 'athlete');
CREATE TYPE program_type AS ENUM ('template', 'custom');
CREATE TYPE difficulty_level AS ENUM ('Beginner', 'Intermediate', 'Advanced');
CREATE TYPE intensity_type AS ENUM ('rir', 'rpe', 'percentage', 'absolute');

-- Users Table
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL,
    coach_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);

-- Athletes-Coaches Relationship Table
CREATE TABLE athletes_coaches (
    athlete_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    coach_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    PRIMARY KEY (athlete_id, coach_id)
);

-- Programs Table
CREATE TABLE programs (
    program_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    creator_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    days_per_week INTEGER CHECK (days_per_week BETWEEN 1 AND 7),
    number_of_workouts INTEGER NOT NULL,
    program_type program_type DEFAULT 'template',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Workouts Table
CREATE TABLE workouts (
    workout_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    creator_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    program_id UUID REFERENCES programs(program_id) ON DELETE SET NULL,
    date TIMESTAMP NOT NULL,
    description TEXT,
    workout_number INTEGER CHECK (workout_number > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exercises Table
CREATE TABLE exercises (
    exercise_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    equipment VARCHAR(50),
    body_part VARCHAR(50),
    difficulty difficulty_level DEFAULT 'Beginner',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exercise Tags Table
CREATE TABLE exercise_tags (
    tag_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

-- Exercise-Tag Mapping Table
CREATE TABLE exercise_tag_map (
    exercise_id UUID NOT NULL REFERENCES exercises(exercise_id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES exercise_tags(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (exercise_id, tag_id)
);

-- Prescribed Exercises Table
CREATE TABLE prescribed_exercises (
    prescription_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_id UUID NOT NULL REFERENCES workouts(workout_id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(exercise_id) ON DELETE CASCADE,
    prescribed_sets INTEGER NOT NULL CHECK (prescribed_sets > 0),
    prescribed_reps INTEGER CHECK (prescribed_reps > 0),
    intensity_method intensity_type NOT NULL,
    intensity_value DECIMAL(5, 2) NOT NULL,
    notes TEXT,
    UNIQUE(workout_id, exercise_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exercise Logs Table
CREATE TABLE exercise_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_id UUID NOT NULL REFERENCES workouts(workout_id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(exercise_id) ON DELETE CASCADE,
    prescription_id UUID REFERENCES prescribed_exercises(prescription_id) ON DELETE SET NULL,
    date_completed TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sets INTEGER NOT NULL CHECK (sets > 0),
    reps INTEGER CHECK (reps > 0),
    weight DECIMAL(5, 2),
    distance DECIMAL(5, 2),
    duration INTERVAL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for Optimization
CREATE INDEX idx_logs_workout_exercise ON exercise_logs(workout_id, exercise_id);
CREATE INDEX idx_prescriptions_workout_exercise ON prescribed_exercises(workout_id, exercise_id);
CREATE INDEX idx_athletes_coaches_coach_id ON athletes_coaches(coach_id);
CREATE INDEX idx_athletes_coaches_athlete_id ON athletes_coaches(athlete_id);

-- Create function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for all tables with updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_programs_updated_at
    BEFORE UPDATE ON programs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workouts_updated_at
    BEFORE UPDATE ON workouts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exercises_updated_at
    BEFORE UPDATE ON exercises
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prescribed_exercises_updated_at
    BEFORE UPDATE ON prescribed_exercises
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exercise_logs_updated_at
    BEFORE UPDATE ON exercise_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Additional index for program lookups
CREATE INDEX idx_workouts_program ON workouts(program_id);
