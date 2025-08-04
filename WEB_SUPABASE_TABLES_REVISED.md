# Enhanced Web App Supabase Tables - AI-Powered with Smart Features

This is an enhanced database schema that includes AI-powered risk assessment, pattern detection, and credibility scoring capabilities alongside basic officer availability management.

**⚠️ PREREQUISITE**: Run DOCUMENTATION.md database setup first to create the `update_updated_at_column()` function.

**⚠️ IMPORTANT**: This is a complete schema revision. Each table will be dropped and recreated individually.

**🤖 AI-ENHANCED APPROACH**: Added intelligent features:
- ✅ AI-powered priority and risk assessment using Gemini 2.0 Flash
- ✅ Smart pattern detection for scammer identification
- ✅ Report credibility scoring and quality assessment
- ✅ Evidence guidance with contextual suggestions
- ✅ Simple availability status: available/busy/overloaded/unavailable

**⚠️ TROUBLESHOOTING**: If you get "Failed to fetch" errors when creating officers:
1. Ensure the database has been updated with this simplified schema
2. Drop and recreate the `pnp_officer_profiles` table using the schema below
3. The API now only sends basic fields, so complex fields must be removed from database constraints

## 🎯 Quick Deployment Guide

### ✅ **MUST RUN (High Priority)**
- **8. Complaints Table** - Enhanced with AI fields, fixed field names
- **9. Evidence Files Table** - Enhanced validation capabilities  
- **10. Status History Table** - Renamed and enhanced structure
- **14. Priority Change Log Table** - NEW: AI audit trail
- **AI Database Functions** - NEW: Required for AI features

### 🔧 **NEW TABLES (Create if Not Exists)**
- **14. Priority Change Log Table** - AI audit functionality
- **15. AI Assessment Cache Table** - Performance optimization
- **16. Evidence Suggestions Table** - Smart evidence guidance

### ❓ **CONDITIONAL (Check First)**
- **0. Prerequisites** - Only if function doesn't exist
- **1-7. Base Tables** - Only if table doesn't exist or structure changed
- **11-13. AI Tables** - Only if tables don't exist

### 📊 **OPTIONAL (Nice to Have)**
- **Data Views** - AI analytics and monitoring

## 0. Prerequisites - Run First

```sql
-- ❓ CONDITIONAL: Only run if function doesn't exist
-- Check first: SELECT routine_name FROM information_schema.routines WHERE routine_name = 'update_updated_at_column';
-- Skip if function already exists

-- Function to update timestamps (REQUIRED for all tables)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## 1. User Profiles Table (Mobile App Citizens)

```sql
-- ❓ CONDITIONAL: Only run if table doesn't exist or needs structure changes
-- Check first: SELECT table_name FROM information_schema.tables WHERE table_name = 'user_profiles';
-- Skip if table exists and structure is correct

-- Drop existing table
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create user_profiles table for mobile app citizens
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
CREATE INDEX idx_user_profiles_user_type ON user_profiles(user_type);

-- Apply updated_at trigger
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS disabled for debugging purposes (can be enabled later)
-- ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

## Storage Bucket Configuration (evidence-files)

**✅ SIMPLE SOLUTION**: Set evidence-files bucket to PUBLIC to avoid RLS complications:

### Instructions:
1. **Go to Supabase Dashboard → Storage → evidence-files bucket**
2. **Click Settings (gear icon)**  
3. **Turn "Public bucket" to ON**
4. **Click Save**

### Result:
- ✅ No more `StorageException: new row violates row-level security policy` errors
- ✅ All authenticated users can upload evidence files
- ✅ File URLs are public but hard to guess
- ✅ Simple and reliable approach

### Security Notes:
- Users still need Firebase Auth to access the app
- Evidence files are publicly accessible via direct URL
- For production, consider implementing server-side access control if needed
```

## 2. Notifications Table (Mobile App)

```sql
-- ❓ CONDITIONAL: Only run if table doesn't exist or needs structure changes
-- Check first: SELECT table_name FROM information_schema.tables WHERE table_name = 'notifications';
-- Skip if table exists and structure is correct

-- Drop existing table
DROP TABLE IF EXISTS notifications CASCADE;

-- Create notifications table for mobile app users
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL, -- Firebase UID from user_profiles
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (type IN ('info', 'warning', 'error', 'success')),
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  notification_category TEXT DEFAULT 'system' CHECK (notification_category IN ('system', 'complaint', 'security', 'update')),
  action_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_priority ON notifications(priority);
CREATE INDEX idx_notifications_category ON notifications(notification_category);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
```

## 3. Admin Profiles Table (Web App)

```sql
-- ❓ CONDITIONAL: Only run if table doesn't exist or needs structure changes
-- Check first: SELECT table_name FROM information_schema.tables WHERE table_name = 'admin_profiles';
-- Skip if table exists and structure is correct

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

## 4. PNP Units Table (Enhanced)

```sql
-- ❓ CONDITIONAL: Only run if table doesn't exist or needs structure changes
-- Check first: SELECT table_name FROM information_schema.tables WHERE table_name = 'pnp_units';
-- Skip if table exists and structure is correct

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

## 5. PNP Unit Crime Types Table

```sql
-- ❓ CONDITIONAL: Only run if table doesn't exist or needs structure changes
-- Check first: SELECT table_name FROM information_schema.tables WHERE table_name = 'pnp_unit_crime_types';
-- Skip if table exists and structure is correct

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

## 6. PNP Officer Profiles Table (Enhanced with Availability Tracking)

```sql
-- ❓ CONDITIONAL: Only run if table doesn't exist or needs structure changes
-- Check first: SELECT table_name FROM information_schema.tables WHERE table_name = 'pnp_officer_profiles';
-- Skip if table exists and structure is correct

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

## 7. Case Assignments Table

```sql
-- ❓ CONDITIONAL: Only run if table doesn't exist or needs structure changes
-- Check first: SELECT table_name FROM information_schema.tables WHERE table_name = 'case_assignments';
-- Skip if table exists and structure is correct

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

## 8. Complaints Table (Unified Flutter/Web Schema with AI Enhancement)

