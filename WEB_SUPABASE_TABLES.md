# Web App Supabase Tables

Additional database tables for the LawBot web application (admin and PNP officer access).

**⚠️ PREREQUISITE**: Run DOCUMENTATION.md database setup first to create the `update_updated_at_column()` function.

**⚠️ DEBUGGING**: RLS is disabled on all tables for debugging purposes. **ENABLE IN PRODUCTION!**

## Admin Profiles Table

```sql
-- Drop existing table
DROP TABLE IF EXISTS admin_profiles CASCADE;

-- Create admin_profiles table for system administrators
CREATE TABLE IF NOT EXISTS admin_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone_number TEXT,
  role TEXT DEFAULT 'SYSTEM_ADMIN' CHECK (role IN ('SYSTEM_ADMIN', 'SUPER_ADMIN', 'SUPPORT_ADMIN')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'inactive')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_admin_profiles_firebase_uid ON admin_profiles(firebase_uid);
CREATE INDEX idx_admin_profiles_email ON admin_profiles(email);
CREATE INDEX idx_admin_profiles_status ON admin_profiles(status);

-- Apply updated_at trigger
CREATE TRIGGER update_admin_profiles_updated_at
  BEFORE UPDATE ON admin_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS disabled for debugging purposes
-- ALTER TABLE admin_profiles ENABLE ROW LEVEL SECURITY;
```

## PNP Officer Profiles Table

