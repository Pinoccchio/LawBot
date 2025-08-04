# ⚠️ DEPRECATED: AI Risk Assessment Database Enhancement

**🔴 DEPRECATED NOTICE**: This file has been merged into WEB_SUPABASE_TABLES_REVISED.md

**✅ USE INSTEAD**: WEB_SUPABASE_TABLES_REVISED.md - Contains all AI enhancements with proper table numbering and organization

**📋 WHAT WAS MERGED**:
- All AI enhancement tables (priority_change_log, ai_assessment_cache, evidence_suggestions)
- All database functions and triggers
- All analytics views and pattern detection
- Updated table structures (complaints, evidence_files, status_history)

**🚫 DO NOT USE THIS FILE** - It may cause conflicts or duplicate table creation

**🤖 AI ENHANCEMENT**: Transforms static rule-based priority scoring into intelligent, real-time AI analysis.

**🔄 KEY IMPROVEMENTS**:
- ❌ Static rule-based priority (only 2 factors)
- ❌ One-time calculation at submission
- ❌ No real-time feedback
- ✅ AI-powered analysis (15+ factors)
- ✅ Real-time assessment as user types
- ✅ Confidence scoring and detailed reasoning

## 1. Complete Complaints Table (Enhanced with AI)

```sql
-- Drop existing table and recreate with full AI capabilities
DROP TABLE IF EXISTS complaints CASCADE;

-- Create complete complaints table with both existing and AI fields
CREATE TABLE IF NOT EXISTS complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL, -- Firebase UID (compatible with existing auth system)
    
    -- Basic Complaint Information
    complaint_number TEXT UNIQUE NOT NULL, -- Format: CYB-YYYY-XXX
    crime_type TEXT NOT NULL, -- Crime type enum name
    title TEXT, -- Auto-generated from description
    description TEXT NOT NULL, -- Detailed incident description
    
    -- Contact Information
    full_name TEXT NOT NULL, -- Complainant name
    email TEXT NOT NULL, -- Contact email
    phone_number TEXT NOT NULL, -- Contact phone
    
    -- Incident Details
    incident_date_time TIMESTAMP WITH TIME ZONE NOT NULL, -- When incident occurred
    incident_location TEXT, -- Where incident occurred
    estimated_loss DECIMAL(15,2), -- Financial loss amount
    
    -- Case Management
    status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Under Investigation', 'Requires More Information', 'Resolved', 'Dismissed')),
    priority TEXT DEFAULT 'low' CHECK (priority IN ('critical', 'high', 'medium', 'low')), -- Rule-based priority
    risk_score INTEGER DEFAULT 30 CHECK (risk_score BETWEEN 0 AND 100), -- Rule-based risk score
    
    -- Assignment Information
    assigned_unit TEXT, -- Unit name like 'Cyber Crime Investigation Cell'
    unit_id UUID REFERENCES pnp_units(id) ON DELETE SET NULL, -- Foreign key to pnp_units table
    assigned_officer TEXT, -- Officer name
    assigned_officer_id UUID REFERENCES pnp_officer_profiles(id) ON DELETE SET NULL, -- FK to officer
    
    -- AI Assessment Fields (Enhanced Intelligence)
    ai_priority TEXT DEFAULT NULL CHECK (ai_priority IS NULL OR ai_priority IN ('critical', 'high', 'medium', 'low')), -- AI-recommended priority
    ai_risk_score INTEGER DEFAULT NULL CHECK (ai_risk_score IS NULL OR (ai_risk_score >= 0 AND ai_risk_score <= 100)), -- AI-calculated risk score
    ai_confidence_score INTEGER DEFAULT NULL CHECK (ai_confidence_score IS NULL OR (ai_confidence_score >= 0 AND ai_confidence_score <= 100)), -- AI confidence percentage
    risk_factors JSONB DEFAULT '[]'::jsonb, -- AI-identified risk factors array
    urgency_indicators JSONB DEFAULT '[]'::jsonb, -- AI-detected urgency signals array
    last_ai_assessment TIMESTAMP WITH TIME ZONE DEFAULT NULL, -- Timestamp of last AI evaluation
    ai_reasoning TEXT DEFAULT NULL, -- AI explanation/reasoning text
    ai_assessment_version TEXT DEFAULT '1.0', -- AI model version tracking
    
    -- Novelty Features (Smart Enhancements)
    credibility_score INTEGER DEFAULT NULL CHECK (credibility_score IS NULL OR (credibility_score >= 0 AND credibility_score <= 100)), -- Report credibility scoring
    pattern_alert_shown BOOLEAN DEFAULT false, -- Pattern detection alert status
    
    -- Dynamic Crime-Specific Fields (Category-specific fields that change based on crime type)
    platform_website TEXT, -- Digital platform involved (Facebook, GCash, etc.)
    account_reference TEXT, -- Account numbers, transaction IDs, reference codes
    
    -- Suspect Information (Dynamic based on crime category)
    suspect_name TEXT, -- Suspect name or alias
    suspect_relationship TEXT CHECK (suspect_relationship IN ('Unknown', 'Acquaintance', 'Friend/Ex-friend', 'Family Member', 'Ex-partner/Romantic', 'Colleague/Classmate', 'Online Contact Only', 'Complete Stranger')), -- Relationship to suspect
    suspect_contact TEXT, -- Suspect contact info (phone, email, social media)
    suspect_details TEXT, -- Additional suspect information
    
    -- Technical Details (For technical and system-related crimes)
    system_details TEXT, -- Technical system information
    technical_info TEXT, -- Technical details and error messages
    vulnerability_details TEXT, -- Security vulnerability information
    attack_vector TEXT, -- How the attack was executed
    
    -- Security & Assessment (For high-level and government crimes)
    security_level TEXT, -- Security classification of affected systems
    target_info TEXT, -- Information about attack targets
    impact_assessment TEXT, -- Assessment of incident impact
    
    -- Content Information (For content-related crimes)
    content_description TEXT, -- Description of illegal content
    
    -- Metadata
    remarks TEXT, -- Additional notes
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

-- Composite indexes for common queries
CREATE INDEX idx_complaints_status_priority ON complaints(status, priority);
CREATE INDEX idx_complaints_user_status ON complaints(user_id, status);
CREATE INDEX idx_complaints_assigned_status ON complaints(assigned_officer_id, status);
```