**⚡ CRITICAL FIX**: This table resolves the `PostgrestException: Could not find the 'assigned_unit' column` error by including ALL fields required by both Flutter app and Web app.

**🤖 AI ENHANCED**: Now includes AI risk assessment fields, credibility scoring, and pattern detection capabilities for intelligent case prioritization.

```sql
-- ✅ UPDATE REQUIRED: This table has been enhanced with AI capabilities
-- 🔧 CHANGES: Added AI fields (ai_priority, ai_risk_score, ai_confidence_score, risk_factors, urgency_indicators, ai_reasoning)
-- 🔧 CHANGES: Added novelty fields (credibility_score, pattern_alert_shown)
-- 🔧 CHANGES: Fixed field name: estimated_loss (was estimated_financial_loss)
-- 🚨 PRIORITY: HIGH - Required for Flutter app compatibility and AI features

-- Drop existing table and recreate with unified schema
DROP TABLE IF EXISTS complaints CASCADE;

-- Create unified complaints table compatible with Flutter app and Web app
CREATE TABLE IF NOT EXISTS complaints (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  
  -- 👤 USER & IDENTIFICATION
  user_id TEXT NOT NULL, -- Firebase UID of complainant (Flutter: user_id)
  complaint_number TEXT UNIQUE NOT NULL, -- Format: CYB-YYYY-XXX (Flutter: complaint_number, Web: complaintNumber)
  
  -- 📝 COMPLAINT CONTENT  
  title TEXT, -- Auto-generated from description (Flutter: title, Web: title)
  crime_type TEXT NOT NULL, -- Crime type enum name (Flutter: crimeType.name, Web: crimeType)
  description TEXT NOT NULL, -- Detailed incident description (Flutter: description, Web: description)
  
  -- 📞 CONTACT INFORMATION
  full_name TEXT NOT NULL, -- Complainant name (Flutter: fullName, Web: fullName/complainant)
  email TEXT NOT NULL, -- Contact email (Flutter: email, Web: email)
  phone_number TEXT NOT NULL, -- Contact phone (Flutter: phoneNumber, Web: phoneNumber)
  
  -- 📅 INCIDENT DETAILS
  incident_date_time TIMESTAMP WITH TIME ZONE NOT NULL, -- When incident occurred (Flutter: incidentDateTime, Web: incidentDateTime)
  incident_location TEXT, -- Where incident occurred (Flutter: incidentLocation, Web: incidentLocation)
  estimated_loss DECIMAL(12,2), -- Financial loss (Flutter: estimatedFinancialLoss→estimated_loss, Web: estimatedLoss)
  
  -- 🔄 DYNAMIC FIELDS (Category-specific fields that change based on crime type)
  platform_website TEXT, -- Digital platform involved (Facebook, GCash, etc.) - shown for social media and financial crimes
  account_reference TEXT, -- Account numbers, transaction IDs, reference codes - shown for financial and data crimes
  
  -- 👤 SUSPECT INFORMATION (Dynamic based on crime category)
  suspect_name TEXT, -- Suspect name or alias - shown for crimes with personal suspects
  suspect_relationship TEXT CHECK (suspect_relationship IN ('Unknown', 'Acquaintance', 'Friend/Ex-friend', 'Family Member', 'Ex-partner/Romantic', 'Colleague/Classmate', 'Online Contact Only', 'Complete Stranger')), -- Relationship to suspect
  suspect_contact TEXT, -- Suspect contact info (phone, email, social media) - shown for crimes with known suspects
  suspect_details TEXT, -- Additional suspect information - shown for crimes with personal suspects
  
  -- 💻 TECHNICAL DETAILS (For technical and system-related crimes)
  system_details TEXT, -- Technical system information - shown for malware and technical crimes
  technical_info TEXT, -- Technical details and error messages - shown for technical crimes
  vulnerability_details TEXT, -- Security vulnerability information - shown for exploitation crimes
  attack_vector TEXT, -- How the attack was executed - shown for targeted and technical crimes
  
  -- 🔒 SECURITY & ASSESSMENT (For high-level and government crimes)
  security_level TEXT, -- Security classification of affected systems - shown for government and security crimes
  target_info TEXT, -- Information about attack targets - shown for targeted attacks and terrorism
  impact_assessment TEXT, -- Assessment of incident impact - shown for high-level security crimes
  
  -- 🚫 CONTENT INFORMATION (For content-related crimes)
  content_description TEXT, -- Description of illegal content - shown for content-related crimes
  
  -- 🎯 CASE MANAGEMENT
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Under Investigation', 'Requires More Information', 'Resolved', 'Dismissed')),
  priority TEXT DEFAULT 'low' CHECK (priority IN ('low', 'medium', 'high')), -- AI-calculated priority (Flutter: priority, Web: priority)
  risk_score INTEGER DEFAULT 30 CHECK (risk_score BETWEEN 0 AND 100), -- AI risk assessment (Flutter: riskScore, Web: riskScore)
  
  -- 👮 ASSIGNMENT INFORMATION
  assigned_unit TEXT, -- Unit name like 'Cyber Crime Investigation Cell' (Flutter: assignedUnit, Web: unit)
  unit_id UUID REFERENCES pnp_units(id) ON DELETE SET NULL, -- Foreign key to pnp_units table (Web: unitId)
  assigned_officer TEXT, -- Officer name (Flutter: assignedOfficer, Web: officer)
  assigned_officer_id UUID REFERENCES pnp_officer_profiles(id) ON DELETE SET NULL, -- FK to officer (Web: officerId)
  
  -- 🤖 AI ASSESSMENT FIELDS (Enhanced Intelligence)
  ai_priority TEXT DEFAULT NULL CHECK (ai_priority IS NULL OR ai_priority IN ('critical', 'high', 'medium', 'low')), -- AI-recommended priority
  ai_risk_score INTEGER DEFAULT NULL CHECK (ai_risk_score IS NULL OR (ai_risk_score >= 0 AND ai_risk_score <= 100)), -- AI-calculated risk score
  ai_confidence_score INTEGER DEFAULT NULL CHECK (ai_confidence_score IS NULL OR (ai_confidence_score >= 0 AND ai_confidence_score <= 100)), -- AI confidence percentage
  risk_factors JSONB DEFAULT '[]'::jsonb, -- AI-identified risk factors array
  urgency_indicators JSONB DEFAULT '[]'::jsonb, -- AI-detected urgency signals array
  last_ai_assessment TIMESTAMP WITH TIME ZONE DEFAULT NULL, -- Timestamp of last AI evaluation
  ai_reasoning TEXT DEFAULT NULL, -- AI explanation/reasoning text
  ai_assessment_version TEXT DEFAULT '1.0', -- AI model version tracking
  
  -- 🔍 NOVELTY FEATURES (Smart Enhancements)
  credibility_score INTEGER DEFAULT NULL CHECK (credibility_score IS NULL OR (credibility_score >= 0 AND credibility_score <= 100)), -- Report credibility scoring
  pattern_alert_shown BOOLEAN DEFAULT false, -- Pattern detection alert status
  
  -- 📋 METADATA
  remarks TEXT, -- Additional notes (Flutter: remarks, Web: remarks)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create comprehensive indexes for both Flutter and Web app queries
CREATE INDEX idx_complaints_user_id ON complaints(user_id); -- Flutter: getUserActiveComplaints()
CREATE INDEX idx_complaints_complaint_number ON complaints(complaint_number); -- Both: unique lookup
CREATE INDEX idx_complaints_crime_type ON complaints(crime_type); -- Web: crime type filtering
CREATE INDEX idx_complaints_status ON complaints(status); -- Both: active vs completed filtering
CREATE INDEX idx_complaints_priority ON complaints(priority); -- Web: priority-based sorting
CREATE INDEX idx_complaints_risk_score ON complaints(risk_score); -- Web: risk-based sorting
CREATE INDEX idx_complaints_assigned_unit ON complaints(assigned_unit); -- Web: unit-based filtering
CREATE INDEX idx_complaints_unit_id ON complaints(unit_id); -- Web: JOIN with pnp_units
CREATE INDEX idx_complaints_assigned_officer_id ON complaints(assigned_officer_id); -- Web: officer assignment
CREATE INDEX idx_complaints_created_at ON complaints(created_at); -- Both: chronological sorting
CREATE INDEX idx_complaints_updated_at ON complaints(updated_at); -- Both: recent activity
CREATE INDEX idx_complaints_title ON complaints(title); -- Web: search functionality

-- Indexes for dynamic fields (performance optimization)
CREATE INDEX idx_complaints_platform_website ON complaints(platform_website); -- Web: platform-based filtering
CREATE INDEX idx_complaints_suspect_name ON complaints(suspect_name); -- Web: suspect name searches
CREATE INDEX idx_complaints_suspect_relationship ON complaints(suspect_relationship); -- Web: relationship-based queries
CREATE INDEX idx_complaints_security_level ON complaints(security_level); -- Web: security classification filtering

-- AI Enhancement indexes (performance optimization)
CREATE INDEX idx_complaints_ai_priority ON complaints(ai_priority); -- AI priority filtering
CREATE INDEX idx_complaints_ai_risk_score ON complaints(ai_risk_score); -- AI risk score sorting
CREATE INDEX idx_complaints_last_ai_assessment ON complaints(last_ai_assessment); -- AI assessment tracking
CREATE INDEX idx_complaints_risk_factors ON complaints USING GIN(risk_factors); -- JSONB risk factors search
CREATE INDEX idx_complaints_urgency_indicators ON complaints USING GIN(urgency_indicators); -- JSONB urgency search
CREATE INDEX idx_complaints_credibility_score ON complaints(credibility_score); -- Credibility scoring
CREATE INDEX idx_complaints_pattern_alert_shown ON complaints(pattern_alert_shown); -- Pattern alert status

-- Apply updated_at trigger
CREATE TRIGGER update_complaints_updated_at
  BEFORE UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Auto-assign unit based on crime type (handles both manual and automatic assignment)
CREATE OR REPLACE FUNCTION auto_assign_unit()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle manual officer assignment (from Flutter app)
  IF NEW.assigned_officer_id IS NOT NULL THEN
    -- If officer is manually selected, get unit info from officer's profile
    SELECT 
      u.id,
      u.unit_name,
      o.full_name
    INTO 
      NEW.unit_id,
      NEW.assigned_unit,
      NEW.assigned_officer
    FROM pnp_officer_profiles o
    JOIN pnp_units u ON o.unit_id = u.id
    WHERE o.id = NEW.assigned_officer_id;
    
    -- Log manual assignment
    RAISE NOTICE 'Manual officer assignment: % to unit %', NEW.assigned_officer, NEW.assigned_unit;
    
  -- Handle automatic assignment (no officer specified)
  ELSIF NEW.assigned_unit IS NULL OR NEW.unit_id IS NULL THEN
    -- Auto-assign based on crime type
    NEW.assigned_unit := CASE 
      WHEN NEW.crime_type IN ('phishing', 'socialEngineering', 'spamMessages', 'fakeSocialMediaProfiles', 'onlineImpersonation', 'businessEmailCompromise', 'smsFraud') 
        THEN 'Cyber Crime Investigation Cell'
      WHEN NEW.crime_type IN ('onlineBankingFraud', 'creditCardFraud', 'investmentScams', 'cryptocurrencyFraud', 'onlineShoppingScams', 'paymentGatewayFraud', 'insuranceFraud', 'taxFraud', 'moneyLaundering') 
        THEN 'Economic Offenses Wing'
      WHEN NEW.crime_type IN ('identityTheft', 'dataBreach', 'unauthorizedSystemAccess', 'corporateEspionage', 'governmentDataTheft', 'medicalRecordsTheft', 'personalInformationTheft', 'accountTakeover') 
        THEN 'Cyber Security Division'
      WHEN NEW.crime_type IN ('ransomware', 'virusAttacks', 'trojanHorses', 'spyware', 'adware', 'worms', 'keyloggers', 'rootkits', 'cryptojacking', 'botnetAttacks') 
        THEN 'Cyber Crime Technical Unit'
      WHEN NEW.crime_type IN ('cyberstalking', 'onlineHarassment', 'cyberbullying', 'revengePorn', 'sextortion', 'onlinePredatoryBehavior', 'doxxing', 'hateSpeech') 
        THEN 'Cyber Crime Against Women and Children'
      WHEN NEW.crime_type IN ('childSexualAbuseMaterial', 'illegalContentDistribution', 'copyrightInfringement', 'softwarePiracy', 'illegalOnlineGambling', 'onlineDrugTrafficking', 'illegalWeaponsSales', 'humanTrafficking') 
        THEN 'Special Investigation Team'
      WHEN NEW.crime_type IN ('denialOfServiceAttacks', 'websiteDefacement', 'systemSabotage', 'networkIntrusion', 'sqlInjection', 'crossSiteScripting', 'manInTheMiddleAttacks') 
        THEN 'Critical Infrastructure Protection Unit'
      WHEN NEW.crime_type IN ('cyberterrorism', 'cyberWarfare', 'governmentSystemHacking', 'electionInterference', 'criticalInfrastructureAttacks', 'propagandaDistribution', 'stateSponsoredAttacks') 
        THEN 'National Security Cyber Division'
      WHEN NEW.crime_type IN ('zeroDayExploits', 'vulnerabilityExploitation', 'backdoorCreation', 'privilegeEscalation', 'codeInjection', 'bufferOverflowAttacks') 
        THEN 'Advanced Cyber Forensics Unit'
      WHEN NEW.crime_type IN ('advancedPersistentThreats', 'spearPhishing', 'ceoFraud', 'supplyChainAttacks', 'insiderThreats') 
        THEN 'Special Cyber Operations Unit'
      ELSE 'Cyber Crime Investigation Cell'
    END;
    
    -- Set unit_id based on assigned_unit
    SELECT id INTO NEW.unit_id FROM pnp_units WHERE unit_name = NEW.assigned_unit LIMIT 1;
    
    -- Log automatic assignment
    RAISE NOTICE 'Automatic unit assignment: % for crime type %', NEW.assigned_unit, NEW.crime_type;
  END IF;
  
  -- Ensure unit_id is set (fallback to default if lookup failed)
  IF NEW.unit_id IS NULL AND NEW.assigned_unit IS NOT NULL THEN
    SELECT id INTO NEW.unit_id FROM pnp_units WHERE unit_name = NEW.assigned_unit LIMIT 1;
    IF NEW.unit_id IS NULL THEN
      -- Fallback to first available unit
      SELECT id, unit_name INTO NEW.unit_id, NEW.assigned_unit FROM pnp_units ORDER BY id LIMIT 1;
      RAISE WARNING 'Unit lookup failed, using fallback unit: %', NEW.assigned_unit;
    END IF;
  END IF;
  
  -- Auto-generate title if not provided
  IF NEW.title IS NULL THEN
    NEW.title := CASE 
      WHEN LENGTH(NEW.description) > 100 THEN LEFT(NEW.description, 97) || '...'
      ELSE NEW.description
    END;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply auto-assign trigger
CREATE TRIGGER auto_assign_unit_trigger
  BEFORE INSERT OR UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION auto_assign_unit();
```

