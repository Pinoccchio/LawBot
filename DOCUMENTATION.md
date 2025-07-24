# LawBot Documentation

## Overview

LawBot is a Flutter mobile application that serves as an AI-powered legal assistant for Philippine cybercrime law. The app provides users with the ability to report cybercrimes, consult with AI about legal matters, and track their submitted reports through the Philippine National Police (PNP) Cybercrime Units.

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

### Backend Services
- **Firebase**: User authentication (sign up, sign in, password reset)
- **Supabase**: Database operations, chat history, user profiles, notifications
- **Google Generative AI**: Legal consultation chatbot functionality

### State Management
- **Provider Pattern** with specialized providers:
  - `AuthProvider`: Authentication state management
  - `ThemeProvider`: Light/dark theme switching
  - `LanguageProvider`: Localization support
  - `NotificationProvider`: Frontend notification management

### Data Flow
1. **Authentication**: Firebase Auth → ID Token → Supabase RLS policies
2. **Report Submission**: Flutter Form → Supabase Database → Status Tracking
3. **AI Consultation**: User Query → Gemini API → Response → Chat History (Supabase)
4. **Notifications**: Frontend sample data → NotificationProvider → UI updates

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
- **History Tab**: Chat history with AI legal assistant
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