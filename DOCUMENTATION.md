# LawBot Platform Documentation

## Overview

LawBot is a comprehensive cybercrime reporting and investigation platform consisting of:
1. **Flutter Mobile Application** - Public-facing cybercrime reporting system for Philippine citizens
2. **Next.js Web Application** - Administrative and investigative dashboard for PNP officers and system administrators

Both applications serve as an AI-powered legal assistance platform for Philippine cybercrime law, providing users with the ability to report cybercrimes, consult with AI about legal matters, and track submitted reports through the Philippine National Police (PNP) Cybercrime Units.

## Core Features

### 1. Cybercrime Reporting System
Users can submit detailed cybercrime reports through a comprehensive form that includes:
- **Crime Type Selection**: Choose from 10 major categories with specific crime types
- **Incident Description**: Detailed narrative of the cybercrime incident
- **Digital Evidence Upload**: Support for images, videos, and documents (max 5 files, 25MB total)
- **Contact Information**: Optional contact details for follow-up

### 2. AI Legal Consultation
- Powered by Google's Generative AI (Gemini)
- Specialized in Philippine cybercrime laws
- Real-time chat interface for legal guidance
- Session-based conversation history

### 3. Report Tracking
- Real-time status updates on submitted reports
- Complaint number assignment (e.g., CYB-2024-001)
- Status categories: Pending, Under Investigation, Resolved, Dismissed, Requires More Info

### 4. Notification System
- Frontend-based notifications for report updates
- Security alerts and system announcements
- Case resolution notifications

## Cybercrime Categories & Police Unit Assignments

The application categorizes cybercrimes into 10 major types, each assigned to specialized police units for optimal handling:

### **📱 COMMUNICATION & SOCIAL MEDIA CRIMES**
**Assigned Unit:** *Cyber Crime Investigation Cell*
- Phishing
- Social Engineering
- Spam Messages
- Fake Social Media Profiles
- Online Impersonation
- Business Email Compromise
- SMS Fraud

### **💰 FINANCIAL & ECONOMIC CRIMES**
**Assigned Unit:** *Economic Offenses Wing*
- Online Banking Fraud
- Credit Card Fraud
- Investment Scams
- Cryptocurrency Fraud
- Online Shopping Scams
- Payment Gateway Fraud
- Insurance Fraud
- Tax Fraud
- Money Laundering

### **🔒 DATA & PRIVACY CRIMES**
**Assigned Unit:** *Cyber Security Division*
- Identity Theft
- Data Breach
- Unauthorized System Access
- Corporate Espionage
- Government Data Theft
- Medical Records Theft
- Personal Information Theft
- Account Takeover

### **💻 MALWARE & SYSTEM ATTACKS**
**Assigned Unit:** *Cyber Crime Technical Unit*
- Ransomware
- Virus Attacks
- Trojan Horses
- Spyware
- Adware
- Worms
- Keyloggers
- Rootkits
- Cryptojacking
- Botnet Attacks

### **👥 HARASSMENT & EXPLOITATION**
**Assigned Unit:** *Cyber Crime Against Women and Children*
- Cyberstalking
- Online Harassment
- Cyberbullying
- Revenge Porn
- Sextortion
- Online Predatory Behavior
- Doxxing
- Hate Speech

### **🚫 CONTENT-RELATED CRIMES**
**Assigned Unit:** *Special Investigation Team*
- Child Sexual Abuse Material
- Illegal Content Distribution
- Copyright Infringement
- Software Piracy
- Illegal Online Gambling
- Online Drug Trafficking
- Illegal Weapons Sales
- Human Trafficking

### **⚡ SYSTEM DISRUPTION & SABOTAGE**
**Assigned Unit:** *Critical Infrastructure Protection Unit*
- Denial of Service Attacks
- Website Defacement
- System Sabotage
- Network Intrusion
- SQL Injection
- Cross-Site Scripting
- Man-in-the-Middle Attacks

### **🏛️ GOVERNMENT & TERRORISM**
**Assigned Unit:** *National Security Cyber Division*
- Cyberterrorism
- Cyber Warfare
- Government System Hacking
- Election Interference
- Critical Infrastructure Attacks
- Propaganda Distribution
- State-Sponsored Attacks

### **🔍 TECHNICAL EXPLOITATION**
**Assigned Unit:** *Advanced Cyber Forensics Unit*
- Zero-Day Exploits
- Vulnerability Exploitation
- Backdoor Creation
- Privilege Escalation
- Code Injection
- Buffer Overflow Attacks