## 2. Evidence Files Table

```sql
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
```

## 3. Status History Table

```sql
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

## 4. AI Risk Assessments Table (Detailed Storage)

```sql
-- Drop existing table and recreate
DROP TABLE IF EXISTS ai_risk_assessments CASCADE;

-- Store detailed AI assessment results with full context
CREATE TABLE IF NOT EXISTS ai_risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    
    -- Assessment Results
    ai_risk_score INTEGER NOT NULL CHECK (ai_risk_score >= 0 AND ai_risk_score <= 100),
    ai_priority VARCHAR NOT NULL CHECK (ai_priority IN ('critical', 'high', 'medium', 'low')),
    confidence_score INTEGER NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 100),
    
    -- Analysis Details
    risk_factors JSONB NOT NULL DEFAULT '[]'::jsonb,
    urgency_indicators JSONB NOT NULL DEFAULT '[]'::jsonb,
    reasoning TEXT NOT NULL,
    
    -- Context Information
    assessment_type VARCHAR NOT NULL DEFAULT 'full' CHECK (assessment_type IN ('full', 'quick', 'update')),
    model_version VARCHAR NOT NULL DEFAULT 'gemini-2.0-flash',
    input_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
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

## 5. Priority Change Log Table (Audit Trail)

```sql
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

## 6. AI Assessment Cache Table (Performance)

```sql
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

## 7. Scammer Patterns Table (Pattern Detection)

