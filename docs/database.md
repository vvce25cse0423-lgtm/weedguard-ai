# Database Schema

See full SQL: `supabase/migrations/001_initial_schema.sql`

## Tables

### profiles
Extends `auth.users`. Created automatically on signup via trigger.
- `id` → auth.users.id
- `email`, `full_name`, `phone`, `location_label`, `preferred_language`, `avatar_url`

### fields
One row per farm field.
- `user_id` → auth.users (RLS: own rows only)
- `name`, `crop_type`, `area_hectares`, `latitude`, `longitude`, `location_label`, `planting_date`, `notes`

### scans
One row per weed detection scan.
- `field_id` → fields
- `user_id` → auth.users (RLS: own rows only)
- `image_url` (Supabase Storage), `weed_count`, `average_confidence`, `severity`, `priority_zone`, `infestation_score`, `is_mock_detection`

### detections
Individual bounding boxes per scan.
- `scan_id` → scans
- `label`, `confidence`, `bbox_x`, `bbox_y`, `bbox_width`, `bbox_height`

### field_zones
Zone-level summary per scan (4 zones per scan).
- `scan_id` → scans
- `zone_id`, `zone_label`, `severity`, `weed_count`, `coverage_percent`

### weather_snapshots
Point-in-time weather readings associated with a field.
- `field_id` → fields, `user_id` → auth.users
- `temperature_celsius`, `humidity`, `rain_probability`, `wind_speed_kmh`, `description`

## Row Level Security

All tables use RLS. Users can only read/write their own rows via `auth.uid()` checks. No cross-user data access is possible.

## Storage

- `scan-images` bucket — private; path structure: `{user_id}/{field_id}/{uuid}.jpg`
- `profile-images` bucket — private; path structure: `{user_id}/avatar.jpg`