## 9. Evidence Files Table (Supporting Complaints)

```sql
-- ✅ UPDATE REQUIRED: Enhanced with file validation capabilities
-- 🔧 CHANGES: Added is_valid and validation_notes fields
-- 🔧 CHANGES: Improved field constraints (VARCHAR with size limits)
-- 😨 PRIORITY: MEDIUM - Enhanced file validation for better evidence management

-- Drop existing table and recreate
DROP TABLE IF EXISTS evidence_files CASCADE;

-- Store evidence files associated with complaints
CREATE TABLE IF NOT EXISTS evidence_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    
    -- File Information
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(1000) NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    file_size INTEGER NOT NULL,
    download_url TEXT,
    
    -- Metadata
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    uploaded_by UUID REFERENCES auth.users(id),
    
    -- File Validation
    is_valid BOOLEAN DEFAULT true,
    validation_notes TEXT
);

-- Create indexes
CREATE INDEX idx_evidence_files_complaint_id ON evidence_files(complaint_id);
CREATE INDEX idx_evidence_files_file_type ON evidence_files(file_type);
CREATE INDEX idx_evidence_files_uploaded_at ON evidence_files(uploaded_at);

-- RLS disabled for simple public bucket approach
-- ALTER TABLE evidence_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidence_files DISABLE ROW LEVEL SECURITY;
```

