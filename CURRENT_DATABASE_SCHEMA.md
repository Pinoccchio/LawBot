# LawBot Current Database Schema - Production Ready
**Last Updated: January 2025**

This document represents the ACTUAL database schema currently in use across both the Flutter mobile app and Next.js web application. All tables, functions, and relationships listed here are actively implemented and working.

## 🎯 Database Architecture Overview

- **Database**: Supabase (PostgreSQL)
- **Authentication**: Firebase Auth (both apps)
- **File Storage**: Supabase Storage (evidence-files bucket - PUBLIC)
- **Real-time**: Supabase Realtime subscriptions

## 📊 Core Tables (15 Tables Total)

### 1. **user_profiles** - Mobile App Citizens
```sql
CREATE TABLE user_profiles (
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
```
**Used by**: Flutter Mobile App
**Purpose**: Stores citizen user accounts who submit complaints

### 2. **admin_profiles** - System Administrators
```sql
CREATE TABLE admin_profiles (
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
```
**Used by**: Next.js Web App
**Purpose**: System administrators who manage the platform

### 3. **pnp_officer_profiles** - Police Officers
```sql
CREATE TABLE pnp_officer_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  badge_number TEXT UNIQUE NOT NULL,
  rank TEXT NOT NULL,
  unit_id UUID NOT NULL REFERENCES pnp_units(id),
  phone_number TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'inactive')),
  availability_status TEXT DEFAULT 'available' CHECK (availability_status IN ('available', 'busy', 'overloaded', 'unavailable')),
  specializations TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Next.js Web App
**Purpose**: PNP officers who investigate complaints

### 4. **pnp_units** - Police Investigation Units
```sql
CREATE TABLE pnp_units (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  unit_name TEXT UNIQUE NOT NULL,
  unit_code TEXT UNIQUE NOT NULL,
  specialization TEXT NOT NULL,
  description TEXT,
  contact_info JSONB,
  head_officer_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Both Apps
**Purpose**: 10 specialized cybercrime investigation units

### 5. **complaints** - Main Complaint Records ⭐
```sql
CREATE TABLE complaints (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES user_profiles(firebase_uid),
  complaint_number TEXT UNIQUE NOT NULL,
  crime_type TEXT NOT NULL,
  title TEXT,
  description TEXT NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  incident_date_time TIMESTAMP WITH TIME ZONE NOT NULL,
  incident_location TEXT,
  estimated_loss DECIMAL(15,2),
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Under Investigation', 'Requires More Information', 'Resolved', 'Dismissed')),
  
  -- Standard Assessment Fields
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  risk_score INTEGER DEFAULT 50 CHECK (risk_score >= 0 AND risk_score <= 100),
  
  -- AI Assessment Fields
  ai_priority TEXT,
  ai_risk_score INTEGER CHECK (ai_risk_score >= 0 AND ai_risk_score <= 100),
  ai_confidence_score INTEGER CHECK (ai_confidence_score >= 0 AND ai_confidence_score <= 100),
  risk_factors TEXT[],
  urgency_indicators TEXT[],
  ai_reasoning TEXT,
  last_ai_assessment TIMESTAMP WITH TIME ZONE,
  
  -- Assignment Fields
  assigned_unit TEXT,
  assigned_officer_id TEXT REFERENCES pnp_officer_profiles(firebase_uid),
  remarks TEXT,
  
  -- Dynamic Fields (Crime-Specific)
  platform_website TEXT,
  account_reference TEXT,
  suspect_name TEXT,
  suspect_relationship TEXT,
  suspect_contact TEXT,
  suspect_details TEXT,
  system_details TEXT,
  technical_info TEXT,
  vulnerability_details TEXT,
  attack_vector TEXT,
  security_level TEXT,
  target_info TEXT,
  impact_assessment TEXT,
  content_description TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Both Apps
**Purpose**: Core complaint data with AI enhancement

### 6. **evidence_files** - Complaint Evidence
```sql
CREATE TABLE evidence_files (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  download_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Both Apps
**Purpose**: Evidence file metadata (actual files in Supabase Storage)

### 7. **status_history** - Complaint Status Audit Trail
```sql
CREATE TABLE status_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  updated_by TEXT NOT NULL,
  updated_by_user_id TEXT,
  remarks TEXT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Both Apps
**Purpose**: Track all status changes with audit trail

### 8. **notifications** - User Notifications
```sql
CREATE TABLE notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (type IN ('info', 'warning', 'error', 'success', 'case_assignment', 'case_update', 'case_submitted')),
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  notification_category TEXT DEFAULT 'system' CHECK (notification_category IN ('system', 'complaint', 'security', 'update', 'officer_assignment', 'complaint_status', 'case_management')),
  action_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  additional_data JSONB,
  sender_name TEXT DEFAULT 'System',
  related_complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Flutter Mobile App
**Purpose**: In-app notifications for users and officers

### 9. **case_assignments** - Officer-Case Relationships
```sql
CREATE TABLE case_assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  officer_id TEXT NOT NULL REFERENCES pnp_officer_profiles(firebase_uid),
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'reassigned')),
  assigned_by TEXT NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE,
  notes TEXT
);
```
**Used by**: Next.js Web App
**Purpose**: Track officer assignments to cases

### 10. **user_analytics** - Mobile App Analytics
```sql
CREATE TABLE user_analytics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES user_profiles(firebase_uid),
  event_type TEXT NOT NULL,
  event_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Flutter Mobile App
**Purpose**: Track user activity and analytics

### 11. **ai_risk_assessments** - AI Analysis Records
```sql
CREATE TABLE ai_risk_assessments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  ai_priority TEXT NOT NULL,
  ai_risk_score INTEGER NOT NULL CHECK (ai_risk_score >= 0 AND ai_risk_score <= 100),
  confidence_score INTEGER NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 100),
  risk_factors TEXT[],
  urgency_indicators TEXT[],
  reasoning TEXT,
  model_version TEXT DEFAULT 'gemini-2.0-flash',
  processing_time_ms INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Flutter Mobile App
**Purpose**: Store AI assessment history and audit trail

### 12. **ai_assessment_cache** - Performance Optimization
```sql
CREATE TABLE ai_assessment_cache (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cache_key TEXT UNIQUE NOT NULL,
  crime_type TEXT NOT NULL,
  input_hash TEXT NOT NULL,
  priority TEXT NOT NULL,
  risk_score INTEGER NOT NULL,
  confidence_score INTEGER,
  risk_factors TEXT[],
  urgency_indicators TEXT[],
  reasoning TEXT,
  model_version TEXT DEFAULT 'gemini-2.0-flash',
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Flutter Mobile App
**Purpose**: Cache AI responses for 24 hours (20-40x performance improvement)

### 13. **evidence_suggestions** - AI Evidence Guidance
```sql
CREATE TABLE evidence_suggestions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID REFERENCES complaints(id) ON DELETE CASCADE,
  crime_type TEXT NOT NULL,
  suggestions TEXT[] NOT NULL,
  importance_levels TEXT[],
  additional_tips TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Flutter Mobile App
**Purpose**: Store AI-generated evidence suggestions

### 14. **scammer_patterns** - Pattern Detection Data
```sql
CREATE TABLE scammer_patterns (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  pattern_type TEXT NOT NULL,
  pattern_data JSONB NOT NULL,
  confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
  related_complaints UUID[],
  first_detected TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Flutter Mobile App
**Purpose**: Track detected scammer patterns across complaints

### 15. **report_credibility_scores** - Report Quality Assessment
```sql
CREATE TABLE report_credibility_scores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  overall_score DECIMAL(3,2) NOT NULL CHECK (overall_score >= 0 AND overall_score <= 1),
  completeness_score DECIMAL(3,2),
  consistency_score DECIMAL(3,2),
  detail_score DECIMAL(3,2),
  improvement_suggestions TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Flutter Mobile App
**Purpose**: Store report quality assessments

## 🔧 Database Functions

### 1. **update_updated_at_column()** - Timestamp Trigger
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```
**Purpose**: Automatically update timestamps on record changes

### 2. **get_available_officers_with_caseload()** - Officer Assignment
```sql
CREATE OR REPLACE FUNCTION get_available_officers_with_caseload(
  unit_name TEXT,
  max_active_cases INTEGER DEFAULT 10
)
RETURNS TABLE (
  firebase_uid TEXT,
  full_name TEXT,
  badge_number TEXT,
  rank TEXT,
  active_cases BIGINT,
  availability_status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.firebase_uid,
    p.full_name,
    p.badge_number,
    p.rank,
    COUNT(ca.id) FILTER (WHERE ca.status = 'active') AS active_cases,
    p.availability_status
  FROM pnp_officer_profiles p
  JOIN pnp_units u ON p.unit_id = u.id
  LEFT JOIN case_assignments ca ON p.firebase_uid = ca.officer_id
  WHERE u.unit_name = get_available_officers_with_caseload.unit_name
    AND p.status = 'active'
    AND p.availability_status IN ('available', 'busy')
  GROUP BY p.firebase_uid, p.full_name, p.badge_number, p.rank, p.availability_status
  HAVING COUNT(ca.id) FILTER (WHERE ca.status = 'active') < max_active_cases
  ORDER BY COUNT(ca.id) FILTER (WHERE ca.status = 'active') ASC;
END;
$$ LANGUAGE plpgsql;
```
**Used by**: Officer assignment system
**Purpose**: Find available officers with lowest caseload

## 📁 Storage Configuration

### evidence-files Bucket
- **Access**: PUBLIC (no RLS)
- **Purpose**: Store complaint evidence files
- **File Types**: Images, Videos, Documents (PDF, DOC, etc.)
- **Max Size**: 25MB total per complaint
- **Path Structure**: `{complaint_id}/{file_name}`

## 🔑 Key Relationships

1. **User → Complaints**: One user can have many complaints
2. **Complaint → Evidence Files**: One complaint can have many evidence files (max 5)
3. **Complaint → Status History**: One complaint has many status updates
4. **Complaint → AI Assessments**: One complaint can have multiple AI assessments
5. **Officer → Case Assignments**: One officer can be assigned to many cases
6. **Unit → Officers**: One unit has many officers

## 🚀 Active Features Using Database

### Flutter Mobile App
- ✅ User registration and profile management
- ✅ Complaint submission with AI assessment
- ✅ Evidence file upload
- ✅ Real-time notifications
- ✅ Status tracking and history
- ✅ AI-powered features (risk assessment, evidence guidance, pattern detection)
- ✅ Analytics tracking

### Next.js Web App
- ✅ Admin and officer authentication
- ✅ Case management dashboard
- ✅ Officer assignment system
- ✅ Status updates with templates
- ✅ Evidence viewing
- ✅ Unit management
- ❌ Real-time updates (planned)

## 📝 Important Notes

1. **Authentication**: Both apps use Firebase Auth, with firebase_uid as the foreign key
2. **Timestamps**: All timestamps are stored in UTC
3. **File Storage**: Evidence files use PUBLIC bucket for simplicity
4. **AI Caching**: 24-hour cache significantly improves performance
5. **Status Flow**: Pending → Under Investigation → Requires More Info → Resolved/Dismissed
6. **Officer Assignment**: Currently simplified (no complex notifications)

## 🔄 Recent Changes

1. **Simplified Officer Assignment**: Removed complex notification system
2. **Fixed Foreign Keys**: Updated to use firebase_uid instead of UUID references
3. **Enhanced AI Fields**: Added comprehensive AI assessment fields to complaints table
4. **Extended Notifications**: Added new types for case management

This schema represents the current production state of the LawBot platform as of January 2025.