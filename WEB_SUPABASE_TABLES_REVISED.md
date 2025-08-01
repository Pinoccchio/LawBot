# Simplified Web App Supabase Tables - Basic Availability Only

This is a simplified database schema that focuses on basic officer availability management without complex workload tracking, leave management, or specializations.

**⚠️ PREREQUISITE**: Run DOCUMENTATION.md database setup first to create the `update_updated_at_column()` function.

**⚠️ IMPORTANT**: This is a complete schema revision. Each table will be dropped and recreated individually.

**🔄 SIMPLIFIED APPROACH**: Removed complex availability features:
- ❌ Max concurrent cases and workload percentage tracking
- ❌ Specializations and skill level management  
- ❌ Leave management with dates, types, and reasons
- ✅ Simple availability status: available/busy/overloaded/unavailable

**⚠️ TROUBLESHOOTING**: If you get "Failed to fetch" errors when creating officers:
1. Ensure the database has been updated with this simplified schema
2. Drop and recreate the `pnp_officer_profiles` table using the schema below
3. The API now only sends basic fields, so complex fields must be removed from database constraints

## 1. Admin Profiles Table (Unchanged)

```sql
-- Drop existing table and recreate
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
```

## 2. PNP Units Table (Enhanced)

```sql
-- Drop existing table and recreate
DROP TABLE IF EXISTS pnp_units CASCADE;

-- Create pnp_units table FIRST (no dependencies)
CREATE TABLE IF NOT EXISTS pnp_units (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  unit_name TEXT NOT NULL UNIQUE, -- Made unique to prevent duplicates
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
    'National Capital Region (NCR)', 'Region I (Ilocos Region)', 'Region II (Cagayan Valley)',
    'Region III (Central Luzon)', 'Region IV-A (CALABARZON)', 'MIMAROPA Region',
    'Region V (Bicol Region)', 'Region VI (Western Visayas)', 'Region VII (Central Visayas)',
    'Region VIII (Eastern Visayas)', 'Region IX (Zamboanga Peninsula)', 'Region X (Northern Mindanao)',
    'Region XI (Davao Region)', 'Region XII (SOCCSKSARGEN)', 'Region XIII (Caraga)',
    'Cordillera Administrative Region (CAR)', 'Bangsamoro Autonomous Region In Muslim Mindanao (BARMM)',
    'Region I - Ilocos Region', 'Region II - Cagayan Valley', 'Region III - Central Luzon',
    'Region IV-A - CALABARZON', 'Region IV-B - MIMAROPA', 'Region V - Bicol Region',
    'Region VI - Western Visayas', 'Region VII - Central Visayas', 'Region VIII - Eastern Visayas',
    'Region IX - Zamboanga Peninsula', 'Region X - Northern Mindanao', 'Region XI - Davao Region',
    'Region XII - SOCCSKSARGEN', 'Region XIII - Caraga', 'BARMM - Bangsamoro Autonomous Region'
  )),
  max_officers INTEGER NOT NULL CHECK (max_officers BETWEEN 1 AND 50),
  current_officers INTEGER DEFAULT 0 CHECK (current_officers >= 0),
  active_cases INTEGER DEFAULT 0 CHECK (active_cases >= 0),
  resolved_cases INTEGER DEFAULT 0 CHECK (resolved_cases >= 0),
  success_rate DECIMAL(5,2) DEFAULT 0.00 CHECK (success_rate BETWEEN 0 AND 100),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'disbanded')),
  created_by UUID REFERENCES admin_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_pnp_units_unit_name ON pnp_units(unit_name);
CREATE INDEX idx_pnp_units_unit_code ON pnp_units(unit_code);
CREATE INDEX idx_pnp_units_category ON pnp_units(category);
CREATE INDEX idx_pnp_units_region ON pnp_units(region);
CREATE INDEX idx_pnp_units_status ON pnp_units(status);

-- Apply updated_at trigger
CREATE TRIGGER update_pnp_units_updated_at
  BEFORE UPDATE ON pnp_units
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## 3. PNP Unit Crime Types Table

```sql
-- Drop existing table and recreate
DROP TABLE IF EXISTS pnp_unit_crime_types CASCADE;