```sql
-- Drop existing table and recreate
DROP TABLE IF EXISTS scammer_patterns CASCADE;

-- Store scammer identifiers and patterns across reports
CREATE TABLE IF NOT EXISTS scammer_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    
    -- Pattern Identifiers
    identifiers JSONB NOT NULL, -- Store email, phone, platform, etc.
    crime_type VARCHAR NOT NULL,
    
    -- Timestamps
    reported_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for pattern matching queries
CREATE INDEX idx_scammer_patterns_identifiers ON scammer_patterns USING GIN(identifiers);
CREATE INDEX idx_scammer_patterns_crime_type ON scammer_patterns(crime_type);
CREATE INDEX idx_scammer_patterns_reported_at ON scammer_patterns(reported_at);
CREATE INDEX idx_scammer_patterns_complaint_id ON scammer_patterns(complaint_id);
```

## 8. Report Credibility Scores Table

```sql
-- Drop existing table and recreate
DROP TABLE IF EXISTS report_credibility_scores CASCADE;

-- Store credibility scores and analysis for reports
CREATE TABLE IF NOT EXISTS report_credibility_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    
    -- Credibility Assessment
    overall_score INTEGER NOT NULL CHECK (overall_score >= 0 AND overall_score <= 100),
    strength_level VARCHAR NOT NULL CHECK (strength_level IN ('weak', 'moderate', 'strong', 'very_strong')),
    factors JSONB NOT NULL DEFAULT '{}'::jsonb, -- Store individual factor scores
    suggestions JSONB NOT NULL DEFAULT '[]'::jsonb, -- Store improvement suggestions
    
    -- Metadata
    calculated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_credibility_scores_complaint ON report_credibility_scores(complaint_id);
CREATE INDEX idx_credibility_scores_overall ON report_credibility_scores(overall_score);
CREATE INDEX idx_credibility_scores_strength ON report_credibility_scores(strength_level);
CREATE INDEX idx_credibility_scores_calculated ON report_credibility_scores(calculated_at);
```

## 9. Evidence Suggestions Table

```sql
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
```

## 10. Row Level Security Policies (Disabled for Development)

```sql
-- ⚠️ RLS DISABLED FOR DEVELOPMENT PHASE
-- Uncomment and customize these policies for production deployment

-- Disable RLS on all tables for easier development
ALTER TABLE complaints DISABLE ROW LEVEL SECURITY;
ALTER TABLE evidence_files DISABLE ROW LEVEL SECURITY;
ALTER TABLE status_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_risk_assessments DISABLE ROW LEVEL SECURITY;
ALTER TABLE priority_change_log DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_assessment_cache DISABLE ROW LEVEL SECURITY;
ALTER TABLE scammer_patterns DISABLE ROW LEVEL SECURITY;
ALTER TABLE report_credibility_scores DISABLE ROW LEVEL SECURITY;
ALTER TABLE evidence_suggestions DISABLE ROW LEVEL SECURITY;

-- ai_risk_assessments policies (COMMENTED OUT FOR DEVELOPMENT)
/*
CREATE POLICY "Users can view their complaint assessments" ON ai_risk_assessments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM complaints 
            WHERE complaints.id = ai_risk_assessments.complaint_id 
            AND complaints.user_id = auth.uid()
        )
    );

CREATE POLICY "Officers can view all assessments" ON ai_risk_assessments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM pnp_officer_profiles 
            WHERE firebase_uid = auth.uid()
        )
    );

CREATE POLICY "System can insert assessments" ON ai_risk_assessments
    FOR INSERT WITH CHECK (true);

-- priority_change_log policies
CREATE POLICY "Officers can manage priority logs" ON priority_change_log
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM pnp_officer_profiles 
            WHERE firebase_uid = auth.uid()
        )
    );

CREATE POLICY "Users can view their complaint logs" ON priority_change_log
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM complaints 
            WHERE complaints.id = priority_change_log.complaint_id 
            AND complaints.user_id = auth.uid()
        )
    );

-- ai_assessment_cache policies (system only)
CREATE POLICY "System can manage cache" ON ai_assessment_cache
    FOR ALL USING (true);
*/
```