## 10. Status History Table

```sql
-- ✅ UPDATE REQUIRED: Table renamed and structure enhanced
-- 🔧 CHANGES: Renamed from 'complaint_status_history' to 'status_history'
-- 🔧 CHANGES: Added updated_by_user_id field for better user tracking
-- 🔧 CHANGES: Changed created_at to timestamp for consistency
-- 😨 PRIORITY: MEDIUM - Required for proper status tracking

-- Drop existing table and recreate
DROP TABLE IF EXISTS status_history CASCADE;

-- Track all status changes for complaints
CREATE TABLE IF NOT EXISTS status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    
    -- Status Change Details
    status VARCHAR NOT NULL CHECK (status IN ('Pending', 'Under Investigation', 'Requires More Information', 'Resolved', 'Dismissed')),
    updated_by VARCHAR NOT NULL,
    updated_by_user_id UUID REFERENCES auth.users(id),
    remarks TEXT,
    
    -- Timestamp
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_status_history_complaint_id ON status_history(complaint_id);
CREATE INDEX idx_status_history_timestamp ON status_history(timestamp);
CREATE INDEX idx_status_history_status ON status_history(status);
```

## 11. AI Risk Assessments Table

```sql
-- ❓ CONDITIONAL: Only run if table doesn't exist
-- Check first: SELECT table_name FROM information_schema.tables WHERE table_name = 'ai_risk_assessments';
-- Skip if table already exists and structure is correct

-- Drop existing table and recreate
DROP TABLE IF EXISTS ai_risk_assessments CASCADE;

-- Store detailed AI assessment results with full context
CREATE TABLE IF NOT EXISTS ai_risk_assessments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE NOT NULL,
    
    -- Assessment Results
    ai_risk_score INTEGER NOT NULL CHECK (ai_risk_score >= 0 AND ai_risk_score <= 100),
    ai_priority TEXT NOT NULL CHECK (ai_priority IN ('critical', 'high', 'medium', 'low')),
    confidence_score INTEGER NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 100),
    
    -- Analysis Details
    risk_factors JSONB NOT NULL DEFAULT '[]'::jsonb,
    urgency_indicators JSONB NOT NULL DEFAULT '[]'::jsonb,
    reasoning TEXT NOT NULL,
    
    -- Context Information
    assessment_type TEXT NOT NULL DEFAULT 'full' CHECK (assessment_type IN ('full', 'quick', 'update')),
    model_version TEXT NOT NULL DEFAULT 'gemini-2.0-flash',
    input_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    processing_time_ms INTEGER,
    
    -- Audit Fields
    created_by UUID REFERENCES auth.users(id),
    
    CONSTRAINT unique_complaint_assessment_per_timestamp 
        UNIQUE(complaint_id, created_at)
);

-- Create indexes for performance
CREATE INDEX idx_ai_assessments_complaint_id ON ai_risk_assessments(complaint_id);
CREATE INDEX idx_ai_assessments_created_at ON ai_risk_assessments(created_at);
CREATE INDEX idx_ai_assessments_ai_priority ON ai_risk_assessments(ai_priority);
CREATE INDEX idx_ai_assessments_ai_risk_score ON ai_risk_assessments(ai_risk_score);
CREATE INDEX idx_ai_assessments_model_version ON ai_risk_assessments(model_version);
CREATE INDEX idx_ai_assessments_risk_factors ON ai_risk_assessments USING GIN(risk_factors);
CREATE INDEX idx_ai_assessments_assessment_type ON ai_risk_assessments(assessment_type);
```