-- Create junction table for PNP Units and their primary crime types
CREATE TABLE IF NOT EXISTS pnp_unit_crime_types (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  unit_id UUID REFERENCES pnp_units(id) ON DELETE CASCADE NOT NULL,
  crime_type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  UNIQUE(unit_id, crime_type) -- Prevent duplicate crime types per unit
);

-- Create indexes for performance
CREATE INDEX idx_pnp_unit_crime_types_unit_id ON pnp_unit_crime_types(unit_id);
CREATE INDEX idx_pnp_unit_crime_types_crime_type ON pnp_unit_crime_types(crime_type);
```

## 4. PNP Officer Profiles Table (Enhanced with Availability Tracking)

```sql
-- Drop existing table and recreate
DROP TABLE IF EXISTS pnp_officer_profiles CASCADE;

-- Create pnp_officer_profiles table with comprehensive availability tracking
CREATE TABLE IF NOT EXISTS pnp_officer_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone_number TEXT,
  badge_number TEXT UNIQUE NOT NULL CHECK (badge_number ~ '^PNP-\d{5}$'),
  rank TEXT NOT NULL CHECK (rank IN (
    'Police Officer I', 'Police Officer II', 'Police Officer III',
    'Senior Police Officer I', 'Senior Police Officer II', 'Senior Police Officer III', 'Senior Police Officer IV',
    'Police Chief Master Sergeant', 'Police Executive Master Sergeant',
    'Police Lieutenant', 'Police Captain', 'Police Major', 'Police Lieutenant Colonel', 'Police Colonel'
  )),
  -- REMOVED: Old unit text field - now only foreign key reference
  unit_id UUID REFERENCES pnp_units(id) ON DELETE SET NULL NOT NULL, -- Made NOT NULL to ensure assignment
  region TEXT NOT NULL CHECK (region IN (
    'National Capital Region (NCR)', 'Region I (Ilocos Region)', 'Region II (Cagayan Valley)',
    'Region III (Central Luzon)', 'Region IV-A (CALABARZON)', 'MIMAROPA Region',
    'Region V (Bicol Region)', 'Region VI (Western Visayas)', 'Region VII (Central Visayas)',
    'Region VIII (Eastern Visayas)', 'Region IX (Zamboanga Peninsula)', 'Region X (Northern Mindanao)',
    'Region XI (Davao Region)', 'Region XII (SOCCSKSARGEN)', 'Region XIII (Caraga)',
    'Cordillera Administrative Region (CAR)', 'Bangsamoro Autonomous Region In Muslim Mindanao (BARMM)',
    'Region I - Ilocos Region', 'Region II - Cagayan Valley', 'Region III - Central Luzon',
    'Region IV-A - CALABARZON', 'Region IV-B - MIMAROPA', 'Region V - Bicol Region',
    'Region VI - Western Visayas', 'Region VII - Central Visayas', 'Region VIII - Eastern Visayas',
    'Region IX - Zamboanga Peninsula', 'Region X - Northern Mindanao', 'Region XI - Davao Region',
    'Region XII - SOCCSKSARGEN', 'Region XIII - Caraga', 'BARMM - Bangsamoro Autonomous Region'
  )),
  
  -- Enhanced Status and Availability Tracking
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'on_leave', 'suspended', 'retired')),
  availability_status TEXT DEFAULT 'available' CHECK (availability_status IN ('available', 'busy', 'overloaded', 'unavailable')),
  
  
  -- Performance metrics (simplified)
  total_cases INTEGER DEFAULT 0 CHECK (total_cases >= 0),
  active_cases INTEGER DEFAULT 0 CHECK (active_cases >= 0), 
  resolved_cases INTEGER DEFAULT 0 CHECK (resolved_cases >= 0),
  success_rate DECIMAL(5,2) DEFAULT 0.00 CHECK (success_rate BETWEEN 0 AND 100),
  
  -- Last Activity Tracking
  last_login_at TIMESTAMP WITH TIME ZONE,
  last_case_assignment_at TIMESTAMP WITH TIME ZONE,
  last_status_update_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_pnp_officer_profiles_firebase_uid ON pnp_officer_profiles(firebase_uid);