### **🎯 TARGETED ATTACKS**
**Assigned Unit:** *Special Cyber Operations Unit*
- Advanced Persistent Threats
- Spear Phishing
- CEO Fraud
- Supply Chain Attacks
- Insider Threats

## Technical Architecture

### Multi-Platform Architecture
The platform consists of two interconnected applications:

#### Mobile App (Flutter)
- **Frontend**: Flutter with Provider state management
- **Navigation**: Route-based navigation with authentication guards
- **State Management**: Provider pattern for theme, language, auth, and notifications
- **Services**: Firebase Auth + Supabase database operations

#### Web App (Next.js)
- **Frontend**: React with Next.js 15.4.4 and TypeScript
- **State Management**: React hooks with local state (no external state library)
- **Architecture**: Single-page application with view switching between Admin/PNP dashboards
- **Styling**: Tailwind CSS with custom LawBot color palette and dark mode

### Shared Backend Services
Both applications use the same dual-backend approach:
- **Firebase**: User authentication (sign up, sign in, password reset)
- **Supabase**: Database operations, chat history, user profiles, notifications, case management
- **Google Generative AI**: Legal consultation chatbot functionality (mobile app)

### State Management

#### Mobile App (Flutter)
- **Provider Pattern** with specialized providers:
  - `AuthProvider`: Authentication state management
  - `ThemeProvider`: Light/dark theme switching
  - `LanguageProvider`: Localization support
  - `NotificationProvider`: Frontend notification management

#### Web App (Next.js)
- **React Hooks**: `useState` for UI state and view switching
- **Auth Context**: `AuthContext` for authentication state management
- **Theme Management**: Root-level theme state with dark mode support
- **Role-Based Views**: Separate component trees for Admin and PNP interfaces

### Data Flow
1. **Authentication**: Firebase Auth → ID Token → Supabase RLS policies (both apps)
2. **Report Submission**: Flutter Form → Supabase Database → Status Tracking → Web Dashboard
3. **AI Consultation**: User Query → Gemini API → Response → Chat History (Supabase) [Mobile only]
4. **Case Management**: Web Dashboard → Supabase Database → Mobile Status Updates
5. **Notifications**: Database-driven notifications for both platforms

## Report Submission Process

### Step 1: Crime Type Selection
Users select from the comprehensive list of cybercrime types, which automatically assigns the appropriate police unit for investigation.

### Step 2: Incident Description
Detailed narrative describing:
- What happened
- When it occurred
- How it affected the user
- Any relevant context or background

### Step 3: Evidence Upload
Support for multiple file types:
- **Images**: Screenshots, photos of evidence
- **Videos**: Screen recordings, surveillance footage
- **Documents**: PDFs, text files, email printouts

### Step 4: Contact Information (Optional)
- Full name
- Email address
- Philippine phone number

### Step 5: Submission & Tracking
- Automatic complaint number generation
- Initial status: "Pending"
- Real-time status updates through the app

## Complete Status Workflow & Reference

### **Status Definitions**

#### 🟡 **PENDING**
- **Display Name**: "Pending"
- **Description**: "Your complaint has been received and is being reviewed"
- **What it means**: Report has been successfully submitted and is in the initial review queue
- **Typical duration**: 1-3 business days
- **Next steps**: Automatic assignment to appropriate PNP unit based on crime type
- **User action**: Wait for assignment; no action needed

#### 🔵 **UNDER INVESTIGATION** 
- **Display Name**: "Under Investigation"
- **Description**: "PNP officers are actively investigating your complaint"
- **What it means**: Case has been assigned to specialized officers and investigation is ongoing
- **Typical duration**: 2-8 weeks (varies by complexity)
- **Activities**: Evidence analysis, witness interviews, suspect identification, digital forensics
- **User action**: Remain available for follow-up questions; monitor notifications

#### 🟠 **REQUIRES MORE INFORMATION**
- **Display Name**: "Requires More Information" 
- **Description**: "Additional information is needed to proceed"
- **What it means**: Investigators need more details, evidence, or clarification to continue
- **Typical duration**: Investigation paused until information is provided
- **Common requests**: Additional screenshots, transaction details, timeline clarification, witness information
- **User action**: **URGENT** - Provide requested information within 7-14 days to avoid case closure

#### 🟢 **RESOLVED**
- **Display Name**: "Resolved"
- **Description**: "Your complaint has been resolved"
- **What it means**: Investigation completed with successful outcome
- **Possible outcomes**: 
  - Suspect arrested and charged
  - Funds recovered through mediation
  - Fake accounts/content removed
  - Legal action taken against perpetrator