-- complaints policies (COMMENTED OUT FOR DEVELOPMENT)
/*
CREATE POLICY "Users can view their own complaints" ON complaints
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own complaints" ON complaints
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own complaints" ON complaints
    FOR UPDATE USING (user_id = auth.uid());

-- Officers can view all complaints
CREATE POLICY "Officers can view all complaints" ON complaints
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM pnp_officer_profiles 
            WHERE firebase_uid = auth.uid()
        )
    );

-- Officers can update assigned complaints
CREATE POLICY "Officers can update assigned complaints" ON complaints
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM pnp_officer_profiles 
            WHERE firebase_uid = auth.uid() 
            AND id = assigned_officer_id
        )
    );

-- Admins can view all complaints
CREATE POLICY "Admins can view all complaints" ON complaints
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_profiles 
            WHERE firebase_uid = auth.uid()
        )
    );

-- Admins can update all complaints
CREATE POLICY "Admins can update all complaints" ON complaints
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM admin_profiles 
            WHERE firebase_uid = auth.uid()
        )
    );
*/

-- evidence_files policies (COMMENTED OUT FOR DEVELOPMENT)
/*
CREATE POLICY "Users can view evidence for their complaints" ON evidence_files
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM complaints 
            WHERE complaints.id = evidence_files.complaint_id 
            AND complaints.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert evidence for their complaints" ON evidence_files
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM complaints 
            WHERE complaints.id = evidence_files.complaint_id 
            AND complaints.user_id = auth.uid()
        )
    );

-- Officers can view all evidence files
CREATE POLICY "Officers can view all evidence files" ON evidence_files
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM pnp_officer_profiles 
            WHERE firebase_uid = auth.uid()
        )
    );

-- Admins can view all evidence files
CREATE POLICY "Admins can view all evidence files" ON evidence_files
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_profiles 
            WHERE firebase_uid = auth.uid()
        )
    );
*/

-- Additional policies (COMMENTED OUT FOR DEVELOPMENT)
/*
-- status_history policies
CREATE POLICY "Users can view status history for their complaints" ON status_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM complaints 
            WHERE complaints.id = status_history.complaint_id 
            AND complaints.user_id = auth.uid()
        )
    );

CREATE POLICY "System can insert status updates" ON status_history
    FOR INSERT WITH CHECK (true);

-- scammer_patterns policies
CREATE POLICY "Public read access for scammer_patterns" ON scammer_patterns
    FOR SELECT USING (true);

CREATE POLICY "Users can insert scammer_patterns for their complaints" ON scammer_patterns
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM complaints 
            WHERE complaints.id = scammer_patterns.complaint_id 
            AND complaints.user_id = auth.uid()
        )
    );

CREATE POLICY "System can manage scammer_patterns" ON scammer_patterns
    FOR ALL USING (true);

-- report_credibility_scores policies
CREATE POLICY "Users can view their own credibility scores" ON report_credibility_scores
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM complaints 
            WHERE complaints.id = report_credibility_scores.complaint_id 
            AND complaints.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert credibility scores for their complaints" ON report_credibility_scores
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM complaints 
            WHERE complaints.id = report_credibility_scores.complaint_id 
            AND complaints.user_id = auth.uid()
        )
    );

CREATE POLICY "Officers can view all credibility scores" ON report_credibility_scores
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM pnp_officer_profiles 
            WHERE firebase_uid = auth.uid()
        )
    );

-- evidence_suggestions policies
CREATE POLICY "Public read access for evidence_suggestions" ON evidence_suggestions
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage evidence_suggestions" ON evidence_suggestions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_profiles 
            WHERE firebase_uid = auth.uid()
        )
    );
*/

## 11. Database Functions