CREATE INDEX idx_pnp_officer_profiles_email ON pnp_officer_profiles(email);
CREATE INDEX idx_pnp_officer_profiles_badge_number ON pnp_officer_profiles(badge_number);
CREATE INDEX idx_pnp_officer_profiles_unit_id ON pnp_officer_profiles(unit_id);
CREATE INDEX idx_pnp_officer_profiles_region ON pnp_officer_profiles(region);
CREATE INDEX idx_pnp_officer_profiles_status ON pnp_officer_profiles(status);
CREATE INDEX idx_pnp_officer_profiles_availability_status ON pnp_officer_profiles(availability_status);
CREATE INDEX idx_pnp_officer_profiles_active_cases ON pnp_officer_profiles(active_cases);

-- Apply updated_at trigger
CREATE TRIGGER update_pnp_officer_profiles_updated_at
  BEFORE UPDATE ON pnp_officer_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## 5. Case Assignments Table

```sql
-- Drop existing table and recreate
DROP TABLE IF EXISTS case_assignments CASCADE;

-- Create case_assignments table to track which officers are assigned to which cases
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

-- Create indexes for performance
CREATE INDEX idx_case_assignments_complaint_id ON case_assignments(complaint_id);
CREATE INDEX idx_case_assignments_officer_id ON case_assignments(officer_id);
CREATE INDEX idx_case_assignments_status ON case_assignments(status);
CREATE INDEX idx_case_assignments_assignment_type ON case_assignments(assignment_type);

-- Apply updated_at trigger
CREATE TRIGGER update_case_assignments_updated_at
  BEFORE UPDATE ON case_assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## 6. Enhanced Trigger Functions

```sql
-- Drop existing functions and triggers
DROP FUNCTION IF EXISTS update_unit_officer_count() CASCADE;
DROP FUNCTION IF EXISTS update_unit_performance_stats(UUID) CASCADE;
DROP FUNCTION IF EXISTS trigger_update_unit_stats() CASCADE;
DROP FUNCTION IF EXISTS update_officer_performance_stats(TEXT) CASCADE;
DROP FUNCTION IF EXISTS trigger_update_officer_stats() CASCADE;

-- Enhanced function to update unit officer count with detailed logging
CREATE OR REPLACE FUNCTION update_unit_officer_count()
RETURNS TRIGGER AS $$
DECLARE
  old_unit_id UUID;
  new_unit_id UUID;
  officer_count INTEGER;
BEGIN
  -- Handle DELETE operations
  IF TG_OP = 'DELETE' THEN
    old_unit_id := OLD.unit_id;
    
    IF old_unit_id IS NOT NULL THEN
      -- Count active officers in the old unit
      SELECT COUNT(*) INTO officer_count
      FROM pnp_officer_profiles 
      WHERE unit_id = old_unit_id AND status = 'active';
      
      -- Update the unit with new count
      UPDATE pnp_units
      SET current_officers = officer_count,
          updated_at = NOW()
      WHERE id = old_unit_id;
      
      -- Log the update
      RAISE NOTICE 'Updated unit % officer count to % (DELETE)', old_unit_id, officer_count;
    END IF;
    
    RETURN OLD;
  END IF;
  
  -- Handle INSERT and UPDATE operations
  old_unit_id := CASE WHEN TG_OP = 'UPDATE' THEN OLD.unit_id ELSE NULL END;
  new_unit_id := NEW.unit_id;
  
  -- Update old unit count if unit changed
  IF TG_OP = 'UPDATE' AND old_unit_id IS DISTINCT FROM new_unit_id AND old_unit_id IS NOT NULL THEN
    SELECT COUNT(*) INTO officer_count
    FROM pnp_officer_profiles 
    WHERE unit_id = old_unit_id AND status = 'active';
    
    UPDATE pnp_units
    SET current_officers = officer_count,
        updated_at = NOW()
    WHERE id = old_unit_id;
    
    RAISE NOTICE 'Updated old unit % officer count to % (UPDATE)', old_unit_id, officer_count;
  END IF;
  
  -- Update new unit count
  IF new_unit_id IS NOT NULL THEN
    SELECT COUNT(*) INTO officer_count
    FROM pnp_officer_profiles 
    WHERE unit_id = new_unit_id AND status = 'active';
    
    UPDATE pnp_units
    SET current_officers = officer_count,
        updated_at = NOW()
    WHERE id = new_unit_id;
    
    RAISE NOTICE 'Updated new unit % officer count to % (%)', new_unit_id, officer_count, TG_OP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Simplified function to update officer availability status based on basic status only