- **User action**: Case closed; follow-up available if needed

#### 🔴 **DISMISSED**
- **Display Name**: "Dismissed"
- **Description**: "Your complaint has been dismissed"
- **What it means**: Case closed without criminal prosecution
- **Common reasons**:
  - Insufficient evidence for criminal charges
  - Matter falls under civil jurisdiction
  - Duplicate report or resolved through other means
  - Lack of legal basis for prosecution
- **User action**: May pursue civil remedies if advised; case cannot be reopened

## Advanced User Experience Features

### **User Novelty 1: Smart Evidence Guidance**

**Purpose**: AI-powered evidence recommendations based on selected crime type

**How it works**: 
- When users select a specific cybercrime type during report submission
- The system provides intelligent suggestions on what evidence to collect and upload
- Recommendations are tailored to maximize case success and investigation efficiency

**Examples by Crime Type**:

- **Online Shopping Scams**: 
  - "📸 Screenshots of product listings and seller profiles"
  - "💳 Payment confirmation receipts (bank transfer, credit card, e-wallet)"
  - "💬 Chat conversations with the seller"
  - "🔗 Links to scammer's social media or marketplace profiles"

- **Phishing Attacks**:
  - "📧 Full email headers showing sender information"
  - "🖼️ Screenshots of suspicious emails or websites"
  - "📱 SMS screenshots if received via text"
  - "🔗 URLs of fake websites (do not click, just copy link)"

- **Identity Theft**:
  - "🆔 Copy of your valid government-issued ID"
  - "📄 Unauthorized account statements or credit reports"
  - "📧 Notifications from institutions about unknown accounts"
  - "📸 Screenshots of fake profiles using your information"

**Implementation**: Integrated into the complaint form screen with dynamic recommendations

---

### **User Novelty 2: Report Credibility Meter**

**Purpose**: Real-time assessment of report completeness and strength

**How it works**:
- AI analyzes submitted information and evidence quality
- Provides percentage-based credibility score (0-100%)
- Offers specific suggestions to improve report strength
- Updates in real-time as users add more information

**Credibility Factors**:
- **Evidence Quality** (40%): Clear screenshots, complete documents, relevant files
- **Description Detail** (25%): Comprehensive incident narrative, timeline accuracy
- **Contact Information** (15%): Verified contact details for follow-up
- **Supporting Documentation** (20%): Additional evidence like transaction records

**Example Feedback**:
- **85% Complete**: "✅ Strong report! Consider adding: screenshot of payment confirmation to reach 95%"
- **65% Complete**: "⚠️ Good start! To strengthen your report, add: conversation screenshots and seller's profile link"
- **40% Complete**: "❌ Needs improvement! Missing: evidence files, detailed timeline, and contact information"

**Benefits**:
- Higher credibility scores = Faster case processing
- Users understand what makes a strong report
- Reduced need for "Requires More Information" status

---

### **User Novelty 3: Report Pattern Alerts**

**Purpose**: Community-driven scam detection and prevention

**How it works**:
- System analyzes incoming reports for common patterns
- Detects duplicate scammers, phone numbers, email addresses, URLs, social media accounts
- Shows real-time alerts when users report known threats
- Prevents others from falling victim to the same schemes

**Pattern Detection**:
- **Phone Numbers**: "📞 This number (+63 XXX XXXX) has been reported 15 times this week"
- **Email Addresses**: "📧 This email (scammer@fake.com) is linked to 8 other fraud reports"
- **Social Media Accounts**: "👤 This Facebook profile was reported by 12 users in the last 24 hours"
- **Websites/URLs**: "🔗 This website has been flagged in 25 phishing reports this month"
- **Bank Account Numbers**: "🏦 This account number appears in 6 other money transfer scams"

**Alert Examples**:
- **High Priority**: "⚠️ DANGER: This scammer is currently active! 47 reports in the last 7 days"
- **Medium Priority**: "⚠️ WARNING: This entity was reported 8 times this month"
- **Low Priority**: "ℹ️ INFO: This matches 2 previous reports from last quarter"

**Additional Features**:
- **Trending Scams Dashboard**: Shows most reported scams this week/month
- **Geographic Alerts**: "5 similar reports from your area (Metro Manila) this week"
- **Seasonal Warnings**: Holiday-specific scam patterns and alerts

**Privacy Protection**:
- No personal information shared between reports
- Only scammer identifiers are compared
- Full anonymization of victim data

## Security Features