```sql
-- Drop existing table
DROP TABLE IF EXISTS pnp_officer_profiles CASCADE;

-- Create pnp_officer_profiles table for Philippine National Police officers
CREATE TABLE IF NOT EXISTS pnp_officer_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone_number TEXT,
  badge_number TEXT UNIQUE NOT NULL,
  rank TEXT NOT NULL CHECK (rank IN (
    'Police Officer I', 'Police Officer II', 'Police Officer III',
    'Senior Police Officer I', 'Senior Police Officer II', 'Senior Police Officer III', 'Senior Police Officer IV',
    'Police Chief Master Sergeant', 'Police Executive Master Sergeant',
    'Police Lieutenant', 'Police Captain', 'Police Major', 'Police Lieutenant Colonel', 'Police Colonel'
  )),
  unit TEXT NOT NULL CHECK (unit IN (
    'Cyber Crime Investigation Cell', 'Economic Offenses Wing', 'Cyber Security Division',
    'Cyber Crime Technical Unit', 'Cyber Crime Against Women and Children', 'Special Investigation Team',
    'Critical Infrastructure Protection Unit', 'National Security Cyber Division',
    'Advanced Cyber Forensics Unit', 'Special Cyber Operations Unit'
  )),
  region TEXT NOT NULL CHECK (region IN (
    -- PSGC Cloud API format (preferred)
    'National Capital Region (NCR)', 'Region I (Ilocos Region)', 'Region II (Cagayan Valley)',
    'Region III (Central Luzon)', 'Region IV-A (CALABARZON)', 'MIMAROPA Region',
    'Region V (Bicol Region)', 'Region VI (Western Visayas)', 'Region VII (Central Visayas)',
    'Region VIII (Eastern Visayas)', 'Region IX (Zamboanga Peninsula)', 'Region X (Northern Mindanao)',
    'Region XI (Davao Region)', 'Region XII (SOCCSKSARGEN)', 'Region XIII (Caraga)',
    'Cordillera Administrative Region (CAR)', 'Bangsamoro Autonomous Region In Muslim Mindanao (BARMM)',
    -- GitLab API format (for compatibility)
    'Region I - Ilocos Region', 'Region II - Cagayan Valley', 'Region III - Central Luzon',
    'Region IV-A - CALABARZON', 'Region IV-B - MIMAROPA', 'Region V - Bicol Region',
    'Region VI - Western Visayas', 'Region VII - Central Visayas', 'Region VIII - Eastern Visayas',
    'Region IX - Zamboanga Peninsula', 'Region X - Northern Mindanao', 'Region XI - Davao Region',
    'Region XII - SOCCSKSARGEN', 'Region XIII - Caraga', 'BARMM - Bangsamoro Autonomous Region'
  )),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'on_leave', 'suspended', 'retired')),
  -- Performance metrics (can be calculated from complaints table or stored for performance)
  total_cases INTEGER DEFAULT 0,
  active_cases INTEGER DEFAULT 0, 
  resolved_cases INTEGER DEFAULT 0,
  success_rate DECIMAL(5,2) DEFAULT 0.00, -- Percentage with 2 decimal places
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_pnp_officer_profiles_firebase_uid ON pnp_officer_profiles(firebase_uid);
CREATE INDEX idx_pnp_officer_profiles_email ON pnp_officer_profiles(email);
CREATE INDEX idx_pnp_officer_profiles_badge_number ON pnp_officer_profiles(badge_number);
CREATE INDEX idx_pnp_officer_profiles_unit ON pnp_officer_profiles(unit);
CREATE INDEX idx_pnp_officer_profiles_region ON pnp_officer_profiles(region);
CREATE INDEX idx_pnp_officer_profiles_status ON pnp_officer_profiles(status);

-- Apply updated_at trigger
CREATE TRIGGER update_pnp_officer_profiles_updated_at
  BEFORE UPDATE ON pnp_officer_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to update officer performance statistics
CREATE OR REPLACE FUNCTION update_officer_performance_stats(officer_full_name TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE pnp_officer_profiles 
  SET 
    total_cases = (
      SELECT COUNT(*) 
      FROM complaints 
      WHERE assigned_officer = officer_full_name
    ),
    active_cases = (
      SELECT COUNT(*) 
      FROM complaints 
      WHERE assigned_officer = officer_full_name 
      AND status NOT IN ('Resolved', 'Dismissed')
    ),
    resolved_cases = (
      SELECT COUNT(*) 
      FROM complaints 
      WHERE assigned_officer = officer_full_name 
      AND status IN ('Resolved', 'Dismissed')
    ),
    success_rate = (
      SELECT CASE 
        WHEN COUNT(*) = 0 THEN 0 
        ELSE ROUND((COUNT(*) FILTER (WHERE status IN ('Resolved', 'Dismissed')) * 100.0 / COUNT(*)), 2)
      END
      FROM complaints 
      WHERE assigned_officer = officer_full_name
    ),
    updated_at = NOW()
  WHERE full_name = officer_full_name;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update officer stats when complaints are modified
CREATE OR REPLACE FUNCTION trigger_update_officer_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Update stats for the assigned officer (handle both INSERT/UPDATE/DELETE)
  IF TG_OP = 'DELETE' THEN
    IF OLD.assigned_officer IS NOT NULL THEN
      PERFORM update_officer_performance_stats(OLD.assigned_officer);
    END IF;
    RETURN OLD;
  END IF;
  
  IF NEW.assigned_officer IS NOT NULL THEN
    PERFORM update_officer_performance_stats(NEW.assigned_officer);
  END IF;
  
  -- If officer assignment changed, update both old and new officer stats
  IF TG_OP = 'UPDATE' AND OLD.assigned_officer IS DISTINCT FROM NEW.assigned_officer THEN
    IF OLD.assigned_officer IS NOT NULL THEN
      PERFORM update_officer_performance_stats(OLD.assigned_officer);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger to complaints table (this will be created when complaints table exists)
-- CREATE TRIGGER update_officer_stats_trigger
--   AFTER INSERT OR UPDATE OR DELETE ON complaints
--   FOR EACH ROW
--   EXECUTE FUNCTION trigger_update_officer_stats();

-- RLS disabled for debugging purposes
-- ALTER TABLE pnp_officer_profiles ENABLE ROW LEVEL SECURITY;
```

## Case Assignments Table

```sql
-- Drop existing table
DROP TABLE IF EXISTS case_assignments CASCADE;

-- Create case_assignments table to track which officers are assigned to which cases
CREATE TABLE IF NOT EXISTS case_assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE NOT NULL,
  officer_id UUID REFERENCES pnp_officer_profiles(id) ON DELETE SET NULL,
  admin_id UUID REFERENCES admin_profiles(id) ON DELETE SET NULL,
  assigned_by TEXT NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'transferred')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_case_assignments_complaint_id ON case_assignments(complaint_id);
CREATE INDEX idx_case_assignments_officer_id ON case_assignments(officer_id);
CREATE INDEX idx_case_assignments_status ON case_assignments(status);

-- RLS disabled for debugging purposes
-- ALTER TABLE case_assignments ENABLE ROW LEVEL SECURITY;
```

## Setup Instructions

**⚠️ IMPORTANT ORDER - Run in exact sequence:**

1. **First: Run the main database setup from DOCUMENTATION.md**
   - This creates the required `update_updated_at_column()` function
   - Creates base tables: `user_profiles`, `complaints`, `evidence_files`, `notifications`