## 12. Scammer Patterns Table

```sql
-- ❓ CONDITIONAL: Only run if table doesn't exist
-- Check first: SELECT table_name FROM information_schema.tables WHERE table_name = 'scammer_patterns';
-- Skip if table already exists and structure is correct

-- Drop existing table and recreate
DROP TABLE IF EXISTS scammer_patterns CASCADE;

-- Store scammer identifiers and patterns across reports
CREATE TABLE IF NOT EXISTS scammer_patterns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE NOT NULL,
    
    -- Pattern Identifiers
    identifiers JSONB NOT NULL, -- Store email, phone, platform, etc.
    crime_type TEXT NOT NULL,
    
    -- Timestamps
    reported_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for pattern matching queries
CREATE INDEX idx_scammer_patterns_identifiers ON scammer_patterns USING GIN(identifiers);
CREATE INDEX idx_scammer_patterns_crime_type ON scammer_patterns(crime_type);
CREATE INDEX idx_scammer_patterns_reported_at ON scammer_patterns(reported_at);
CREATE INDEX idx_scammer_patterns_complaint_id ON scammer_patterns(complaint_id);

-- Apply updated_at trigger
CREATE TRIGGER update_scammer_patterns_updated_at
  BEFORE UPDATE ON scammer_patterns
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## 13. Report Credibility Scores Table

```sql
-- ❓ CONDITIONAL: Only run if table doesn't exist
-- Check first: SELECT table_name FROM information_schema.tables WHERE table_name = 'report_credibility_scores';
-- Skip if table already exists and structure is correct

-- Drop existing table and recreate
DROP TABLE IF EXISTS report_credibility_scores CASCADE;

-- Store credibility scores and analysis for reports
CREATE TABLE IF NOT EXISTS report_credibility_scores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE NOT NULL,
    
    -- Credibility Assessment
    overall_score INTEGER NOT NULL CHECK (overall_score >= 0 AND overall_score <= 100),
    strength_level TEXT NOT NULL CHECK (strength_level IN ('weak', 'moderate', 'strong', 'very_strong')),
    factors JSONB NOT NULL DEFAULT '{}'::jsonb, -- Store individual factor scores
    suggestions JSONB NOT NULL DEFAULT '[]'::jsonb, -- Store improvement suggestions
    
    -- Metadata
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes
CREATE INDEX idx_credibility_scores_complaint ON report_credibility_scores(complaint_id);
CREATE INDEX idx_credibility_scores_overall ON report_credibility_scores(overall_score);
CREATE INDEX idx_credibility_scores_strength ON report_credibility_scores(strength_level);
CREATE INDEX idx_credibility_scores_calculated ON report_credibility_scores(calculated_at);

-- Apply updated_at trigger
CREATE TRIGGER update_credibility_scores_updated_at
  BEFORE UPDATE ON report_credibility_scores
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## 14. Priority Change Log Table (Audit Trail)

```sql
-- ⚠️ NEW TABLE: Must be created for AI audit trail functionality
-- 🆕 PURPOSE: Comprehensive audit trail for all priority-related changes
-- 😨 PRIORITY: HIGH - Required for AI learning and officer feedback

-- Drop existing table and recreate
DROP TABLE IF EXISTS priority_change_log CASCADE;

-- Comprehensive audit trail for all priority-related changes
CREATE TABLE IF NOT EXISTS priority_change_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    
    -- Change Details
    change_type VARCHAR NOT NULL CHECK (change_type IN ('priority_change', 'risk_score_change', 'manual_override', 'ai_update')),
    old_value JSONB,
    new_value JSONB,
    
    -- Change Source
    changed_by_type VARCHAR NOT NULL CHECK (changed_by_type IN ('system', 'ai', 'user', 'officer', 'admin')),
    changed_by_user UUID REFERENCES auth.users(id),
    
    -- Officer Feedback (for learning)
    officer_approved BOOLEAN DEFAULT NULL,
    officer_feedback TEXT,
    feedback_recorded_at TIMESTAMPTZ,
    feedback_officer_id UUID,
    
    -- Context
    reason TEXT NOT NULL,
    confidence_before INTEGER,
    confidence_after INTEGER,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    session_id VARCHAR,
    
    -- Additional Data
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for performance
CREATE INDEX idx_priority_log_complaint_id ON priority_change_log(complaint_id);
CREATE INDEX idx_priority_log_created_at ON priority_change_log(created_at);
CREATE INDEX idx_priority_log_change_type ON priority_change_log(change_type);
CREATE INDEX idx_priority_log_changed_by_type ON priority_change_log(changed_by_type);
CREATE INDEX idx_priority_log_officer_approved ON priority_change_log(officer_approved);
CREATE INDEX idx_priority_log_session_id ON priority_change_log(session_id);
```