### Data Protection
- Row Level Security (RLS) policies in Supabase
- Firebase ID token authentication
- Encrypted file uploads for evidence
- Secure communication channels

### Privacy Considerations
- Optional contact information
- Anonymous reporting supported
- Secure evidence handling protocols
- GDPR-compliant data handling

## User Interface

### Navigation Structure
- **Reports Tab**: View and manage submitted reports
- **Resources Tab**: Legal resources and educational content
- **History Tab**: Completed cybercrime cases (resolved/dismissed status)
- **Notifications Tab**: System notifications and updates
- **Profile Tab**: User account management
- **Settings Tab**: App preferences and configurations

### Theme Support
- Light and dark mode themes
- System theme integration
- Consistent color scheme across all screens

### Localization
- Multi-language support framework
- Philippine context-aware content
- Cultural sensitivity in UI design

## Best Practices for Users

### Effective Reporting
1. **Be Specific**: Provide detailed descriptions of incidents
2. **Include Evidence**: Upload relevant screenshots, documents, or recordings
3. **Accurate Information**: Ensure all details are correct before submission
4. **Follow Up**: Monitor report status and respond to requests for additional information

### Digital Evidence Guidelines
- **Screenshots**: Capture full screens showing URLs, timestamps, and content
- **Communications**: Save email headers, chat logs, and social media interactions
- **Financial Records**: Include transaction details, bank statements, and receipts
- **Documentation**: Preserve all relevant documents in their original format

### Privacy Protection
- Review information before sharing
- Use the anonymous reporting option when needed
- Keep personal contact information secure
- Report any suspicious activity immediately

## Integration with PNP Cybercrime Units

The application facilitates seamless communication between citizens and law enforcement by:

1. **Automated Routing**: Reports are categorized and routed to the appropriate specialized unit
2. **Standardized Reporting**: Consistent format for all cybercrime reports
3. **Evidence Management**: Secure handling and preservation of digital evidence
4. **Status Communication**: Real-time updates on investigation progress
5. **Case Tracking**: Comprehensive tracking from submission to resolution

This structure ensures that each cybercrime type is handled by the most appropriate specialized police unit, maximizing the effectiveness of investigations and improving outcomes for victims.

---

## Supabase Database Setup

### SQL Editor Scripts for Database Setup

Use the following SQL scripts in the Supabase SQL Editor to set up the database schema:

#### 1. User Profiles Table
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

-- RLS disabled for debugging purposes
-- ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
```

#### 2. Complaints Table
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

-- RLS disabled for debugging purposes
-- ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
```

#### 3. Evidence Files Table
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

-- RLS disabled for debugging purposes
-- ALTER TABLE evidence_files ENABLE ROW LEVEL SECURITY;
```

#### 4. Status History Table
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

-- RLS disabled for debugging purposes
-- ALTER TABLE status_history ENABLE ROW LEVEL SECURITY;
```

#### 5. Notifications Table
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

-- RLS disabled for debugging purposes
-- ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
```

#### 6. Functions and Triggers

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

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_complaints_updated_at
  BEFORE UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

```

#### 7. Storage Buckets Setup

**Note**: Storage buckets must be created through the Supabase Dashboard UI, not SQL.

**Step 1: Create Buckets via Dashboard**
1. Go to Supabase Dashboard → Storage
2. Click "New Bucket"
3. Create bucket: `evidence-files` (Private)
4. Create bucket: `profile-pictures` (Private)

**Step 2: Add Storage Policies via SQL**
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


CREATE TABLE IF NOT EXISTS admin_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone_number TEXT,
  role TEXT DEFAULT 'SYSTEM_ADMIN' CHECK (role IN ('SYSTEM_ADMIN', 'SUPER_ADMIN', 'SUPPORT_ADMIN')),
  permissions TEXT[] DEFAULT ARRAY['READ', 'write', 'delete', 'admin'],
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'inactive')),
  department TEXT DEFAULT 'IT Administration',
  employee_id TEXT,
  hire_date DATE,
  last_login TIMESTAMP WITH TIME ZONE,
  login_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  created_by TEXT,
  updated_by TEXT
);

-- Create indexes for performance
CREATE INDEX idx_admin_profiles_firebase_uid ON admin_profiles(firebase_uid);
CREATE INDEX idx_admin_profiles_email ON admin_profiles(email);
CREATE INDEX idx_admin_profiles_status ON admin_profiles(status);