2. **Second: Run each table section from this file in order**
   - Admin Profiles Table (table + indexes + trigger)
   - PNP Officer Profiles Table (table + indexes + trigger)  
   - Case Assignments Table (table + indexes)
   - PNP Units Table (table + indexes + trigger)
   - PNP Unit Crime Types Table (table + indexes)
   - PNP Officer Profiles Update (add unit_id + trigger)
   - Complaints Table Update (add unit_id + trigger)

3. **Finally: Verify all tables are created in the Table Editor**
   - Check that all tables, indexes, and triggers are created
   - Note: RLS is disabled for debugging (commented out)

## PNP Units Table

```sql
-- Drop existing table
DROP TABLE IF EXISTS pnp_units CASCADE;

-- Create pnp_units table for specialized cybercrime investigation units
CREATE TABLE IF NOT EXISTS pnp_units (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  unit_name TEXT NOT NULL,
  unit_code TEXT UNIQUE NOT NULL CHECK (unit_code ~ '^PCU-\d{3}$'),
  category TEXT NOT NULL CHECK (category IN (
    'Communication & Social Media Crimes',
    'Financial & Economic Crimes',
    'Data & Privacy Crimes',
    'Malware & System Attacks',
    'Harassment & Exploitation',
    'Content-Related Crimes',
    'System Disruption & Sabotage',
    'Government & Terrorism',
    'Technical Exploitation',
    'Targeted Attacks'
  )),
  description TEXT NOT NULL,
  region TEXT NOT NULL CHECK (region IN (
    -- PSGC Cloud API format (preferred)
    'National Capital Region (NCR)', 'Region I (Ilocos Region)', 'Region II (Cagayan Valley)',
    'Region III (Central Luzon)', 'Region IV-A (CALABARZON)', 'MIMAROPA Region',
    'Region V (Bicol Region)', 'Region VI (Western Visayas)', 'Region VII (Central Visayas)',
    'Region VIII (Eastern Visayas)', 'Region IX (Zamboanga Peninsula)', 'Region X (Northern Mindanao)',
    'Region XI (Davao Region)', 'Region XII (SOCCSKSARGEN)', 'Region XIII (Caraga)',
    'Cordillera Administrative Region (CAR)', 'Bangsamoro Autonomous Region In Muslim Mindanao (BARMM)',
    -- GitLab API format (for compatibility)
    'Region I - Ilocos Region', 'Region II - Cagayan Valley', 'Region III - Central Luzon',
    'Region IV-A - CALABARZON', 'Region IV-B - MIMAROPA', 'Region V - Bicol Region',
    'Region VI - Western Visayas', 'Region VII - Central Visayas', 'Region VIII - Eastern Visayas',
    'Region IX - Zamboanga Peninsula', 'Region X - Northern Mindanao', 'Region XI - Davao Region',
    'Region XII - SOCCSKSARGEN', 'Region XIII - Caraga', 'BARMM - Bangsamoro Autonomous Region'
  )),
  max_officers INTEGER NOT NULL CHECK (max_officers BETWEEN 1 AND 50),
  current_officers INTEGER DEFAULT 0,
  active_cases INTEGER DEFAULT 0,
  resolved_cases INTEGER DEFAULT 0,
  success_rate DECIMAL(5,2) DEFAULT 0.00, -- Percentage with 2 decimal places
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'disbanded')),
  created_by UUID REFERENCES admin_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_pnp_units_unit_code ON pnp_units(unit_code);
CREATE INDEX idx_pnp_units_category ON pnp_units(category);
CREATE INDEX idx_pnp_units_region ON pnp_units(region);
CREATE INDEX idx_pnp_units_status ON pnp_units(status);

-- Apply updated_at trigger
CREATE TRIGGER update_pnp_units_updated_at
  BEFORE UPDATE ON pnp_units
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS disabled for debugging purposes
-- ALTER TABLE pnp_units ENABLE ROW LEVEL SECURITY;
```

## PNP Unit Crime Types Table

```sql
-- Drop existing table
DROP TABLE IF EXISTS pnp_unit_crime_types CASCADE;

-- Create junction table for PNP Units and their primary crime types
CREATE TABLE IF NOT EXISTS pnp_unit_crime_types (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  unit_id UUID REFERENCES pnp_units(id) ON DELETE CASCADE NOT NULL,
  crime_type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_pnp_unit_crime_types_unit_id ON pnp_unit_crime_types(unit_id);
CREATE INDEX idx_pnp_unit_crime_types_crime_type ON pnp_unit_crime_types(crime_type);

-- RLS disabled for debugging purposes
-- ALTER TABLE pnp_unit_crime_types ENABLE ROW LEVEL SECURITY;
```

