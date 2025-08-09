# LawBot Current Database Schema - Production Ready
**Last Updated: January 2025**

This document represents the ACTUAL database schema currently in use across both the Flutter mobile app and Next.js web application. All tables, functions, and relationships listed here are actively implemented and working.

## 🎯 Database Architecture Overview

- **Database**: Supabase (PostgreSQL)
- **Authentication**: Firebase Auth (both apps)
- **File Storage**: Supabase Storage (evidence-files bucket - PUBLIC)
- **Real-time**: Supabase Realtime subscriptions

## 📊 Core Tables (16 Tables Total)

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
  
  -- Complaint Editing Fields
  last_citizen_update TIMESTAMP WITH TIME ZONE,
  update_request_message TEXT, -- PNP officer's message about what info is needed
  total_updates INTEGER DEFAULT 0,
  
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

### 16. **complaint_updates** - Field-Level Change Tracking
```sql
CREATE TABLE complaint_updates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  updated_by TEXT NOT NULL,
  update_type TEXT NOT NULL CHECK (update_type IN ('citizen_update', 'officer_update', 'system_update')),
  fields_updated TEXT[] NOT NULL,
  old_values JSONB,
  new_values JSONB NOT NULL,
  update_reason TEXT,
  update_notes TEXT,
  device_info JSONB,
  requires_ai_reassessment BOOLEAN DEFAULT TRUE,
  ai_reassessment_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
```
**Used by**: Both Apps
**Purpose**: Track field-level changes when complaints are edited

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

### 2. **get_available_officers_with_caseload()** - Enhanced Officer Assignment
```sql
CREATE OR REPLACE FUNCTION get_available_officers_with_caseload(
  unit_name TEXT,
  priority_level TEXT DEFAULT 'normal',
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
    -- Enhanced availability filtering based on priority
    AND (
      CASE 
        WHEN priority_level = 'urgent' THEN p.availability_status IN ('available', 'busy')
        ELSE p.availability_status = 'available'
      END
    )
    -- Always exclude overloaded and unavailable officers
    AND p.availability_status NOT IN ('overloaded', 'unavailable')
  GROUP BY p.firebase_uid, p.full_name, p.badge_number, p.rank, p.availability_status
  HAVING COUNT(ca.id) FILTER (WHERE ca.status = 'active') < max_active_cases
  ORDER BY 
    -- Prioritize available officers first, then busy officers
    CASE p.availability_status 
      WHEN 'available' THEN 1 
      WHEN 'busy' THEN 2 
      ELSE 3 
    END,
    COUNT(ca.id) FILTER (WHERE ca.status = 'active') ASC;
END;
$$ LANGUAGE plpgsql;
```
**Used by**: Officer assignment system
**Purpose**: Find available officers with priority-based availability filtering and lowest caseload

### 3. **track_complaint_update()** - Update Tracking Trigger
```sql
CREATE OR REPLACE FUNCTION track_complaint_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update general complaint timestamp
  -- DO NOT automatically set citizen update fields here
  -- Citizen update fields (last_citizen_update, total_updates) should ONLY be set 
  -- by the apply_complaint_update() function when citizens actually update complaints
  
  -- Update general updated_at timestamp
  NEW.updated_at = TIMEZONE('utc', NOW());
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```
**Used by**: Database triggers
**Purpose**: Track general complaint updates (citizen-specific tracking handled separately by apply_complaint_update function)

### 4. **get_complaint_with_updates()** - Get Complaint with Edit History
```sql
CREATE OR REPLACE FUNCTION get_complaint_with_updates(
  p_complaint_id UUID,
  p_firebase_uid TEXT  -- Firebase UID passed from application
)
RETURNS TABLE (
  complaint_data JSONB,
  update_history JSONB,
  can_edit BOOLEAN
) AS $$
DECLARE
  v_complaint_status TEXT;
BEGIN
  -- Get the complaint status
  SELECT status INTO v_complaint_status
  FROM complaints
  WHERE id = p_complaint_id;
  
  RETURN QUERY
  SELECT 
    -- Get complaint data with latest updates applied
    to_jsonb(c.*) AS complaint_data,
    
    -- Get update history
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', cu.id,
          'updated_by', cu.updated_by,
          'updater_name', 
          CASE 
            WHEN cu.update_type = 'citizen_update' THEN up.full_name
            WHEN cu.update_type = 'officer_update' THEN pop.full_name
            ELSE 'System'
          END,
          'update_type', cu.update_type,
          'fields_updated', cu.fields_updated,
          'old_values', cu.old_values,
          'new_values', cu.new_values,
          'update_reason', cu.update_reason,
          'created_at', cu.created_at
        ) ORDER BY cu.created_at DESC
      ) FILTER (WHERE cu.id IS NOT NULL),
      '[]'::jsonb
    ) AS update_history,
    
    -- Check if user can edit
    (c.user_id = p_firebase_uid AND c.status = 'Requires More Information') AS can_edit
    
  FROM complaints c
  LEFT JOIN complaint_updates cu ON c.id = cu.complaint_id
  LEFT JOIN user_profiles up ON cu.updated_by = up.firebase_uid AND cu.update_type = 'citizen_update'
  LEFT JOIN pnp_officer_profiles pop ON cu.updated_by = pop.firebase_uid AND cu.update_type = 'officer_update'
  WHERE c.id = p_complaint_id
  GROUP BY c.id, c.user_id, c.status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```
**Used by**: Both Apps
**Purpose**: Retrieve complaint with complete update history and edit permissions