## 15. AI Assessment Cache Table (Performance)

```sql
-- ⚠️ NEW TABLE: Must be created for AI performance optimization
-- 🆕 PURPOSE: Cache frequent AI assessments for better performance
-- 😨 PRIORITY: MEDIUM - Performance optimization for AI features

-- Drop existing table and recreate
DROP TABLE IF EXISTS ai_assessment_cache CASCADE;

-- Cache frequent AI assessments for performance
CREATE TABLE IF NOT EXISTS ai_assessment_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Cache Key Components
    input_hash VARCHAR(64) NOT NULL UNIQUE,
    crime_type VARCHAR NOT NULL,
    description_hash VARCHAR(64) NOT NULL,
    
    -- Cached Results
    ai_risk_score INTEGER NOT NULL CHECK (ai_risk_score >= 0 AND ai_risk_score <= 100),
    ai_priority VARCHAR NOT NULL CHECK (ai_priority IN ('critical', 'high', 'medium', 'low')),
    confidence_score INTEGER NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 100),
    risk_factors JSONB NOT NULL DEFAULT '[]'::jsonb,
    urgency_indicators JSONB NOT NULL DEFAULT '[]'::jsonb,
    reasoning TEXT NOT NULL,
    
    -- Cache Metadata
    cache_hits INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    
    -- Model Information
    model_version VARCHAR NOT NULL DEFAULT 'gemini-2.0-flash',
    assessment_type VARCHAR NOT NULL DEFAULT 'full'
);

-- Create indexes for performance
CREATE INDEX idx_ai_cache_input_hash ON ai_assessment_cache(input_hash);
CREATE INDEX idx_ai_cache_crime_type ON ai_assessment_cache(crime_type);
CREATE INDEX idx_ai_cache_expires_at ON ai_assessment_cache(expires_at);
CREATE INDEX idx_ai_cache_last_used_at ON ai_assessment_cache(last_used_at);
CREATE INDEX idx_ai_cache_description_hash ON ai_assessment_cache(description_hash);
```

## 16. Evidence Suggestions Table

```sql
-- ⚠️ NEW TABLE: Must be created for smart evidence guidance
-- 🆕 PURPOSE: Store AI-generated evidence suggestions for different crime types
-- 😨 PRIORITY: MEDIUM - Enhanced user experience with evidence guidance

-- Drop existing table and recreate
DROP TABLE IF EXISTS evidence_suggestions CASCADE;

-- Store AI-generated evidence suggestions for different crime types
CREATE TABLE IF NOT EXISTS evidence_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Crime Type Mapping
    crime_type VARCHAR NOT NULL,
    category VARCHAR NOT NULL, -- Crime category
    suggestion_type VARCHAR NOT NULL CHECK (suggestion_type IN ('evidence_guidance', 'contextual_tip', 'collection_method')),
    
    -- Suggestion Content
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR NOT NULL CHECK (priority IN ('critical', 'high', 'medium', 'low')),
    icon VARCHAR(50),
    examples JSONB DEFAULT '[]'::jsonb, -- Array of example strings
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_evidence_suggestions_crime_type ON evidence_suggestions(crime_type);
CREATE INDEX idx_evidence_suggestions_category ON evidence_suggestions(category);
CREATE INDEX idx_evidence_suggestions_suggestion_type ON evidence_suggestions(suggestion_type);
CREATE INDEX idx_evidence_suggestions_priority ON evidence_suggestions(priority);
CREATE INDEX idx_evidence_suggestions_active ON evidence_suggestions(is_active);

-- Apply updated_at trigger
CREATE TRIGGER update_evidence_suggestions_updated_at
  BEFORE UPDATE ON evidence_suggestions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## 17. Enhanced Trigger Functions

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

## 12. Default Unit Data (For Testing)

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

## 13. Verification Queries

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

## 📱💻 Flutter/Web App Compatibility Guide

### 🔧 **Complaints Table Field Mappings**

The unified complaints table supports both platforms with the following field mappings:

| Database Field | Flutter App | Web App | Notes |
|---|---|---|---|
| `user_id` | `user_id` | `userId` | Firebase UID |
| `complaint_number` | `complaint_number` | `complaintNumber` | Format: CYB-YYYY-XXX |
| `title` | `title` | `title` | Auto-generated from description |
| `crime_type` | `crimeType.name` | `crimeType` | Enum name (snake_case) |
| `full_name` | `fullName` | `fullName`/`complainant` | Complainant name |
| `estimated_loss` | `estimatedFinancialLoss` | `estimatedLoss` | Decimal amount |
| `risk_score` | `riskScore` | `riskScore` | AI-calculated 0-100 |
| `assigned_unit` | `assignedUnit` | `unit` | Unit display name |
| `assigned_officer` | `assignedOfficer` | `officer` | Officer display name |
| `created_at` | `createdAt` | `createdAt` | ISO timestamp |

### 🎯 **Platform-Specific Usage Patterns**

#### Flutter App (Mobile)
- **Primary Use**: Complaint submission and tracking
- **Key Operations**: 
  - `submitComplaint()` - Creates new complaint with auto-assignment
  - `getUserActiveComplaints()` - Filters by status IN ('Pending', 'Under Investigation', 'Requires More Information')
  - `getUserCompletedComplaints()` - Filters by status IN ('Resolved', 'Dismissed')
- **Auto-Assignment**: Uses `auto_assign_unit()` trigger to assign unit based on crime type
- **Evidence Upload**: Links to `evidence_files` table via `complaint_id`

#### Web App (Next.js)
- **Primary Use**: Case management and investigation
- **Key Operations**:
  - Admin dashboard displays all complaints with priority sorting
  - PNP officer dashboard shows assigned cases via `case_assignments` table
  - Evidence viewer accesses files through `evidence_files` table
  - Status updates logged in `complaint_status_history` table
- **Officer Assignment**: Links complaints to officers via `assigned_officer_id` FK
- **Unit Management**: Uses `unit_id` FK to `pnp_units` table for proper relationships

### 🔄 **Data Flow Integration**

```
1. Flutter App Submission:
   complaint.submitComplaint() 
   → complaints table (with auto_assign_unit trigger)
   → evidence_files table (if files attached)
   → complaint_status_history table (initial "Pending" status)

