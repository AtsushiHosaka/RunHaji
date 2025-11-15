# Supabase Database Schema

## Overview

This document defines the database schema for the RunHaji application using Supabase PostgreSQL.

## Tables

### 1. users
Supabase Auth will handle user authentication. We'll use the auth.users table's UUID as the foreign key.

```sql
-- This table is managed by Supabase Auth
-- We reference auth.users(id) in other tables
```

### 2. user_profiles
User profile information collected during onboarding.

```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  email TEXT,
  age INTEGER,
  height DOUBLE PRECISION,  -- cm
  weight DOUBLE PRECISION,  -- kg
  available_time_per_week INTEGER,  -- hours
  ideal_frequency INTEGER,  -- times per week
  current_frequency INTEGER,  -- times per week
  goal TEXT,  -- RunningGoal enum as string
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- RLS (Row Level Security)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

### 3. roadmaps
User's personalized running roadmap.

```sql
CREATE TABLE roadmaps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  goal TEXT NOT NULL,  -- RunningGoal enum as string
  target_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- RLS
ALTER TABLE roadmaps ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own roadmaps"
  ON roadmaps FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own roadmaps"
  ON roadmaps FOR ALL
  USING (auth.uid() = user_id);
```

### 4. milestones
Milestones within a roadmap.

```sql
CREATE TABLE milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  roadmap_id UUID REFERENCES roadmaps(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  target_date TIMESTAMPTZ,
  is_completed BOOLEAN DEFAULT FALSE NOT NULL,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Constraint: if is_completed is true, completed_at must be set
  CONSTRAINT milestone_completion_consistency
    CHECK ((is_completed = TRUE AND completed_at IS NOT NULL) OR
           (is_completed = FALSE AND completed_at IS NULL))
);

-- RLS
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view milestones of own roadmaps"
  ON milestones FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM roadmaps
    WHERE roadmaps.id = milestones.roadmap_id
    AND roadmaps.user_id = auth.uid()
  ));

CREATE POLICY "Users can manage milestones of own roadmaps"
  ON milestones FOR ALL
  USING (EXISTS (
    SELECT 1 FROM roadmaps
    WHERE roadmaps.id = milestones.roadmap_id
    AND roadmaps.user_id = auth.uid()
  ));
```

### 5. workout_sessions
Individual workout session records.

```sql
CREATE TABLE workout_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  duration DOUBLE PRECISION NOT NULL,  -- seconds
  distance DOUBLE PRECISION NOT NULL,  -- meters
  calories DOUBLE PRECISION NOT NULL,  -- kcal
  rpe INTEGER,  -- Rate of Perceived Exertion (1-10)
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Constraints
  CONSTRAINT valid_duration CHECK (duration > 0),
  CONSTRAINT valid_distance CHECK (distance >= 0),
  CONSTRAINT valid_calories CHECK (calories >= 0),
  CONSTRAINT valid_rpe CHECK (rpe IS NULL OR (rpe >= 1 AND rpe <= 10)),
  CONSTRAINT valid_dates CHECK (end_date > start_date)
);

-- Indexes
CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_start_date ON workout_sessions(start_date DESC);

-- RLS
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own workout sessions"
  ON workout_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own workout sessions"
  ON workout_sessions FOR ALL
  USING (auth.uid() = user_id);
```

### 6. workout_reflections
AI-generated reflections and suggestions for workout sessions.

```sql
CREATE TABLE workout_reflections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_session_id UUID REFERENCES workout_sessions(id) ON DELETE CASCADE NOT NULL UNIQUE,
  estimated_rpe INTEGER NOT NULL,  -- AI-estimated RPE (1-10)
  reflection TEXT NOT NULL,  -- AI-generated reflection
  suggestions TEXT NOT NULL,  -- AI-generated suggestions
  milestone_id UUID REFERENCES milestones(id) ON DELETE SET NULL,  -- Associated milestone if achieved
  is_milestone_achieved BOOLEAN DEFAULT FALSE NOT NULL,
  achievement_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Constraints
  CONSTRAINT valid_estimated_rpe CHECK (estimated_rpe >= 1 AND estimated_rpe <= 10),
  CONSTRAINT milestone_achievement_consistency
    CHECK ((is_milestone_achieved = TRUE AND milestone_id IS NOT NULL AND achievement_message IS NOT NULL) OR
           (is_milestone_achieved = FALSE))
);

-- Indexes
CREATE INDEX idx_workout_reflections_workout_session_id ON workout_reflections(workout_session_id);
CREATE INDEX idx_workout_reflections_milestone_id ON workout_reflections(milestone_id);

-- RLS
ALTER TABLE workout_reflections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own workout reflections"
  ON workout_reflections FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM workout_sessions
    WHERE workout_sessions.id = workout_reflections.workout_session_id
    AND workout_sessions.user_id = auth.uid()
  ));

CREATE POLICY "Users can manage own workout reflections"
  ON workout_reflections FOR ALL
  USING (EXISTS (
    SELECT 1 FROM workout_sessions
    WHERE workout_sessions.id = workout_reflections.workout_session_id
    AND workout_sessions.user_id = auth.uid()
  ));
```

### 7. upcoming_workouts
Planned/suggested workouts for the user.

```sql
CREATE TABLE upcoming_workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  estimated_duration DOUBLE PRECISION NOT NULL,  -- seconds
  target_distance DOUBLE PRECISION,  -- meters
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Constraints
  CONSTRAINT valid_estimated_duration CHECK (estimated_duration > 0),
  CONSTRAINT valid_target_distance CHECK (target_distance IS NULL OR target_distance > 0)
);

-- Indexes
CREATE INDEX idx_upcoming_workouts_user_id ON upcoming_workouts(user_id);

-- RLS
ALTER TABLE upcoming_workouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own upcoming workouts"
  ON upcoming_workouts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own upcoming workouts"
  ON upcoming_workouts FOR ALL
  USING (auth.uid() = user_id);
```

## Triggers

### Auto-update updated_at timestamp

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roadmaps_updated_at
  BEFORE UPDATE ON roadmaps
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_milestones_updated_at
  BEFORE UPDATE ON milestones
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## Data Migration Notes

Current data is stored in UserDefaults with the following keys:
- `user_profile` → user_profiles table
- `user_roadmap` → roadmaps + milestones tables
- `workout_sessions` → workout_sessions table
- `workout_reflections` → workout_reflections table
- `upcoming_workouts` → upcoming_workouts table

## Setup Instructions

1. Create a new Supabase project
2. Run the SQL schema above in the Supabase SQL Editor
3. Enable Row Level Security (RLS) on all tables
4. Configure authentication (email/password or anonymous auth)
5. Add SUPABASE_URL and SUPABASE_ANON_KEY to Info.plist

## API Endpoints

Supabase automatically generates REST API endpoints:
- `GET /rest/v1/user_profiles` - Get user profile
- `POST /rest/v1/workout_sessions` - Create workout session
- `GET /rest/v1/workout_sessions?user_id=eq.{uuid}` - Get user's workouts
- etc.

The Supabase Swift SDK provides type-safe access to these endpoints.