### 5. **apply_complaint_update()** - Apply Field Updates to Complaint
```sql
CREATE OR REPLACE FUNCTION apply_complaint_update(
  p_complaint_id UUID,
  p_firebase_uid TEXT,  -- Firebase UID passed from application
  p_updates JSONB,
  p_update_reason TEXT DEFAULT NULL,
  p_update_notes TEXT DEFAULT NULL,
  p_device_info JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_complaint_status TEXT;
  v_old_values JSONB;
  v_fields_updated TEXT[];
  v_update_id UUID;
  v_key TEXT;
  v_value JSONB;
BEGIN
  
  -- Check if user can update this complaint
  SELECT status INTO v_complaint_status
  FROM complaints
  WHERE id = p_complaint_id AND user_id = p_firebase_uid;
  
  IF v_complaint_status IS NULL THEN
    RAISE EXCEPTION 'Complaint not found or unauthorized';
  END IF;
  
  IF v_complaint_status != 'Requires More Information' THEN
    RAISE EXCEPTION 'Complaint can only be updated when status is "Requires More Information"';
  END IF;
  
  -- Get current values for fields being updated
  SELECT to_jsonb(c.*) INTO v_old_values
  FROM complaints c
  WHERE id = p_complaint_id;
  
  -- Extract field names being updated
  v_fields_updated := ARRAY[]::TEXT[];
  FOR v_key IN SELECT jsonb_object_keys(p_updates)
  LOOP
    v_fields_updated := array_append(v_fields_updated, v_key);
  END LOOP;
  
  -- Create update record
  INSERT INTO complaint_updates (
    complaint_id,
    updated_by,
    update_type,
    fields_updated,
    old_values,
    new_values,
    update_reason,
    update_notes,
    device_info
  ) VALUES (
    p_complaint_id,
    p_firebase_uid,
    'citizen_update',
    v_fields_updated,
    v_old_values,
    p_updates,
    p_update_reason,
    p_update_notes,
    p_device_info
  ) RETURNING id INTO v_update_id;
  
  -- Apply updates to complaint table
  -- This is a dynamic update based on the fields provided
  -- Extract actual text values from JSONB to prevent extra quotes
  FOR v_key, v_value IN SELECT * FROM jsonb_each(p_updates)
  LOOP
    EXECUTE format('UPDATE complaints SET %I = $1 WHERE id = $2', v_key)
    USING (v_value #>> '{}'), p_complaint_id;
  END LOOP;
  
  -- Update citizen update tracking fields (ONLY when citizen actually updates)
  UPDATE complaints SET 
    last_citizen_update = TIMEZONE('utc', NOW()),
    total_updates = COALESCE(total_updates, 0) + 1,
    updated_at = TIMEZONE('utc', NOW())
  WHERE id = p_complaint_id;
  
  -- Return success response
  RETURN jsonb_build_object(
    'success', true,
    'update_id', v_update_id,
    'message', 'Complaint updated successfully'
  );
  
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```
**Used by**: Flutter Mobile App
**Purpose**: Apply citizen updates to complaints when status = "Requires More Information"

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
7. **Complaint → Updates**: One complaint can have many field updates (audit trail)

## 🚀 Active Features Using Database

### Flutter Mobile App
- ✅ User registration and profile management
- ✅ Complaint submission with AI assessment
- ✅ Evidence file upload with proper MIME type detection
- ✅ Real-time notifications
- ✅ Status tracking and history
- ✅ AI-powered features (risk assessment, evidence guidance, pattern detection)
- ✅ Analytics tracking
- ✅ **Complete complaint editing system** (citizens can update complaints when status = "Requires More Information")
- ✅ **Field-level change tracking** with complete audit trail and update history
- ✅ **Visual update indicators** with green badges and detailed info panels in Reports tab
- ✅ **Evidence upload during updates** with correct MIME types (image/jpeg, video/mp4, etc.) 
- ✅ **AI re-assessment** automatically triggered after complaint updates
- ✅ **Modern UI components** with blue/emerald gradient design and responsive layouts

### Next.js Web App
- ✅ Admin and officer authentication
- ✅ Case management dashboard with AI-powered prioritization
- ✅ Officer assignment system
- ✅ Status updates with templates
- ✅ Evidence viewing with secure file handling
- ✅ Unit management
- ✅ **PNP My Cases interface** with visual indicators for citizen updates
- ✅ **Complaint update indicators** (green badges, "NEEDS REVIEW" alerts, update timestamps)
- ✅ **Case Detail modal** with comprehensive update information display
- ✅ **Officer request messages** showing what additional information was requested
- ✅ **Update history tracking** with detailed change logs and field-level audit trail
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
5. **Complete Complaint Editing System** (January 2025): Full citizen complaint editing functionality
   - ✅ **complaint_updates table**: Field-level change tracking with audit trail
   - ✅ **apply_complaint_update() function**: Secure citizen updates with proper citizen tracking fields
   - ✅ **track_complaint_update() trigger**: Fixed to prevent false citizen update indicators
   - ✅ **get_complaint_with_updates() function**: Retrieve edit history with permissions
   - ✅ **Database constraints**: Removed suspect_relationship CHECK constraint for app-level validation
   - ✅ **Additional complaint fields**: `last_citizen_update`, `update_request_message`, `total_updates`
   - ✅ **Cross-platform integration**: Full Flutter mobile app and Next.js web app support
   - ✅ **Visual indicators**: Update badges and info panels in both mobile and web interfaces
   - ✅ **Evidence upload fix**: Proper MIME type detection for complaint updates (image/jpeg, video/mp4, etc.)
   - ✅ **AI re-assessment**: Automatic AI risk assessment after citizen updates
   - ✅ **Fixed false citizen indicators**: Officer status changes no longer trigger false "Case Updated by Citizen" indicators

This schema represents the current production state of the LawBot platform as of January 2025.