CREATE OR REPLACE FUNCTION update_officer_availability_status()
RETURNS TRIGGER AS $$
DECLARE
  new_availability_status TEXT;
BEGIN
  -- Simple availability logic based on officer status
  IF NEW.status != 'active' THEN
    new_availability_status := 'unavailable';
  ELSE
    -- Keep the manually set availability status for active officers
    new_availability_status := COALESCE(NEW.availability_status, 'available');
  END IF;
  
  -- Update availability status if it changed and officer status changed
  IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
    NEW.availability_status := new_availability_status;
    NEW.last_status_update_at := TIMEZONE('utc', NOW());
    
    RAISE NOTICE 'Officer % availability status updated to % due to status change', NEW.full_name, new_availability_status;
  ELSIF TG_OP = 'INSERT' THEN
    NEW.availability_status := COALESCE(NEW.availability_status, 'available');
    NEW.last_status_update_at := TIMEZONE('utc', NOW());
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to keep unit officer counts updated
CREATE TRIGGER update_unit_officer_count_trigger
  AFTER INSERT OR UPDATE OR DELETE ON pnp_officer_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_unit_officer_count();

-- Create trigger to automatically update officer availability status
CREATE TRIGGER update_officer_availability_status_trigger
  BEFORE INSERT OR UPDATE ON pnp_officer_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_officer_availability_status();
```

## 7. Default Unit Data (For Testing)

```sql
-- Insert default units for testing
INSERT INTO pnp_units (unit_name, unit_code, category, description, region, max_officers) VALUES
('Cyber Crime Investigation Cell', 'PCU-001', 'Communication & Social Media Crimes', 'Handles phishing, social engineering, and communication-related cybercrimes', 'National Capital Region (NCR)', 20),
('Economic Offenses Wing', 'PCU-002', 'Financial & Economic Crimes', 'Investigates online banking fraud, investment scams, and financial crimes', 'National Capital Region (NCR)', 25),
('Cyber Security Division', 'PCU-003', 'Data & Privacy Crimes', 'Handles data breaches, identity theft, and privacy violations', 'National Capital Region (NCR)', 15),
('Cyber Crime Technical Unit', 'PCU-004', 'Malware & System Attacks', 'Specializes in malware analysis, ransomware, and technical attacks', 'National Capital Region (NCR)', 18),
('Cyber Crime Against Women and Children', 'PCU-005', 'Harassment & Exploitation', 'Investigates cyberstalking, online harassment, and exploitation', 'National Capital Region (NCR)', 22);

-- Insert crime types for the first unit (Communication & Social Media Crimes)
INSERT INTO pnp_unit_crime_types (unit_id, crime_type) 
SELECT id, crime_type FROM pnp_units, 
UNNEST(ARRAY['Phishing', 'Social Engineering', 'Spam Messages', 'Fake Social Media Profiles', 'Online Impersonation', 'Business Email Compromise', 'SMS Fraud']) AS crime_type
WHERE unit_name = 'Cyber Crime Investigation Cell';

-- Insert crime types for Economic Offenses Wing
INSERT INTO pnp_unit_crime_types (unit_id, crime_type) 
SELECT id, crime_type FROM pnp_units, 
UNNEST(ARRAY['Online Banking Fraud', 'Credit Card Fraud', 'Investment Scams', 'Cryptocurrency Fraud', 'Online Shopping Scams', 'Payment Gateway Fraud', 'Insurance Fraud', 'Tax Fraud', 'Money Laundering']) AS crime_type
WHERE unit_name = 'Economic Offenses Wing';

-- Insert crime types for Cyber Security Division
INSERT INTO pnp_unit_crime_types (unit_id, crime_type) 
SELECT id, crime_type FROM pnp_units, 
UNNEST(ARRAY['Identity Theft', 'Data Breach', 'Unauthorized System Access', 'Corporate Espionage', 'Government Data Theft', 'Medical Records Theft', 'Personal Information Theft', 'Account Takeover']) AS crime_type
WHERE unit_name = 'Cyber Security Division';

