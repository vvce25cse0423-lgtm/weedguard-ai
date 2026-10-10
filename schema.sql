-- ══════════════════════════════════════════════════════════
--  WeedGuard AI – Supabase Schema
--  Paste the entire file into the Supabase SQL Editor and run.
-- ══════════════════════════════════════════════════════════

-- ── Extensions ────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ══════════════════════════════════════════════════════════
--  PROFILES
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.profiles (
  id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email            TEXT NOT NULL,
  full_name        TEXT,
  phone            TEXT,
  location_label   TEXT,
  preferred_language TEXT DEFAULT 'en',
  avatar_url       TEXT,
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile"   ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ══════════════════════════════════════════════════════════
--  FIELDS
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.fields (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  crop_type        TEXT NOT NULL,
  area_hectares    NUMERIC(10,2),
  latitude         DOUBLE PRECISION,
  longitude        DOUBLE PRECISION,
  location_label   TEXT,
  planting_date    DATE,
  notes            TEXT,
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fields_user_id ON public.fields(user_id);

ALTER TABLE public.fields ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own fields" ON public.fields;
CREATE POLICY "Users can manage own fields"
  ON public.fields FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ══════════════════════════════════════════════════════════
--  SCANS
--  field_id is NULLABLE – scans can be saved without a field
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.scans (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  field_id            UUID REFERENCES public.fields(id) ON DELETE SET NULL,  -- nullable
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url           TEXT,
  weed_count          INTEGER NOT NULL DEFAULT 0,
  average_confidence  NUMERIC(5,4) DEFAULT 0,
  severity            TEXT NOT NULL DEFAULT 'low'
                        CHECK (severity IN ('low','moderate','high')),
  priority_zone       TEXT,
  infestation_score   NUMERIC(5,4),
  is_mock_detection   BOOLEAN DEFAULT FALSE,
  created_at          TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_scans_field_id   ON public.scans(field_id);
CREATE INDEX IF NOT EXISTS idx_scans_user_id    ON public.scans(user_id);
CREATE INDEX IF NOT EXISTS idx_scans_created_at ON public.scans(created_at DESC);

ALTER TABLE public.scans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own scans" ON public.scans;
CREATE POLICY "Users can manage own scans"
  ON public.scans FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ══════════════════════════════════════════════════════════
--  DETECTIONS  (individual bounding boxes per scan)
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.detections (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scan_id     UUID NOT NULL REFERENCES public.scans(id) ON DELETE CASCADE,
  label       TEXT NOT NULL,
  confidence  NUMERIC(5,4) NOT NULL,
  bbox_x      NUMERIC(6,4),
  bbox_y      NUMERIC(6,4),
  bbox_width  NUMERIC(6,4),
  bbox_height NUMERIC(6,4)
);

CREATE INDEX IF NOT EXISTS idx_detections_scan_id ON public.detections(scan_id);

ALTER TABLE public.detections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can access own scan detections" ON public.detections;
CREATE POLICY "Users can access own scan detections"
  ON public.detections FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.scans
      WHERE scans.id = detections.scan_id
        AND scans.user_id = auth.uid()
    )
  );

-- ══════════════════════════════════════════════════════════
--  FIELD ZONES
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.field_zones (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scan_id          UUID NOT NULL REFERENCES public.scans(id) ON DELETE CASCADE,
  zone_id          TEXT NOT NULL,
  zone_label       TEXT NOT NULL,
  severity         TEXT NOT NULL DEFAULT 'low'
                     CHECK (severity IN ('low','moderate','high')),
  weed_count       INTEGER NOT NULL DEFAULT 0,
  coverage_percent NUMERIC(5,2) DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_field_zones_scan_id ON public.field_zones(scan_id);

ALTER TABLE public.field_zones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can access own field zones" ON public.field_zones;
CREATE POLICY "Users can access own field zones"
  ON public.field_zones FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.scans
      WHERE scans.id = field_zones.scan_id
        AND scans.user_id = auth.uid()
    )
  );

-- ══════════════════════════════════════════════════════════
--  STORAGE BUCKETS
--  Run these only once; skip if buckets already exist.
-- ══════════════════════════════════════════════════════════
INSERT INTO storage.buckets (id, name, public)
  VALUES ('scan-images', 'scan-images', false)
  ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
  VALUES ('profile-images', 'profile-images', false)
  ON CONFLICT (id) DO NOTHING;

-- Storage RLS: each user can only read/write their own folder
DROP POLICY IF EXISTS "User scan images access"    ON storage.objects;
DROP POLICY IF EXISTS "User profile images access" ON storage.objects;

CREATE POLICY "User scan images access"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'scan-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  )
  WITH CHECK (
    bucket_id = 'scan-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "User profile images access"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'profile-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  )
  WITH CHECK (
    bucket_id = 'profile-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
