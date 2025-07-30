# PNP Officer Profiles Table

This table stores information about Philippine National Police officers who investigate cybercrime cases.

> **⚠️ IMPORTANT**: This file contains two separate SQL scripts:
> 1. The initial table creation script (run second in the setup sequence)
> 2. A table update script to add the unit_id field (run after creating the pnp_units table)

## Initial Table Schema

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

## PNP Officer Profiles Update (Unit Association)

> **⚠️ RUN AFTER CREATING PNP_UNITS TABLE**: The following SQL must be executed after the pnp_units table has been created. This adds a foreign key reference to link officers to specialized units.

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

## Table Details

### Fields

- **id**: Primary key, automatically generated UUID
- **firebase_uid**: Unique identifier from Firebase Authentication
- **email**: Officer's email address (unique)
- **full_name**: Officer's full name
- **phone_number**: Optional contact number
- **badge_number**: Unique badge identifier (format: PNP-XXXXX)
- **rank**: Official PNP rank
- **unit**: Specialized cybercrime investigation unit
- **unit_id**: Foreign key reference to pnp_units table (added after pnp_units creation)
- **region**: Philippine geographic region (from PSGC)
- **status**: Account status (active, on_leave, suspended, retired)
- **total_cases**: Total number of cases assigned to the officer
- **active_cases**: Number of ongoing cases
- **resolved_cases**: Number of completed cases
- **success_rate**: Percentage of cases successfully resolved
- **created_at**: Timestamp when the record was created
- **updated_at**: Timestamp when the record was last updated

### Indexes

- **idx_pnp_officer_profiles_firebase_uid**: Optimizes lookups by Firebase UID
- **idx_pnp_officer_profiles_email**: Optimizes lookups by email address
- **idx_pnp_officer_profiles_badge_number**: Optimizes lookups by badge number
- **idx_pnp_officer_profiles_unit**: Optimizes filtering by text unit name
- **idx_pnp_officer_profiles_unit_id**: Optimizes filtering by unit ID (foreign key)
- **idx_pnp_officer_profiles_region**: Optimizes filtering by region
- **idx_pnp_officer_profiles_status**: Optimizes filtering by account status

### Functions and Triggers

- **update_officer_performance_stats**: Updates officer performance metrics based on complaint data
- **trigger_update_officer_stats**: Triggers the update of officer statistics when complaints change
- **update_unit_officer_count**: Updates the count of officers in a unit when assignments change
- **update_unit_officer_count_trigger**: Triggers the update of unit officer counts

## Related Tables

- **complaints**: Cases assigned to officers
- **case_assignments**: Tracks which officers are assigned to which cases
- **pnp_units**: Officers belong to specialized units

## Setup Instructions

### Initial Table Setup
Run the initial table creation SQL after setting up the admin_profiles table, and before creating the case_assignments table.

### Unit Association Update
Run the update SQL (adding unit_id and related triggers) AFTER creating the pnp_units table.

### Setup Order Summary
1. Create admin_profiles table
2. Create pnp_officer_profiles table (initial schema)
3. Create case_assignments table
4. Create pnp_units table
5. Update pnp_officer_profiles table (add unit_id)