## Update PNP Officer Profiles Table

```sql
-- Modify pnp_officer_profiles table to reference pnp_units
-- First create a foreign key column to reference pnp_units
ALTER TABLE pnp_officer_profiles ADD COLUMN unit_id UUID REFERENCES pnp_units(id) ON DELETE SET NULL;

-- Create an index for performance
CREATE INDEX idx_pnp_officer_profiles_unit_id ON pnp_officer_profiles(unit_id);

-- Create a function to update the unit's current_officers count
CREATE OR REPLACE FUNCTION update_unit_officer_count()
RETURNS TRIGGER AS $$
BEGIN
  -- If officer unit changed (including new officer or officer removal)
  IF (TG_OP = 'DELETE' OR OLD.unit_id IS DISTINCT FROM NEW.unit_id) THEN
    -- Update old unit count if there was one
    IF OLD.unit_id IS NOT NULL THEN
      UPDATE pnp_units
      SET current_officers = (
        SELECT COUNT(*) 
        FROM pnp_officer_profiles 
        WHERE unit_id = OLD.unit_id
      ),
      updated_at = NOW()
      WHERE id = OLD.unit_id;
    END IF;
  END IF;
  
  -- Update new unit count
  IF TG_OP <> 'DELETE' AND NEW.unit_id IS NOT NULL THEN
    UPDATE pnp_units
    SET current_officers = (
      SELECT COUNT(*) 
      FROM pnp_officer_profiles 
      WHERE unit_id = NEW.unit_id
    ),
    updated_at = NOW()
    WHERE id = NEW.unit_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to keep unit officer counts updated
CREATE TRIGGER update_unit_officer_count_trigger
  AFTER INSERT OR UPDATE OR DELETE ON pnp_officer_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_unit_officer_count();
```

## Update Complaints Table

```sql
-- Modify complaints table to reference pnp_units
-- First create a foreign key column to reference pnp_units
ALTER TABLE complaints ADD COLUMN unit_id UUID REFERENCES pnp_units(id) ON DELETE SET NULL;

-- Create an index for performance
CREATE INDEX idx_complaints_unit_id ON complaints(unit_id);

-- Create a function to update the unit's performance metrics
CREATE OR REPLACE FUNCTION update_unit_performance_stats(unit_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE pnp_units 
  SET 
    active_cases = (
      SELECT COUNT(*) 
      FROM complaints 
      WHERE unit_id = unit_id_param 
      AND status NOT IN ('Resolved', 'Dismissed')
    ),
    resolved_cases = (
      SELECT COUNT(*) 
      FROM complaints 
      WHERE unit_id = unit_id_param 
      AND status IN ('Resolved', 'Dismissed')
    ),
    success_rate = (
      SELECT CASE 
        WHEN COUNT(*) = 0 THEN 0 
        ELSE ROUND((COUNT(*) FILTER (WHERE status IN ('Resolved', 'Dismissed')) * 100.0 / COUNT(*)), 2)
      END
      FROM complaints 
      WHERE unit_id = unit_id_param
    ),
    updated_at = NOW()
  WHERE id = unit_id_param;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update unit performance metrics when complaints are modified
CREATE OR REPLACE FUNCTION trigger_update_unit_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Update stats for the assigned unit (handle both INSERT/UPDATE/DELETE)
  IF TG_OP = 'DELETE' THEN
    IF OLD.unit_id IS NOT NULL THEN
      PERFORM update_unit_performance_stats(OLD.unit_id);
    END IF;
    RETURN OLD;
  END IF;
  
  IF NEW.unit_id IS NOT NULL THEN
    PERFORM update_unit_performance_stats(NEW.unit_id);
  END IF;
  
  -- If unit assignment changed, update both old and new unit stats
  IF TG_OP = 'UPDATE' AND OLD.unit_id IS DISTINCT FROM NEW.unit_id THEN
    IF OLD.unit_id IS NOT NULL THEN
      PERFORM update_unit_performance_stats(OLD.unit_id);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger to complaints table
CREATE TRIGGER update_unit_stats_trigger
  AFTER INSERT OR UPDATE OR DELETE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_unit_stats();
```

## Updated Database Schema

```
├── auth.users (Supabase built-in)
├── user_profiles (for regular citizens)
├── admin_profiles (for system administrators)
├── pnp_officer_profiles (for PNP officers)
├── pnp_units
│   └── pnp_unit_crime_types
├── complaints
│   ├── evidence_files
│   ├── status_history
│   └── case_assignments (linking cases to officers/admins)
└── notifications
```