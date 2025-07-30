# PNP Units Database Integration

This document describes the SQL schema for the PNP Units table and its integration with the existing tables.

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

## Integration with Existing Tables

The new PNP Units table integrates with existing tables as follows:

1. **PNP Officer Profiles**: Officers belong to a PNP Unit
   - Added unit_id column to reference the pnp_units table
   - Added triggers to update unit officer counts

2. **Complaints**: Cases are assigned to a PNP Unit 
   - Added unit_id column to reference the pnp_units table
   - Added triggers to update unit performance metrics

3. **Admin Profiles**: Admins create PNP Units
   - The created_by column in pnp_units references admin_profiles

## Setup Instructions

**⚠️ IMPORTANT ORDER - Run in exact sequence:**

1. **First: Run the main database setup from DOCUMENTATION.md**
   - This creates the required tables and functions for the base system

2. **Second: Run the web app tables setup from WEB_SUPABASE_TABLES.md**
   - This creates admin_profiles, pnp_officer_profiles, and case_assignments tables

3. **Third: Run each section from this file in order**
   - PNP Units Table (table + indexes + trigger)
   - PNP Unit Crime Types Table (table + indexes)
   - PNP Officer Profiles Table update (add unit_id + trigger)
   - Complaints Table update (add unit_id + trigger)

4. **Finally: Verify all tables are created in the Table Editor**
   - Check that all tables, indexes, and triggers are created
   - Note: RLS is disabled for debugging (commented out)