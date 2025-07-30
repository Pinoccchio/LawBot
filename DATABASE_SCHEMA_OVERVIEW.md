# LawBot Database Schema Overview

This document provides a comprehensive overview of all database tables used across the LawBot platform, categorized by their primary usage in either the Mobile App (Flutter), Web App (Next.js), or shared between both platforms.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Shared Tables (Both Platforms)](#shared-tables-both-platforms)
3. [Mobile App Specific Tables](#mobile-app-specific-tables)
4. [Web App Specific Tables](#web-app-specific-tables)
5. [Functions and Triggers](#functions-and-triggers)
6. [Storage Buckets](#storage-buckets)
7. [Verification Queries](#verification-queries)
8. [Table Relationships](#table-relationships)

---

## Prerequisites

**⚠️ IMPORTANT**: Run these setup scripts in the Supabase SQL Editor in the exact order shown.

### Required Functions
```sql
-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## Shared Tables (Both Platforms)

These tables are used by both the Flutter mobile app and Next.js web application to maintain data consistency across platforms.

### 1. User Profiles Table (Citizens)
**Purpose**: Stores citizen user accounts who submit cybercrime reports  
**Used by**: Mobile App (primary), Web App (reference)

```sql
-- Drop existing table
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  user_type TEXT DEFAULT 'CLIENT' CHECK (user_type IN ('CLIENT', 'ADMIN')),
  user_status TEXT DEFAULT 'active' CHECK (user_status IN ('active', 'suspended', 'deleted')),
  profile_picture_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  last_active TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_user_profiles_firebase_uid ON user_profiles(firebase_uid);
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
CREATE INDEX idx_user_profiles_user_status ON user_profiles(user_status);

-- Apply updated_at trigger
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 2. Complaints Table (Cybercrime Reports)
**Purpose**: Core table storing all cybercrime reports submitted by citizens  
**Used by**: Mobile App (submission), Web App (investigation & management)

```sql
-- Drop existing table
DROP TABLE IF EXISTS complaints CASCADE;

-- Create complaints table
CREATE TABLE IF NOT EXISTS complaints (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  crime_type TEXT NOT NULL,
  description TEXT NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  incident_date_time TIMESTAMP WITH TIME ZONE NOT NULL,
  incident_location TEXT,
  estimated_financial_loss DECIMAL(12,2),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'underInvestigation', 'resolved', 'dismissed', 'requiresMoreInfo')),
  complaint_number TEXT UNIQUE,
  assigned_officer TEXT,
  remarks TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_complaints_user_id ON complaints(user_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_crime_type ON complaints(crime_type);
CREATE INDEX idx_complaints_complaint_number ON complaints(complaint_number);
CREATE INDEX idx_complaints_created_at ON complaints(created_at);

-- Apply updated_at trigger
CREATE TRIGGER update_complaints_updated_at
  BEFORE UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 3. Evidence Files Table
**Purpose**: Stores metadata and references to evidence files uploaded with complaints  
**Used by**: Mobile App (upload), Web App (review & download)

```sql
-- Drop existing table
DROP TABLE IF EXISTS evidence_files CASCADE;

-- Create evidence_files table
CREATE TABLE IF NOT EXISTS evidence_files (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE NOT NULL,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  download_url TEXT,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_evidence_files_complaint_id ON evidence_files(complaint_id);
CREATE INDEX idx_evidence_files_file_type ON evidence_files(file_type);
CREATE INDEX idx_evidence_files_uploaded_at ON evidence_files(uploaded_at);
```

### 4. Status History Table
**Purpose**: Tracks all status changes for complaints, providing complete audit history  
**Used by**: Mobile App (display history), Web App (update & track changes)

```sql
-- Drop existing table
DROP TABLE IF EXISTS status_history CASCADE;

-- Create status_history table
CREATE TABLE IF NOT EXISTS status_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'underInvestigation', 'resolved', 'dismissed', 'requiresMoreInfo')),
  updated_by TEXT NOT NULL,
  remarks TEXT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_status_history_complaint_id ON status_history(complaint_id);
CREATE INDEX idx_status_history_status ON status_history(status);
CREATE INDEX idx_status_history_timestamp ON status_history(timestamp);
```

### 5. Notifications Table
**Purpose**: Stores notifications for users across both platforms  
**Used by**: Mobile App (display notifications), Web App (admin notifications)

```sql
-- Drop existing table
DROP TABLE IF EXISTS notifications CASCADE;

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error', 'case_update', 'security_alert', 'legal_update', 'announcement')),
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  notification_category TEXT DEFAULT 'system',
  sender_name TEXT DEFAULT 'System',
  action_url TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  read_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for performance
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
```

---

## Mobile App Specific Tables

*Note: The mobile app primarily uses the shared tables above. Additional tables for AI chat functionality may be added as needed.*

---

## Web App Specific Tables

These tables are specifically designed for the Next.js web application's administrative and investigative features.

### 1. Admin Profiles Table
**Purpose**: Stores system administrator accounts with role-based permissions  
**Used by**: Web App only

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
```

### 2. PNP Units Table
**Purpose**: Manages specialized PNP cybercrime investigation units  
**Used by**: Web App only

```sql
-- Drop existing table
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

### 3. PNP Unit Crime Types Table
**Purpose**: Junction table linking PNP units to their specialized crime types  
**Used by**: Web App only

```sql
-- Drop existing table
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

### 4. PNP Officer Profiles Table
**Purpose**: Stores PNP officer accounts with unit assignments and performance metrics  
**Used by**: Web App only

```sql
-- Drop existing table
DROP TABLE IF EXISTS pnp_officer_profiles CASCADE;

-- Create pnp_officer_profiles table with proper foreign key from start
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
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'on_leave', 'suspended', 'retired')),
  -- Performance metrics
  total_cases INTEGER DEFAULT 0 CHECK (total_cases >= 0),
  active_cases INTEGER DEFAULT 0 CHECK (active_cases >= 0), 
  resolved_cases INTEGER DEFAULT 0 CHECK (resolved_cases >= 0),
  success_rate DECIMAL(5,2) DEFAULT 0.00 CHECK (success_rate BETWEEN 0 AND 100),
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

-- Apply updated_at trigger
CREATE TRIGGER update_pnp_officer_profiles_updated_at
  BEFORE UPDATE ON pnp_officer_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 5. Case Assignments Table
**Purpose**: Links complaints to specific officers and tracks assignment details  
**Used by**: Web App only

```sql
-- Drop existing table
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

---

## Functions and Triggers

### Complaint Number Generation
```sql
-- Function to generate complaint numbers
CREATE OR REPLACE FUNCTION generate_complaint_number()
RETURNS TEXT AS $$
DECLARE
  current_year TEXT;
  sequence_num INTEGER;
  complaint_num TEXT;
BEGIN
  current_year := EXTRACT(YEAR FROM NOW())::TEXT;
  
  -- Get the next sequence number for this year
  SELECT COALESCE(MAX(
    CAST(SUBSTRING(complaint_number FROM 'CYB-' || current_year || '-(\d+)') AS INTEGER)
  ), 0) + 1
  INTO sequence_num
  FROM complaints
  WHERE complaint_number LIKE 'CYB-' || current_year || '-%';
  
  complaint_num := 'CYB-' || current_year || '-' || LPAD(sequence_num::TEXT, 3, '0');
  
  RETURN complaint_num;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate complaint numbers
CREATE OR REPLACE FUNCTION set_complaint_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.complaint_number IS NULL THEN
    NEW.complaint_number := generate_complaint_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_complaint_number_trigger
  BEFORE INSERT ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION set_complaint_number();
```

### Unit Officer Count Management
```sql
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

-- Create trigger to keep unit officer counts updated
CREATE TRIGGER update_unit_officer_count_trigger
  AFTER INSERT OR UPDATE OR DELETE ON pnp_officer_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_unit_officer_count();
```

---

## Storage Buckets

**Note**: Storage buckets must be created through the Supabase Dashboard UI, not SQL.

### Step 1: Create Buckets via Dashboard
1. Go to Supabase Dashboard → Storage
2. Click "New Bucket"
3. Create bucket: `evidence-files` (Private)
4. Create bucket: `profile-pictures` (Private)

### Step 2: Add Storage Policies via SQL
```sql
-- Evidence files storage policies
CREATE POLICY "Allow authenticated users to upload evidence files" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'evidence-files' 
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Allow authenticated users to view evidence files" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'evidence-files' 
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Allow authenticated users to delete evidence files" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'evidence-files' 
    AND auth.role() = 'authenticated'
  );

-- Profile pictures storage policies
CREATE POLICY "Allow authenticated users to upload profile pictures" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'profile-pictures' 
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Allow authenticated users to view profile pictures" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'profile-pictures' 
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Allow authenticated users to update profile pictures" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'profile-pictures' 
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Allow authenticated users to delete profile pictures" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'profile-pictures' 
    AND auth.role() = 'authenticated'
  );
```

---

## Default Test Data

### PNP Units Sample Data
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

---

## Verification Queries

```sql
-- Verify all tables and relationships
SELECT 
  'user_profiles' as table_name, 
  COUNT(*) as record_count 
FROM user_profiles

UNION ALL

SELECT 
  'complaints' as table_name, 
  COUNT(*) as record_count 
FROM complaints

UNION ALL

SELECT 
  'evidence_files' as table_name, 
  COUNT(*) as record_count 
FROM evidence_files

UNION ALL

SELECT 
  'status_history' as table_name, 
  COUNT(*) as record_count 
FROM status_history

UNION ALL

SELECT 
  'notifications' as table_name, 
  COUNT(*) as record_count 
FROM notifications

UNION ALL

SELECT 
  'admin_profiles' as table_name, 
  COUNT(*) as record_count 
FROM admin_profiles

UNION ALL

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
  'case_assignments' as table_name, 
  COUNT(*) as record_count 
FROM case_assignments;

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

---

## Table Relationships

```
Firebase Auth Users
├── user_profiles (Citizens) 
├── admin_profiles (System Admins)
└── pnp_officer_profiles (Police Officers)

complaints (Cybercrime Reports)
├── evidence_files (Evidence attachments)
├── status_history (Status change audit)
├── case_assignments (Officer assignments)
└── notifications (Related notifications)

pnp_units (Police Units)
├── pnp_unit_crime_types (Specialized crime types)
├── pnp_officer_profiles (Assigned officers)
└── case_assignments (Unit case assignments)
```

## Platform Usage Summary

### Mobile App (Flutter) - **5 Primary Tables**
- ✅ `user_profiles` - User account management
- ✅ `complaints` - Report submission and tracking
- ✅ `evidence_files` - Evidence upload and management
- ✅ `status_history` - Case status tracking
- ✅ `notifications` - User notifications

### Web App (Next.js) - **10 Total Tables**
**Shared Tables (5):** All mobile app tables for case management

**Web-Specific Tables (5):**
- ✅ `admin_profiles` - System administrator accounts
- ✅ `pnp_units` - Police unit management
- ✅ `pnp_unit_crime_types` - Unit specialization mapping
- ✅ `pnp_officer_profiles` - Police officer accounts
- ✅ `case_assignments` - Case-to-officer assignment tracking

## Setup Instructions

1. **Open Supabase Dashboard** → SQL Editor
2. **Run Scripts in Order** - Execute each section sequentially
3. **Create Storage Buckets** - Use Dashboard UI for buckets
4. **Add Storage Policies** - Run storage SQL policies
5. **Insert Test Data** - Add sample PNP units and crime types
6. **Verify Setup** - Run verification queries to confirm everything works

This comprehensive schema ensures seamless integration between both platforms while maintaining appropriate role-based access and data security.