-- Ponytail SQL Schema (Lazy & Efficient)
-- Run this in your Supabase SQL Editor.

-- 1. Companions Table
-- We create this first since profiles will reference it.
CREATE TABLE companions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  description TEXT,
  asset_path TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Insert some default companions based on the "Pokemon-style" selection
INSERT INTO companions (name, type, description, asset_path) VALUES 
('Lumina', 'Light', 'A calming presence to guide your focus.', 'assets/companions/lumina.riv'),
('Terra', 'Earth', 'Grounded and steady, perfect for building habits.', 'assets/companions/terra.riv'),
('Zephyr', 'Wind', 'Light and breezy, helps clear your mind.', 'assets/companions/zephyr.riv');


-- 2. Profiles Table
-- Ties into Supabase's native auth.users table automatically
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  current_xp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  current_streak INTEGER DEFAULT 0,
  selected_companion_id UUID REFERENCES companions(id),
  onboarding_profile JSONB, -- JSONB is perfect here instead of 5 different tables
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS (Row Level Security) so users can only read/update their own profile
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Trigger to automatically create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (new.id);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- 3. Weekly Goals Table
CREATE TABLE weekly_goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  focus_area TEXT NOT NULL,
  status TEXT DEFAULT 'active', -- active, completed, failed
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE weekly_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own weekly goals" ON weekly_goals FOR ALL USING (auth.uid() = user_id);


-- 4. Growth Drops (Book Recommendations)
CREATE TABLE growth_drops (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  drop_date DATE NOT NULL,
  focus_area TEXT NOT NULL,
  recommended_books JSONB NOT NULL, -- Array of book objects (title, summary, lessons)
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE growth_drops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own growth drops" ON growth_drops FOR SELECT USING (auth.uid() = user_id);


-- 5. Quests (Tasks)
CREATE TABLE quests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  xp_reward INTEGER DEFAULT 10,
  is_completed BOOLEAN DEFAULT false,
  quest_type TEXT DEFAULT 'daily', -- daily, weekly, one_off
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE quests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own quests" ON quests FOR ALL USING (auth.uid() = user_id);