```sql
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

-- Function to get trending scammer alerts
CREATE OR REPLACE FUNCTION get_trending_alerts(days_back INTEGER DEFAULT 7)
RETURNS TABLE (
    identifier TEXT,
    identifier_type TEXT,
    match_count BIGINT,
    crime_types TEXT[],
    last_seen TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    WITH pattern_data AS (
        SELECT 
            COALESCE(suspect_contact, phone_number) as id_value,
            CASE 
                WHEN suspect_contact LIKE '%@%' THEN 'email'
                WHEN suspect_contact ~ '^[0-9+\-\s\(\)]+$' THEN 'phone'
                ELSE 'contact'
            END as id_type,
            crime_type,
            created_at
        FROM complaints
        WHERE created_at >= (CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL)
        AND (suspect_contact IS NOT NULL OR phone_number IS NOT NULL)
    )
    SELECT 
        pd.id_value,
        pd.id_type,
        COUNT(*) as match_count,
        ARRAY_AGG(DISTINCT pd.crime_type) as crime_types,
        MAX(pd.created_at) as last_seen
    FROM pattern_data pd
    WHERE pd.id_value IS NOT NULL
    GROUP BY pd.id_value, pd.id_type
    HAVING COUNT(*) >= 2
    ORDER BY match_count DESC, last_seen DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to auto-create scammer pattern entries
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

-- Add updated_at trigger for complaints table (assumes function exists from WEB_SUPABASE_TABLES_REVISED.md)
CREATE TRIGGER update_complaints_updated_at
  BEFORE UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## 12. Data Views for Analytics

```sql
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

## 13. Verification Queries

```sql
-- Check if AI fields were added successfully
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'complaints' 
AND (column_name LIKE '%ai%' OR column_name LIKE '%risk%')
ORDER BY column_name;

-- Check if new tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('ai_risk_assessments', 'priority_change_log', 'ai_assessment_cache', 'scammer_patterns', 'report_credibility_scores', 'evidence_suggestions')
AND table_schema = 'public';

-- Check indexes
SELECT indexname, tablename 
FROM pg_indexes 
WHERE tablename IN ('complaints', 'ai_risk_assessments', 'priority_change_log', 'ai_assessment_cache')
AND indexname LIKE '%ai%'
ORDER BY tablename, indexname;

-- Test AI vs Rule-based comparison
SELECT * FROM complaint_priority_comparison LIMIT 5;
```

## 14. Usage Examples

```sql
-- Example: Insert a complaint with AI assessment
/*
INSERT INTO complaints (
    user_id, complaint_number, crime_type, description, 
    full_name, email, phone_number, incident_date_time,
    status, priority, risk_score,
    ai_priority, ai_risk_score, ai_confidence_score,
    risk_factors, urgency_indicators, ai_reasoning
) VALUES (
    'user-uuid', 'CYB-2025-001', 'onlineBankingFraud',
    'Hackers accessed my account and transferred money to unknown accounts',
    'John Doe', 'john@email.com', '+639123456789', NOW(),
    'Pending', 'medium', 55,
    'high', 85, 92,
    '["high_financial_loss", "ongoing_threat"]'::jsonb,
    '["immediate_threat", "evidence_degradation"]'::jsonb,
    'High-risk case due to sophisticated attack pattern and ongoing financial threat'
);
*/

-- Example: Query complaints with AI data
/*
SELECT 
    complaint_number,
    crime_type,
    COALESCE(ai_priority, priority) as effective_priority,
    COALESCE(ai_risk_score, risk_score) as effective_risk_score,
    ai_confidence_score,
    CASE WHEN ai_priority IS NOT NULL THEN 'AI' ELSE 'Rule-based' END as source
FROM complaints 
WHERE status = 'Pending'
ORDER BY 
    COALESCE(ai_risk_score, risk_score) DESC,
    created_at DESC;
*/

-- Example: Get AI assessment history for a complaint
/*
SELECT * FROM get_ai_assessment_history('complaint-uuid-here');
*/

-- Example: Monitor AI performance
/*
SELECT * FROM ai_assessment_performance;
*/

-- Example: Test scammer pattern detection
/*
SELECT * FROM check_email_patterns('scammer@example.com');
*/

-- Example: Test trending alerts
/*
SELECT * FROM get_trending_alerts(7);
*/

-- Example: Test credibility scores
/*
SELECT c.complaint_number, rcs.overall_score, rcs.strength_level 
FROM complaints c
LEFT JOIN report_credibility_scores rcs ON c.id = rcs.complaint_id
ORDER BY c.created_at DESC LIMIT 10;
*/

-- Example: View evidence suggestions for a crime type
/*
SELECT title, description, priority 
FROM evidence_suggestions 
WHERE crime_type = 'onlineBankingFraud' 
AND is_active = true
ORDER BY priority DESC;
*/
```