2. Web App Processing:
   Admin assigns officer 
   → case_assignments table (links complaint to officer)
   → complaints.assigned_officer_id updated
   → complaint_status_history table (status change logged)

3. Cross-Platform Sync:
   Flutter app queries by user_id
   → Shows updated status and assigned officer
   → Real-time updates via Supabase subscriptions
```

### ⚠️ **Critical Compatibility Notes**

1. **Column Names**: Database uses `snake_case`, apps handle conversion:
   - Flutter: Direct mapping (already uses snake_case)
   - Web: Convert `camelCase` ↔ `snake_case` in service layer

2. **Status Values**: Must use exact strings:
   - ✅ 'Pending', 'Under Investigation', 'Requires More Information', 'Resolved', 'Dismissed'
   - ❌ 'pending', 'under_investigation', etc.

3. **Crime Types**: Use enum names from Flutter's `CrimeType`:
   - ✅ 'phishing', 'onlineBankingFraud', 'identityTheft'
   - ❌ 'Phishing', 'Online Banking Fraud', 'Identity Theft'

4. **Unit Assignment**: Automatic via trigger, but manual override supported:
   - Flutter: Relies on `auto_assign_unit()` trigger
   - Web: Can manually reassign via `unit_id` FK

### 🚀 **Migration Instructions**

To apply this unified schema:

1. **Run the complete table creation scripts** in Supabase SQL Editor
2. **Update existing data** using the data transformation queries
3. **Test Flutter app complaint submission** - should work without errors
4. **Verify Web app case display** - should show all fields correctly
5. **Check evidence file uploads** - should link properly to complaints

### 🔍 **Troubleshooting Common Issues**

| Error | Cause | Solution |
|---|---|---|
| `Could not find the 'assigned_unit' column` | Old schema missing fields | Run unified complaints table creation |
| `estimated_financial_loss doesn't exist` | Column name mismatch | Use `estimated_loss` (updated schema) |
| `status constraint violation` | Wrong status values | Use exact case-sensitive status strings |
| `crime_type not recognized` | Display name vs enum name | Use enum names (snake_case) not display names |

This unified approach ensures seamless operation across both Flutter mobile app and Next.js web application with a single source of truth for complaint data.

## 🔄 Dynamic Fields Implementation

### Field-to-Category Mapping

The dynamic fields in the complaints table change visibility based on the selected crime type:

#### 📱 Communication & Social Media Crimes
- `incident_location`, `platform_website`, `account_reference`, `estimated_loss`, `suspect_name`, `suspect_relationship`, `suspect_contact`, `suspect_details`

#### 💰 Financial & Economic Crimes  
- `incident_location`, `platform_website`, `account_reference`, `estimated_loss`, `suspect_name`, `suspect_contact`

#### 🔒 Data & Privacy Crimes
- `incident_location`, `account_reference`, `technical_info`, `vulnerability_details`, `security_level`, `impact_assessment`

#### 💻 Malware & System Attacks
- `system_details`, `technical_info`, `attack_vector`

#### 👥 Harassment & Exploitation
- `incident_location`, `platform_website`, `suspect_name`, `suspect_relationship`, `suspect_contact`, `suspect_details`, `content_description`

#### 🚫 Content-Related Crimes
- `incident_location`, `platform_website`, `estimated_loss`, `suspect_name`, `suspect_contact`, `content_description`

#### ⚡ System Disruption & Sabotage
- `system_details`, `technical_info`, `vulnerability_details`, `attack_vector`, `impact_assessment`

#### 🏛️ Government & Terrorism
- `incident_location`, `security_level`, `target_info`, `impact_assessment`

#### 🔍 Technical Exploitation
- `system_details`, `technical_info`, `vulnerability_details`, `target_info`, `attack_vector`, `impact_assessment`

#### 🎯 Targeted Attacks
- `target_info`, `attack_vector`, `system_details`, `technical_info`, `impact_assessment`

### Flutter App Dynamic Implementation
The Flutter app uses `DynamicFieldService` to determine which fields to show based on the selected crime type, providing a tailored user experience for each category of cybercrime.

## AI Database Functions

