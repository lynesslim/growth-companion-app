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

ALTER TABLE companions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view companions" ON companions FOR SELECT USING (true);


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


-- Migration (run if table already exists): ALTER TABLE growth_drops ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE;

-- 4. Growth Drops (Book Recommendations)
CREATE TABLE growth_drops (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  drop_date DATE NOT NULL,
  focus_area TEXT NOT NULL,
  recommended_books JSONB NOT NULL, -- Array of book objects (title, summary, lessons)
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE growth_drops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own growth drops" ON growth_drops FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own growth drops" ON growth_drops FOR UPDATE USING (auth.uid() = user_id);


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


-- 6. Friends Table (Social)
CREATE TABLE friends (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id_1 UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  user_id_2 UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending', -- pending, accepted, declined
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id_1, user_id_2)
);

ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own friendships" ON friends FOR SELECT USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);
CREATE POLICY "Users insert friendships" ON friends FOR INSERT WITH CHECK (auth.uid() = user_id_1 OR auth.uid() = user_id_2);
CREATE POLICY "Users update own friendships" ON friends FOR UPDATE USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);


-- 7. Social Streaks Table
CREATE TABLE social_streaks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id_1 UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  user_id_2 UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  current_streak INTEGER DEFAULT 0,
  last_shared_date_1 DATE,
  last_shared_date_2 DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id_1, user_id_2)
);

ALTER TABLE social_streaks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own streaks" ON social_streaks FOR SELECT USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);
CREATE POLICY "Users update own streaks" ON social_streaks FOR UPDATE USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);


-- 8. Social Drops Table
CREATE TABLE social_drops (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  recipient_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  drop_date DATE NOT NULL,
  book_data JSONB NOT NULL,
  is_opened BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE social_drops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own social drops" ON social_drops FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = recipient_id);
CREATE POLICY "Users insert social drops" ON social_drops FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users update own social drops" ON social_drops FOR UPDATE USING (auth.uid() = recipient_id);


-- 9. search_users RPC (SECURITY DEFINER)
-- Searches profiles by name (ILIKE) and auth.users by email (exact match)
-- Returns sanitized user profiles for friend search
CREATE OR REPLACE FUNCTION public.search_users(search_query TEXT, current_user_id UUID)
RETURNS TABLE(id UUID, name TEXT, current_xp INTEGER, level INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT p.id, p.name, p.current_xp, p.level
  FROM profiles p
  WHERE p.id != current_user_id
    AND (
      p.name ILIKE '%' || search_query || '%'
      OR EXISTS (
        SELECT 1 FROM auth.users u
        WHERE u.id = p.id AND u.email = search_query
      )
    )
  ORDER BY p.name ASC
  LIMIT 20;
END;
$$;