-- RLS disabled for debugging purposes
-- ALTER TABLE admin_profiles ENABLE ROW LEVEL SECURITY;
```

#### 9. PNP Officer Profiles Table (for Police Access)
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
    'National Capital Region (NCR)', 'Region I - Ilocos Region', 'Region II - Cagayan Valley',
    'Region III - Central Luzon', 'Region IV-A - CALABARZON', 'Region IV-B - MIMAROPA',
    'Region V - Bicol Region', 'Region VI - Western Visayas', 'Region VII - Central Visayas',
    'Region VIII - Eastern Visayas', 'Region IX - Zamboanga Peninsula', 'Region X - Northern Mindanao',
    'Region XI - Davao Region', 'Region XII - SOCCSKSARGEN', 'Region XIII - Caraga',
    'BARMM - Bangsamoro Autonomous Region'
  )),
  specialization TEXT,
  years_of_service INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'on_leave', 'suspended', 'retired')),
  security_clearance TEXT DEFAULT 'standard' CHECK (security_clearance IN ('standard', 'elevated', 'high', 'top_secret')),
  assigned_cases_count INTEGER DEFAULT 0,
  last_login TIMESTAMP WITH TIME ZONE,
  login_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  created_by TEXT,
  updated_by TEXT
);

-- Create indexes for performance
CREATE INDEX idx_pnp_officer_profiles_firebase_uid ON pnp_officer_profiles(firebase_uid);
CREATE INDEX idx_pnp_officer_profiles_email ON pnp_officer_profiles(email);
CREATE INDEX idx_pnp_officer_profiles_badge_number ON pnp_officer_profiles(badge_number);
CREATE INDEX idx_pnp_officer_profiles_unit ON pnp_officer_profiles(unit);
CREATE INDEX idx_pnp_officer_profiles_region ON pnp_officer_profiles(region);
CREATE INDEX idx_pnp_officer_profiles_status ON pnp_officer_profiles(status);

-- RLS disabled for debugging purposes
-- ALTER TABLE pnp_officer_profiles ENABLE ROW LEVEL SECURITY;
```

#### 10. Case Assignments Table (linking cases to officers)
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
  assignment_type TEXT DEFAULT 'primary' CHECK (assignment_type IN ('primary', 'secondary', 'consultant', 'reviewer')),
  assignment_date TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'transferred', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_case_assignments_complaint_id ON case_assignments(complaint_id);
CREATE INDEX idx_case_assignments_officer_id ON case_assignments(officer_id);
CREATE INDEX idx_case_assignments_admin_id ON case_assignments(admin_id);
CREATE INDEX idx_case_assignments_status ON case_assignments(status);

