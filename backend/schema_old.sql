-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables if they exist (in reverse order of dependencies)
DROP TABLE IF EXISTS progress CASCADE;
DROP TABLE IF EXISTS workout_exercises CASCADE;
DROP TABLE IF EXISTS athlete_maxes CASCADE;
DROP TABLE IF EXISTS exercises CASCADE;
DROP TABLE IF EXISTS workouts CASCADE;
DROP TABLE IF EXISTS programs CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users Table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR NOT NULL,
  email VARCHAR UNIQUE NOT NULL,
  password_hash VARCHAR NOT NULL,
  role VARCHAR NOT NULL CHECK (role IN ('coach', 'athlete')),
  specializations TEXT,  -- Only for coaches
  self_guided BOOLEAN DEFAULT false  -- Only for athletes
);

-- Athletes Table


-- Programs Table
CREATE TABLE programs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR NOT NULL,
  description TEXT,
  coach_id UUID REFERENCES users(id),  -- Coach's program (null if self-guided)
  athlete_id UUID REFERENCES users(id), -- Athlete's program (if self-guided)
  days_per_week INTEGER CHECK (days_per_week BETWEEN 1 AND 7)
);

-- Workouts Table
CREATE TABLE workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  program_id UUID REFERENCES programs(id),
  date TIMESTAMP,
  athlete_id UUID REFERENCES users(id),
  coach_id UUID REFERENCES users(id),
  details TEXT,
  "order" INTEGER  -- Order of workouts in a program
);

-- Exercises Table
CREATE TABLE exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR NOT NULL,
  category VARCHAR, -- Olympic lift, Accessory, Strength, Cardio, etc.
  description TEXT,
  type VARCHAR,     -- Strength, Mobility, Cardio, etc.
  equipment VARCHAR, -- Equipment required
  body_part VARCHAR -- Body part that the workout hits
);

-- Athlete Maxes Table
CREATE TABLE athlete_maxes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES users(id),
  exercise_id UUID REFERENCES exercises(id),
  max_weight FLOAT,
  date TIMESTAMP
);

-- Workout Exercises Table (Junction)
CREATE TABLE workout_exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_id UUID REFERENCES workouts(id),
  exercise_id UUID REFERENCES exercises(id),
  "order" INTEGER -- Order of exercises in the workout
);

-- Progress Table
CREATE TABLE progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES users(id),
  workout_id UUID REFERENCES workouts(id),
  exercise_id UUID REFERENCES exercises(id),
  prescribed_weight FLOAT,
  actual_weight FLOAT,
  reps INTEGER,
  date TIMESTAMP,
  status VARCHAR CHECK (status IN ('Goal met', 'near goal', 'goal missed')),
  comment TEXT
);

-- Add indexes for foreign keys and frequently queried columns
CREATE INDEX idx_programs_coach ON programs(coach_id);
CREATE INDEX idx_programs_athlete ON programs(athlete_id);
CREATE INDEX idx_workouts_program ON workouts(program_id);
CREATE INDEX idx_workouts_athlete ON workouts(athlete_id);
CREATE INDEX idx_workouts_coach ON workouts(coach_id);
CREATE INDEX idx_progress_athlete ON progress(athlete_id);
CREATE INDEX idx_progress_workout ON progress(workout_id);
CREATE INDEX idx_workout_exercises_workout ON workout_exercises(workout_id);
CREATE INDEX idx_workout_exercises_exercise ON workout_exercises(exercise_id);
CREATE INDEX idx_athlete_maxes_athlete ON athlete_maxes(athlete_id);
CREATE INDEX idx_athlete_maxes_exercise ON athlete_maxes(exercise_id); 
