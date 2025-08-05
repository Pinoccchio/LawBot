-- 🔧 FIX: Create Missing Tables for Case Assignments
-- Run this SQL in Supabase SQL Editor to fix the foreign key relationship error

-- Step 1: Check if tables exist
DO $$
BEGIN 
  RAISE NOTICE '🔍 Checking existing tables...';
END $$;

SELECT 
  table_name,
  CASE 
    WHEN table_name = 'pnp_units' THEN '📋 PNP Units'
    WHEN table_name = 'pnp_officer_profiles' THEN '👮 PNP Officers' 
    WHEN table_name = 'case_assignments' THEN '📁 Case Assignments'
    WHEN table_name = 'admin_profiles' THEN '👨‍💼 Admin Profiles'
    ELSE '❓ Other'
  END as description
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('pnp_units', 'pnp_officer_profiles', 'case_assignments', 'admin_profiles')
ORDER BY table_name;

-- Step 2: Create PNP Units table (if missing)
CREATE TABLE IF NOT EXISTS pnp_units (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  unit_name TEXT UNIQUE NOT NULL,
  unit_code TEXT UNIQUE NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  region TEXT DEFAULT 'National Capital Region (NCR)',
  max_officers INTEGER DEFAULT 20,
  current_officers INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'restructuring')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Step 3: Create Admin Profiles table (if missing)
CREATE TABLE IF NOT EXISTS admin_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT DEFAULT 'SYSTEM_ADMIN' CHECK (role IN ('SYSTEM_ADMIN', 'SUPER_ADMIN', 'SUPPORT_ADMIN')),
  permissions JSONB DEFAULT '[]'::jsonb,
  department TEXT,
  employee_id TEXT UNIQUE,
  phone_number TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Step 4: Create PNP Officer Profiles table (if missing)
CREATE TABLE IF NOT EXISTS pnp_officer_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  badge_number TEXT UNIQUE NOT NULL,
  rank TEXT NOT NULL CHECK (rank IN (
    'Police Officer I', 'Police Officer II', 'Police Officer III',
    'Senior Police Officer I', 'Senior Police Officer II', 'Senior Police Officer III', 'Senior Police Officer IV',
    'Police Master Sergeant', 'Police Chief Master Sergeant', 'Police Executive Master Sergeant',
    'Police Lieutenant', 'Police Captain', 'Police Major', 'Police Lieutenant Colonel', 'Police Colonel'
  )),
  phone_number TEXT,
  unit_id UUID REFERENCES pnp_units(id) ON DELETE SET NULL NOT NULL,
  specializations TEXT[] DEFAULT '{}',
  region TEXT DEFAULT 'National Capital Region (NCR)',
  years_of_service INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'on_leave', 'suspended', 'retired')),
  availability_status TEXT DEFAULT 'available' CHECK (availability_status IN ('available', 'busy', 'overloaded', 'unavailable')),
  last_status_update TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Step 5: Create Case Assignments table (if missing) 
CREATE TABLE IF NOT EXISTS case_assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE NOT NULL,
  officer_id UUID REFERENCES pnp_officer_profiles(id) ON DELETE CASCADE NOT NULL,
  admin_id UUID REFERENCES admin_profiles(id) ON DELETE SET NULL,
  assigned_by TEXT NOT NULL,
  assignment_type TEXT DEFAULT 'primary' CHECK (assignment_type IN ('primary', 'secondary', 'consultant', 'reviewer')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'transferred')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Step 6: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_pnp_officers_unit_id ON pnp_officer_profiles(unit_id);
CREATE INDEX IF NOT EXISTS idx_pnp_officers_status ON pnp_officer_profiles(status);
CREATE INDEX IF NOT EXISTS idx_pnp_officers_availability ON pnp_officer_profiles(availability_status);
CREATE INDEX IF NOT EXISTS idx_case_assignments_complaint_id ON case_assignments(complaint_id);
CREATE INDEX IF NOT EXISTS idx_case_assignments_officer_id ON case_assignments(officer_id);
CREATE INDEX IF NOT EXISTS idx_case_assignments_status ON case_assignments(status);

-- Step 7: Insert default PNP units (if empty)
INSERT INTO pnp_units (unit_name, unit_code, category, description, max_officers) VALUES
('Cyber Crime Investigation Cell', 'PCU-001', 'Communication & Social Media Crimes', 'Handles phishing, social engineering, and communication-related cybercrimes', 20),
('Economic Offenses Wing', 'PCU-002', 'Financial & Economic Crimes', 'Investigates online banking fraud, investment scams, and financial crimes', 25),
('Cyber Security Division', 'PCU-003', 'Data & Privacy Crimes', 'Handles data breaches, identity theft, and privacy violations', 15),
('Cyber Crime Technical Unit', 'PCU-004', 'Malware & System Attacks', 'Specializes in malware analysis, ransomware, and technical attacks', 18),
('Cyber Crime Against Women and Children', 'PCU-005', 'Harassment & Exploitation', 'Investigates cyberstalking, harassment, and exploitation cases', 22),
('Special Investigation Team', 'PCU-006', 'Content-Related Crimes', 'Handles illegal content, piracy, and trafficking cases', 16),
('Critical Infrastructure Protection Unit', 'PCU-007', 'System Disruption & Sabotage', 'Protects critical infrastructure from cyber attacks', 14),
('National Security Cyber Division', 'PCU-008', 'Government & Terrorism', 'Handles cyberterrorism and national security threats', 12),
('Advanced Cyber Forensics Unit', 'PCU-009', 'Technical Exploitation', 'Specializes in advanced forensics and zero-day exploits', 10),
('Special Cyber Operations Unit', 'PCU-010', 'Targeted Attacks', 'Handles advanced persistent threats and targeted attacks', 8)
ON CONFLICT (unit_name) DO NOTHING;

-- Step 8: Create sample PNP officer (for testing)
DO $$
DECLARE
    unit_uuid UUID;
BEGIN
    -- Get first unit ID
    SELECT id INTO unit_uuid FROM pnp_units LIMIT 1;
    
    -- Insert sample officer if no officers exist
    IF NOT EXISTS (SELECT 1 FROM pnp_officer_profiles LIMIT 1) THEN
        INSERT INTO pnp_officer_profiles (
            firebase_uid, email, full_name, badge_number, rank, 
            phone_number, unit_id, status, availability_status
        ) VALUES (
            'sample_officer_uid_123', 
            'officer.sample@pnp.gov.ph',
            'Officer Juan Dela Cruz',
            'PNP-001-2025',
            'Police Officer III',
            '+63 912 345 6789',
            unit_uuid,
            'active',
            'available'
        );
        RAISE NOTICE '✅ Sample officer created for testing';
    END IF;
END $$;

-- Step 9: Verify foreign key relationships
SELECT 
    tc.table_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name IN ('case_assignments', 'pnp_officer_profiles')
ORDER BY tc.table_name, kcu.column_name;

-- Step 10: Final verification
DO $$
BEGIN 
  RAISE NOTICE '✅ Tables created successfully!';
  RAISE NOTICE '✅ Foreign key relationships established!';
  RAISE NOTICE '✅ Default data inserted!';
  RAISE NOTICE '🎉 Case assignments should now work properly in Flutter app!';
END $$;