-- RLS disabled for debugging purposes
-- ALTER TABLE case_assignments ENABLE ROW LEVEL SECURITY;
```

#### 11. Updated Triggers for New Tables
```sql
-- Apply updated_at trigger to new tables
```

### Setup Instructions

1. **Open Supabase Dashboard**
   - Go to your project dashboard at supabase.com
   - Navigate to the "SQL Editor" tab

2. **Run Scripts in Order**
   - Copy and paste each script above in the SQL Editor
   - Execute them one by one in the order shown
   - Ensure each script runs successfully before proceeding

3. **Verify Setup**
   - Go to "Table Editor" to verify all tables are created
   - Check "Storage" section to confirm buckets are set up
   - Test RLS policies by creating a test user

4. **Environment Configuration**
   - Update your `lib/config/supabase_config.dart` with your project URL and anon key
   - Ensure your API keys are properly configured

### Database Schema Overview

```
├── auth.users (Supabase built-in)
├── user_profiles
├── complaints
│   ├── evidence_files
│   └── status_history
└── notifications
```

This simplified schema supports the core LawBot functionality with debugging-friendly configuration (RLS policies disabled for easier development).

---

## CYBERCRIME REPORTING SYSTEM WORKFLOW

This section outlines the complete end-to-end workflow for the LawBot cybercrime reporting system, from initial user complaint submission to final case resolution.

### COMPLETE SYSTEM FLOW

#### **1. USER COMPLAINT SUBMISSION**
- **User Action**: User submits complaint through the mobile app with supporting evidence
- **Evidence Types**: Screenshots, PDFs, images, videos, documents (max 5 files, 25MB total)
- **Data Storage**: All complaint data and evidence files are securely saved in the Supabase database
- **Initial Status**: Case automatically assigned "Pending" status
- **Complaint Number**: System generates unique identifier (e.g., CYB-2024-001)

#### **2. AI SUMMARIZATION (Gemini API Integration)**
- **Trigger**: Optional automated step or manual admin activation
- **Process**: Gemini AI analyzes the complaint description and evidence
- **Output Generation**:
  - Clean, concise summary of the incident
  - Extracted key data points (case type, severity level)
  - Structured data for further processing
- **Storage**: AI-generated summary stored alongside original complaint

#### **3. PRESCRIPTIVE ANALYTICS TRIGGERS**
- **Data Input**: Uses either Gemini's structured data OR raw complaint data
- **Risk Assessment**: AI calculates comprehensive risk score for different threat categories:
  - Fraud Risk Score
  - Harassment Severity Level
  - Financial Impact Assessment
  - Urgency Classification
- **Auto-Prioritization**: System assigns priority level (High, Medium, Low) before admin review
- **Unit Assignment**: Automatic routing to appropriate PNP cybercrime unit based on crime type

#### **4. ADMIN DASHBOARD PRESENTATION**
**Admin Interface Displays**:
- **Priority Tag**: Visual indicator (High/Medium/Low) with color coding
- **Case Type**: Auto-tagged categories (Fraud, Harassment, Phishing, etc.)
- **AI Summary**: Condensed incident overview (if AI summarization enabled)
- **Suggested Actions**: AI-generated recommendations such as:
  - "Request additional transaction records"
  - "Escalate to Financial Crimes Unit"
  - "Contact victim for clarification"
  - "Coordinate with telecommunications provider"

#### **5. ADMIN INVESTIGATION & ACTION**
**Case Review Process**:
- **Initial Assessment**: Admin clicks case to review detailed information
- **AI Tools Available**:
  - On-demand summarization for complex cases
  - Evidence analysis recommendations
  - Pattern recognition alerts for repeat offenders

**Admin Action Options**:
- **Status Updates**: 
  - Pending → Under Investigation
  - Under Investigation → Requires More Information
  - Under Investigation → Resolved/Dismissed
- **Case Management**:
  - Add investigation notes and remarks
  - Request additional evidence from complainant
  - Assign case to specific investigating officer
- **Escalation Pathways**:
  - **Senior Admin Escalation**: For high-priority or complex cases requiring supervisory oversight
  - **Specialized Unit Transfer**: Route to appropriate PNP cybercrime department:
    - Fraud Unit (financial crimes)
    - Harassment Unit (cyberbullying, stalking)
    - Phishing/Scam Unit (social engineering attacks)
    - Technical Crimes Unit (hacking, malware)

#### **6. USER NOTIFICATION & COMMUNICATION**
**Real-Time Updates**:
- **Status Notifications**: Automatic alerts when case status changes
- **Investigation Progress**: Regular updates on case development
- **Action Requests**: Notifications when additional information is needed
- **Escalation Alerts**: "Your case has been escalated to the Financial Crimes Unit for specialized investigation"

**Communication Channels**:
- In-app notifications
- Email updates (if provided)
- SMS alerts for critical updates

#### **7. CASE RESOLUTION & FEEDBACK**
**Resolution Process**:
- **Case Closure**: Admin marks case as "Resolved" or "Dismissed"
- **Resolution Details**: 
  - Summary of actions taken
  - Outcome description
  - Legal recommendations (if applicable)
- **Documentation**: Complete case file with evidence and investigation notes

**Post-Resolution Features**:
- **User Feedback System**: Optional rating and review of investigation process
- **Case Archive**: Permanent record for future reference
- **Appeal Process**: Information on next steps if user disagrees with outcome
- **Legal Guidance**: Referrals to appropriate legal resources or agencies

### WORKFLOW BENEFITS

#### **For Users (Complainants)**:
- **Streamlined Reporting**: Simple, guided complaint submission process
- **Transparency**: Real-time visibility into case progress
- **Professional Handling**: Appropriate expertise applied to each case type
- **Comprehensive Support**: From initial report to final resolution

#### **For Administrators (PNP Officers)**:
- **Intelligent Triage**: AI-powered prioritization and categorization
- **Enhanced Efficiency**: Automated routing and suggested actions
- **Better Decision Making**: AI insights and pattern recognition
- **Streamlined Workflow**: Integrated tools for case management

#### **For the System**:
- **Quality Assurance**: Consistent handling across all case types
- **Data Analytics**: Comprehensive reporting and trend analysis
- **Resource Optimization**: Efficient allocation of investigative resources
- **Continuous Improvement**: Feedback loops for system enhancement

### TECHNICAL IMPLEMENTATION NOTES

#### **AI Integration Points**:
- **Gemini API**: Text summarization and structured data extraction
- **Pattern Recognition**: Duplicate scammer detection and trending threat analysis
- **Risk Assessment**: Multi-factor scoring algorithm for case prioritization
- **Natural Language Processing**: Automated categorization and keyword extraction

#### **Database Workflow**:
- **Complaint Storage**: Primary complaint record with evidence file references
- **Status Tracking**: Complete audit trail of all case status changes
- **User Notifications**: Automated notification generation based on status updates
- **Analytics Data**: Aggregated statistics for reporting and system optimization

This comprehensive workflow ensures that every cybercrime report receives appropriate attention, professional investigation, and transparent communication throughout the entire process.

---

## Firebase & Supabase Configuration Guide

This section outlines the Firebase Authentication and Supabase Database configuration for both the Flutter mobile app and Next.js web application.

### Configuration Overview

Both applications use the same dual-backend strategy:
- **Firebase**: User authentication (sign up, sign in, password reset)
- **Supabase**: Database operations (user profiles, complaints, notifications, case management)

### Flutter Mobile App Configuration

#### Firebase Setup (Flutter)
**File**: `lib/firebase_options.dart`
```dart
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7clmGkru3fQZAIJpfvOGlhgCkAb5VF8A',
    appId: '1:940247359181:android:e24d9f7f6b8448405e5384',
    messagingSenderId: '940247359181',
    projectId: 'lawbotfirebase',
    storageBucket: 'lawbotfirebase.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB6ndUlL8E8F1ST1QgmBtuvThO8keWph1o',
    appId: '1:940247359181:ios:af70274bc33d85585e5384',
    messagingSenderId: '940247359181',
    projectId: 'lawbotfirebase',
    storageBucket: 'lawbotfirebase.firebasestorage.app',
    iosBundleId: 'com.example.lawbot',
  );
}
```

#### Supabase Setup (Flutter)
**File**: `lib/config/supabase_config.dart`
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://knoahdsfthalbdqockmw.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtub2FoZHNmdGhhbGJkcW9ja213Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4NjEzMzQsImV4cCI6MjA2NDQzNzMzNH0.xiT1DLOJ_l2UQNwpBt7SAsXaAmc8uXVY0-3Mg_UGoOI';
  
  // Service role key - only use for secure server-side operations
  static const String serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtub2FoZHNmdGhhbGJkcW9ja213Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODg2MTMzNCwiZXhwIjoyMDY0NDM3MzM0fQ.RIJDn6ZiyZYv-M9MtKyV9zo4AwZaGdxDGDWc8yK2s9Y';
}
```