-- Insert crime types for Cyber Crime Technical Unit
INSERT INTO pnp_unit_crime_types (unit_id, crime_type) 
SELECT id, crime_type FROM pnp_units, 
UNNEST(ARRAY['Ransomware', 'Virus Attacks', 'Trojan Horses', 'Spyware', 'Adware', 'Worms', 'Keyloggers', 'Rootkits', 'Cryptojacking', 'Botnet Attacks']) AS crime_type
WHERE unit_name = 'Cyber Crime Technical Unit';

-- Insert crime types for Cyber Crime Against Women and Children
INSERT INTO pnp_unit_crime_types (unit_id, crime_type) 
SELECT id, crime_type FROM pnp_units, 
UNNEST(ARRAY['Cyberstalking', 'Online Harassment', 'Cyberbullying', 'Revenge Porn', 'Sextortion', 'Online Predatory Behavior', 'Doxxing', 'Hate Speech']) AS crime_type
WHERE unit_name = 'Cyber Crime Against Women and Children';
```

## 8. Verification Queries

```sql
-- Verify all tables and relationships
SELECT 
  'pnp_units' as table_name, 
  COUNT(*) as record_count 
FROM pnp_units

UNION ALL

SELECT 
  'pnp_unit_crime_types' as table_name, 
  COUNT(*) as record_count 
FROM pnp_unit_crime_types

UNION ALL

SELECT 
  'pnp_officer_profiles' as table_name, 
  COUNT(*) as record_count 
FROM pnp_officer_profiles

UNION ALL

SELECT 
  'admin_profiles' as table_name, 
  COUNT(*) as record_count 
FROM admin_profiles;

-- Verify units with crime types
SELECT 
  u.unit_name,
  u.unit_code,
  u.current_officers,
  ARRAY_AGG(ct.crime_type) as crime_types
FROM pnp_units u
LEFT JOIN pnp_unit_crime_types ct ON u.id = ct.unit_id
GROUP BY u.id, u.unit_name, u.unit_code, u.current_officers
ORDER BY u.unit_name;
```

## Key Improvements in This Revision

### 🔄 **Structural Changes**
1. **Removed Dual Unit Fields**: Eliminated confusing `unit` text field, now only using `unit_id` foreign key
2. **Made Unit Assignment Required**: `unit_id` is now `NOT NULL` ensuring every officer must be assigned
3. **Enhanced Constraints**: Added proper check constraints and unique constraints
4. **Better Indexing**: Optimized indexes for common queries including availability status

### 🚦 **Simplified Officer Availability Tracking**
1. **Dual Status System**: Separate `status` (active/on_leave/suspended/retired) and `availability_status` (available/busy/overloaded/unavailable)
2. **Manual Availability Control**: Officers can manually set their availability status
3. **Simple Status Logic**: Automatic status updates only when officer status changes (non-active = unavailable)
4. **Activity Monitoring**: Last status update timestamps for tracking changes

### 🛠️ **Simplified Trigger System**
1. **Officer Count Triggers**: Enhanced with detailed logging and active officer filtering
2. **Availability Status Triggers**: Simple status updates based on officer status changes only
3. **Comprehensive Coverage**: Handles INSERT, UPDATE, DELETE operations properly
4. **Manual Control**: Officers maintain full control over their availability status

### 📊 **Advanced Data Integrity**
1. **Default Test Data**: Pre-populated units and crime types for immediate testing
2. **Unique Constraints**: Prevents duplicate units and crime type assignments
3. **Proper References**: All foreign keys are properly defined with cascading rules
4. **Enhanced Validation**: Check constraints for availability status, leave types, workload limits
5. **GIN Indexes**: Optimized searching for specializations array field

### 🎯 **Simple Officer Assignment**
With this simplified schema:
- **Flutter App**: Can query available officers based on availability status
- **Web Admin**: Can view and manage basic officer availability
- **Manual Control**: Officers can set their own availability status as needed
- **Simple Logic**: Clear separation between officer status and availability status
- **Direct Updates**: Availability status updates only when manually changed or status changes

### 🔧 **API Enhancement Benefits**
1. **Simple Filtering**: Apps can filter by `availability_status = 'available'` for available officers
2. **Manual Control**: Officers have full control over their availability status
3. **Performance Tracking**: Basic metrics for officer performance and case assignment
4. **Easy Integration**: Simplified data structure for easier app development

This simplified revision provides a clean foundation for basic officer availability management across both the Flutter mobile app and Next.js web application.