```sql
-- 🔧 NEW FUNCTIONS: Must be created for AI functionality
-- 🎯 PURPOSE: Essential functions for AI assessment, caching, and pattern detection
-- 🚨 PRIORITY: HIGH - Required for AI features to work properly

-- Function to update complaint AI assessment
CREATE OR REPLACE FUNCTION update_complaint_ai_assessment(
    p_complaint_id UUID,
    p_ai_risk_score INTEGER,
    p_ai_priority VARCHAR,
    p_confidence_score INTEGER,
    p_risk_factors JSONB,
    p_urgency_indicators JSONB,
    p_reasoning TEXT,
    p_assessment_type VARCHAR DEFAULT 'full'
) RETURNS VOID AS $$
BEGIN
    -- Update complaints table
    UPDATE complaints SET
        ai_priority = p_ai_priority,
        ai_risk_score = p_ai_risk_score,
        ai_confidence_score = p_confidence_score,
        risk_factors = p_risk_factors,
        urgency_indicators = p_urgency_indicators,
        last_ai_assessment = NOW(),
        ai_reasoning = p_reasoning,
        updated_at = NOW()
    WHERE id = p_complaint_id;
    
    -- Insert detailed assessment record
    INSERT INTO ai_risk_assessments (
        complaint_id,
        ai_risk_score,
        ai_priority,
        confidence_score,
        risk_factors,
        urgency_indicators,
        reasoning,
        assessment_type,
        input_data
    ) VALUES (
        p_complaint_id,
        p_ai_risk_score,
        p_ai_priority,
        p_confidence_score,
        p_risk_factors,
        p_urgency_indicators,
        p_reasoning,
        p_assessment_type,
        '{}'::jsonb
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get AI assessment history
CREATE OR REPLACE FUNCTION get_ai_assessment_history(p_complaint_id UUID)
RETURNS TABLE (
    assessment_id UUID,
    ai_risk_score INTEGER,
    ai_priority VARCHAR,
    confidence_score INTEGER,
    reasoning TEXT,
    created_at TIMESTAMPTZ,
    assessment_type VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.ai_risk_score,
        a.ai_priority,
        a.confidence_score,
        a.reasoning,
        a.created_at,
        a.assessment_type
    FROM ai_risk_assessments a
    WHERE a.complaint_id = p_complaint_id
    ORDER BY a.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cleanup expired cache
CREATE OR REPLACE FUNCTION cleanup_expired_ai_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM ai_assessment_cache 
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check for similar email patterns
CREATE OR REPLACE FUNCTION check_email_patterns(email_input TEXT, days_back INTEGER DEFAULT 30)
RETURNS TABLE (
    complaint_id UUID,
    suspect_contact TEXT,
    crime_type TEXT,
    created_at TIMESTAMPTZ,
    match_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.suspect_contact,
        c.crime_type,
        c.created_at,
        COUNT(*) OVER () as match_count
    FROM complaints c
    WHERE (c.suspect_contact ILIKE '%' || email_input || '%' 
           OR c.description ILIKE '%' || email_input || '%')
    AND c.created_at >= (CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL)
    ORDER BY c.created_at DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check for similar phone patterns
CREATE OR REPLACE FUNCTION check_phone_patterns(phone_input TEXT, days_back INTEGER DEFAULT 30)
RETURNS TABLE (
    complaint_id UUID,
    suspect_contact TEXT,
    phone_number TEXT,
    crime_type TEXT,
    created_at TIMESTAMPTZ,
    match_count BIGINT
) AS $$
DECLARE
    clean_phone TEXT;
BEGIN
    -- Clean phone number (remove non-digits except +)
    clean_phone := regexp_replace(phone_input, '[^0-9+]', '', 'g');
    
    RETURN QUERY
    SELECT 
        c.id,
        c.suspect_contact,
        c.phone_number,
        c.crime_type,
        c.created_at,
        COUNT(*) OVER () as match_count
    FROM complaints c
    WHERE (c.suspect_contact ILIKE '%' || clean_phone || '%' 
           OR c.phone_number ILIKE '%' || clean_phone || '%'
           OR c.description ILIKE '%' || clean_phone || '%')
    AND c.created_at >= (CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL)
    ORDER BY c.created_at DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Auto-create scammer pattern entries
CREATE OR REPLACE FUNCTION auto_create_scammer_pattern()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create pattern entry if we have suspect identifiers
    IF NEW.suspect_contact IS NOT NULL OR NEW.phone_number IS NOT NULL THEN
        INSERT INTO scammer_patterns (
            complaint_id,
            identifiers,
            crime_type,
            reported_at
        ) VALUES (
            NEW.id,
            jsonb_build_object(
                'suspect_contact', NEW.suspect_contact,
                'phone_number', NEW.phone_number,
                'platform_website', NEW.platform_website,
                'suspect_name', NEW.suspect_name
            ),
            NEW.crime_type,
            NEW.created_at
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for auto-creating scammer patterns
DROP TRIGGER IF EXISTS auto_create_scammer_pattern_trigger ON complaints;
CREATE TRIGGER auto_create_scammer_pattern_trigger
    AFTER INSERT ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_scammer_pattern();
```

## Data Views for Analytics

```sql
-- 📊 NEW VIEWS: Must be created for AI analytics and monitoring
-- 🎯 PURPOSE: Monitor AI performance and compare with rule-based assessments
-- 🚨 PRIORITY: MEDIUM - Useful for AI performance monitoring

-- View to see AI vs Rule-based comparison
CREATE OR REPLACE VIEW complaint_priority_comparison AS
SELECT 
    c.id,
    c.complaint_number,
    c.crime_type,
    c.priority as rule_based_priority,
    c.risk_score as rule_based_risk_score,
    c.ai_priority,
    c.ai_risk_score,
    c.ai_confidence_score,
    c.last_ai_assessment,
    CASE 
        WHEN c.ai_priority IS NOT NULL THEN 'AI'
        ELSE 'Rule-based'
    END as effective_source,
    COALESCE(c.ai_priority, c.priority) as effective_priority,
    COALESCE(c.ai_risk_score, c.risk_score) as effective_risk_score,
    c.created_at
FROM complaints c
WHERE c.status IN ('Pending', 'Under Investigation', 'Requires More Information')
ORDER BY c.created_at DESC;

-- View for AI performance monitoring
CREATE OR REPLACE VIEW ai_assessment_performance AS
SELECT 
    ai_priority,
    COUNT(*) as assessment_count,
    AVG(ai_risk_score) as avg_risk_score,
    AVG(confidence_score) as avg_confidence,
    MIN(confidence_score) as min_confidence,
    MAX(confidence_score) as max_confidence,
    COUNT(CASE WHEN confidence_score >= 90 THEN 1 END) as high_confidence_count,
    COUNT(CASE WHEN confidence_score < 70 THEN 1 END) as low_confidence_count
FROM complaints 
WHERE ai_priority IS NOT NULL
GROUP BY ai_priority
ORDER BY 
    CASE ai_priority 
        WHEN 'critical' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        WHEN 'low' THEN 4 
    END;
```

## ✅ Merge Complete!

**WEB_SUPABASE_TABLES_REVISED.md is now the single source of truth with:**
- ✅ All 16 tables properly numbered and organized
- ✅ Complete AI enhancement capabilities
- ✅ All database functions and views
- ✅ Proper trigger system for pattern detection
- ✅ Performance optimization with caching
- ✅ Analytics and monitoring views

**📝 REMINDER: AI_RISK_ASSESSMENT_TABLES.md is no longer needed** - everything has been merged into the main WEB file with proper organization!