#### Flutter Dependencies
**File**: `pubspec.yaml`
```yaml
dependencies:
  firebase_core: ^3.13.1     # Firebase initialization
  firebase_auth: ^5.5.4      # Authentication
  supabase_flutter: ^2.9.0   # Database operations
  provider: ^6.1.1           # State management
  google_generative_ai: ^0.4.7 # Gemini AI integration
```

### Next.js Web App Configuration

#### Firebase Setup (Web)
**File**: `src/lib/firebase.ts`
```typescript
import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || "AIzaSyB7clmGkru3fQZAIJpfvOGlhgCkAb5VF8A",
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || "lawbotfirebase.firebaseapp.com",
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "lawbotfirebase",
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || "lawbotfirebase.firebasestorage.app",
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || "940247359181",
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || "1:940247359181:web:YOUR_WEB_APP_ID"
}

const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)
export default app
```

#### Supabase Setup (Web)
**File**: `src/lib/supabase.ts`
```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://knoahdsfthalbdqockmw.supabase.co'
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtub2FoZHNmdGhhbGJkcW9ja213Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4NjEzMzQsImV4cCI6MjA2NDQzNzMzNH0.xiT1DLOJ_l2UQNwpBt7SAsXaAmc8uXVY0-3Mg_UGoOI'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
export default supabase
```

#### Web App Dependencies
**File**: `package.json`
```json
{
  "dependencies": {
    "firebase": "^11.2.0",
    "@supabase/supabase-js": "^2.47.10",
    "next": "15.4.4",
    "react": "19.1.0",
    "typescript": "^5"
  }
}
```