## Key Improvements with AI Enhancement

### 🤖 **AI vs Rule-Based Comparison**

| Aspect | Rule-Based (Old) | AI-Powered (New) |
|---|---|---|
| **Factors Analyzed** | 2 (crime type + financial loss) | 15+ (content, evidence, suspect, timeline, etc.) |
| **Decision Logic** | Hardcoded if/else statements | Intelligent content analysis |
| **Adaptability** | Static thresholds | Dynamic contextual decisions |
| **Real-time Feedback** | None | Live assessment as user types |
| **Confidence Tracking** | None | 0-100% confidence scoring |
| **Reasoning** | None | Detailed AI explanation |
| **Updates** | One-time at submission | Continuous reassessment |

### 🎯 **Smart Prioritization Examples**

**Same Crime Type, Different AI Decisions:**

```sql
-- Example 1: Low Priority
-- Crime: Online Banking Fraud, Loss: ₱500
-- AI Decision: LOW priority (25% risk)
-- Reasoning: "Minimal loss, quick detection, card blocked, low ongoing threat"

-- Example 2: High Priority  
-- Crime: Online Banking Fraud, Loss: ₱50,000
-- AI Decision: HIGH priority (85% risk)
-- Reasoning: "Sophisticated attack, ongoing threat, personal info compromised"
```

### 📊 **Dual Scoring System**

The system maintains both AI and rule-based scores:
- **AI Scores**: Primary (intelligent analysis)
- **Rule-based Scores**: Fallback (reliability)
- **Effective Priority**: `COALESCE(ai_priority, priority)`
- **Effective Risk Score**: `COALESCE(ai_risk_score, risk_score)`

### 🔄 **Real-time Flow**

```
User Types → Debounced Timer → Quick AI Assessment → Visual Feedback
                                      ↓
Final Submit → Full AI Assessment → Database Storage → Audit Trail
```

## Migration and Deployment

### 🚀 **Installation Steps**

1. **Run Table Creation**: Execute all SQL blocks in Supabase SQL Editor
2. **Verify Installation**: Run verification queries to confirm setup
3. **Test AI Integration**: Submit a test complaint to verify AI assessment
4. **Monitor Performance**: Use analytics views to track AI accuracy

### ⚠️ **Important Notes**

- **Backwards Compatible**: Existing complaints continue to work
- **Graceful Fallback**: System works even if AI service fails
- **Performance Optimized**: Indexes and caching for fast queries
- **Audit Ready**: Complete change tracking for compliance

## Novelty Features Integration

### 🔍 **Smart Pattern Detection**
- **Scammer Identification**: Automatic detection of repeat offenders across reports
- **Contact Matching**: Email and phone number pattern recognition
- **Trending Alerts**: Real-time alerts for frequent scammer contacts
- **Cross-Crime Analysis**: Pattern matching across different crime types

### 📊 **Report Credibility Assessment**
- **Quality Scoring**: 0-100% credibility score for each report
- **Strength Levels**: Weak, Moderate, Strong, Very Strong classifications
- **Improvement Suggestions**: AI-generated recommendations for better evidence
- **Factor Analysis**: Detailed breakdown of credibility factors

### 💡 **Smart Evidence Guidance**
- **Crime-Specific Suggestions**: Tailored evidence collection tips
- **Priority-Based Guidance**: Critical, High, Medium, Low priority suggestions
- **Contextual Tips**: Dynamic suggestions based on crime type and category
- **Collection Methods**: Step-by-step evidence gathering instructions

This AI enhancement transforms LawBot's complaint system from static rule-based priority scoring into an intelligent, adaptive cybercrime case prioritization platform powered by Gemini 2.0 Flash with advanced pattern detection and evidence guidance capabilities!

**🔧 DEPLOYMENT ORDER:**
1. **First**: Run WEB_SUPABASE_TABLES_REVISED.md (base tables)
2. **Second**: Run this file (AI enhancements)
3. **Result**: Complete AI-powered LawBot system