#### Environment Variables (Web)
**File**: `.env.local`
```bash
# Firebase Configuration
NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSyB7clmGkru3fQZAIJpfvOGlhgCkAb5VF8A
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=lawbotfirebase.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=lawbotfirebase
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=lawbotfirebase.firebasestorage.app
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=940247359181
NEXT_PUBLIC_FIREBASE_APP_ID=1:940247359181:web:YOUR_WEB_APP_ID

# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://knoahdsfthalbdqockmw.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtub2FoZHNmdGhhbGJkcW9ja213Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4NjEzMzQsImV4cCI6MjA2NDQzNzMzNH0.xiT1DLOJ_l2UQNwpBt7SAsXaAmc8uXVY0-3Mg_UGoOI

# Supabase Service Role Key (Server-side only)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtub2FoZHNmdGhhbGJkcW9ja213Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODg2MTMzNCwiZXhwIjoyMDY0NDM3MzM0fQ.RIJDn6ZiyZYv-M9MtKyV9zo4AwZaGdxDGDWc8yK2s9Y
```

### Authentication Services

#### Flutter Auth Service
**File**: `lib/services/auth_service.dart`
- Firebase authentication operations
- User profile creation in Supabase
- Error handling with user-friendly messages
- Integration with Supabase RLS policies

#### Web Auth Service
**File**: `src/lib/auth.ts`
- Firebase authentication for web
- React context provider (`src/contexts/AuthContext.tsx`)
- Same error handling patterns as Flutter app
- Compatible user profile management

### Database Services

#### Flutter Database Service
**File**: `lib/services/database_service.dart`
- Supabase operations for mobile app
- User profile management
- Notification handling
- Evidence file uploads

#### Web Database Service
**File**: `src/lib/database.ts`
- Supabase operations for web dashboard
- Case management for PNP officers
- Admin dashboard functionality
- Complaint status updates

### Required Setup Steps

#### 1. Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select the `lawbotfirebase` project
3. **For Flutter**: Android and iOS apps are already configured
4. **For Web**: Add a new web app to the project
5. Copy the web app configuration and update `NEXT_PUBLIC_FIREBASE_APP_ID`
6. Enable Authentication methods (Email/Password)

#### 2. Supabase Configuration
- Project URL: `https://knoahdsfthalbdqockmw.supabase.co`
- Both apps use the same Supabase project
- Database schema is shared between mobile and web
- Row Level Security (RLS) policies control data access

#### 3. Development Commands

**Flutter Mobile App**:
```bash
flutter pub get                    # Install dependencies
flutter run                       # Run development
flutter build apk                 # Build Android
flutter analyze                   # Code analysis
```

**Next.js Web App**:
```bash
cd web_app/lawbot-web
npm install                       # Install dependencies
npm run dev                       # Run development server
npm run build                     # Build for production
npm run lint                      # Lint code
```

### Integration Between Mobile and Web Apps

#### Shared Data Models
- **Complaint/Case ID Format**: CYB-YYYY-XXX (e.g., CYB-2025-001)
- **Status Workflow**: Pending → Under Investigation → Requires More Info → Resolved/Dismissed
- **Crime Type Categories**: 10 categories with 60+ specific crime types
- **Evidence File Structure**: Compatible file handling and metadata
- **Police Unit Assignments**: Shared unit names and specializations

#### Role Separation
- **Mobile App**: Public-facing for citizens to submit cybercrime reports
- **Web App**: Internal PNP use for case management and investigation
- **User Types**: Citizens (mobile) vs. PNP Officers/Admins (web)
- **Access Levels**: Report submission (mobile) vs. Investigation tools (web)

#### Cross-Platform Data Flow
1. **Report Submission**: Mobile app → Supabase database
2. **Case Management**: Web dashboard displays mobile submissions
3. **Status Updates**: Web dashboard updates → Mobile app notifications
4. **Evidence Handling**: Shared file storage and access policies
5. **User Authentication**: Same Firebase project, different user roles

### Security Considerations

1. **Environment Variables**: All sensitive keys stored securely
2. **Service Role Key**: Only used on server-side (API routes, server actions)
3. **Row Level Security**: Supabase RLS policies control data access
4. **Firebase Auth**: User authentication handled by Firebase
5. **CORS**: Configure allowed domains in Firebase and Supabase
6. **API Key Security**: Separate keys for development and production

### Troubleshooting

#### Common Issues:
1. **Firebase Web App ID**: Update `NEXT_PUBLIC_FIREBASE_APP_ID` after creating web app
2. **CORS Errors**: Add domain to Firebase authorized domains
3. **Supabase RLS**: Ensure Row Level Security policies allow cross-platform access
4. **Environment Variables**: Verify all required variables are set correctly
5. **Database Permissions**: Check user roles and permissions in Supabase

#### Testing Authentication Flow:
1. Create user account in mobile app
2. Verify user appears in Firebase Auth console
3. Check user profile created in Supabase `user_profiles` table
4. Test login from web app with same credentials
5. Verify shared data access between platforms