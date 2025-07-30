# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LawBot is a comprehensive cybercrime reporting and investigation platform consisting of:
1. **Flutter Mobile App** - Public-facing cybercrime reporting system for Philippine National Police (PNP)
2. **Next.js Web Application** - Administrative and investigative dashboard for PNP officers and system administrators

Both applications use a hybrid architecture with Firebase for authentication and Supabase for database operations, focusing on comprehensive cybercrime report management, tracking, and investigation.

### Mobile App Key Features
- **Cybercrime Reporting System**: Comprehensive reporting with 10 crime categories and 60+ specific crime types
- **Report Tracking**: Real-time status updates with complaint numbers and police unit assignment
- **Evidence Upload**: Support for images, videos, and documents (max 5 files, 25MB total)
- **Police Unit Assignment**: Automatic routing to specialized PNP units based on crime type
- **Report History**: Track completed cases (resolved/dismissed) separately from active reports
- **Frontend Notifications**: Sample notification system for app updates and report status

### Web App Key Features
- **Dual-Role Interface**: Separate dashboards for System Administrators and PNP Officers
- **AI-Powered Case Management**: Automatic case prioritization and routing using Gemini AI analysis
- **Evidence Management**: Secure viewing and handling of evidence files with chain of custody
- **Real-time Case Tracking**: 5-status workflow (Pending → Under Investigation → Requires More Info → Resolved/Dismissed)
- **Advanced Analytics**: Performance metrics, case statistics, and priority-based dashboards
- **Dark/Light Theme Support**: Full theme switching capability throughout both applications

## Development Commands

### Flutter Mobile App Commands
```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Build for Android
flutter build apk

# Build for iOS  
flutter build ios

# Run tests
flutter test

# Analyze code for issues
flutter analyze

# Generate app icons
flutter pub run flutter_launcher_icons

# Clean build artifacts
flutter clean
```

### Next.js Web App Commands
```bash
# Navigate to web app directory
cd web_app/lawbot-web

# Install dependencies
npm install

# Run development server with Turbopack
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Lint code
npm run lint

# Check TypeScript types
npx tsc --noEmit
```

### Platform-Specific Commands
```bash
# Android-specific build (mobile app)
cd android && ./gradlew assembleRelease

# Install on connected device (mobile app)
flutter install

# List connected devices (mobile app)
flutter devices
```

## Architecture Overview

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

### Shared Backend Strategy
Both applications use the same dual-backend approach:
- **Firebase**: Handles user authentication (sign up, sign in, password reset)
- **Supabase**: Manages all data operations (cybercrime reports, user profiles, evidence files, notifications)

Authentication flow: Firebase Auth → Get ID token → Use for Supabase RLS policies

### Mobile App State Management
Uses Provider pattern with these key providers:
- `AuthProvider`: Manages authentication state
- `ThemeProvider`: Handles light/dark theme switching  
- `LanguageProvider`: Manages localization
- `NotificationProvider`: Handles frontend-only notifications with sample data

### Web App State Management
- **React Hooks**: `useState` for UI state and view switching
- **Theme Management**: Root-level theme state passed down to components
- **Role-Based Views**: Separate component trees for Admin and PNP interfaces
- **No External Libraries**: Uses React's built-in state management

### Key Services Architecture
- `AuthService`: Firebase authentication operations (mobile app)
- `DatabaseService`: Supabase data operations for cybercrime report management (mobile app)
- `ComplaintModel`: Core data structure for cybercrime reports with comprehensive status tracking (mobile app)
- Mock Data System: Web app uses `mock-data.ts` for development and demonstration

## Configuration Requirements

### Firebase Setup (Mobile App)
1. Ensure `google-services.json` is in `android/app/`
2. iOS configuration in `ios/Runner/GoogleService-Info.plist`
3. Firebase config generated in `lib/firebase_options.dart`

### Supabase Configuration (Both Apps)
- **Mobile App**: Database credentials in `lib/config/supabase_config.dart`
- **Web App**: Currently uses mock data, but can be configured to use same Supabase instance
- **WARNING**: Contains actual API keys - ensure proper environment handling in production

### API Keys and Environment
- Supabase anon key and service role key are embedded (review security)
- Evidence upload endpoints for file storage and management
- Web app requires no external API configuration (uses mock data)

### Development Environment Setup
#### Mobile App
- Flutter SDK 3.0.0 or higher
- Android Studio / Xcode for platform-specific builds
- Firebase project with authentication enabled
- Supabase project with database and storage

#### Web App
- Node.js 18+ 
- npm or yarn package manager
- No external API dependencies (mock data driven)

## Database Schema Patterns

The app follows specific patterns for data integrity:
- **Report Status Management**: Clear separation between active (Pending, Under Investigation, Requires More Info) and completed (Resolved, Dismissed) reports
- **Evidence File Handling**: Secure upload and storage of evidence files with size and format validation
- **Timezone Handling**: All operations use Philippine time with UTC storage
- **Notification System**: Frontend-only sample notifications for development/demo purposes

## Key Development Patterns

### Error Handling
- Services use try-catch with specific error messages
- Database operations include RPC function calls with direct query fallbacks
- Authentication errors are mapped to user-friendly messages

### Data Consistency
- Cybercrime reports include comprehensive status history tracking
- User profiles track last activity timestamps
- Police unit assignments are automatically determined based on crime type

### Image Handling
- Profile pictures uploaded to Supabase storage
- Automatic cleanup of old profile images
- Binary upload method for file handling

## Testing and Quality

### Linting Configuration
The project uses strict linting rules defined in `analysis_options.yaml`:
- Enforces explicit return types
- Prevents implicit casts and dynamics
- Requires const constructors where possible
- Comprehensive code quality rules

### Common Development Tasks
- When working with crime types, ensure they match the enum values in `lib/models/complaint_model.dart`
- Always test both Firebase and Supabase connections
- Verify timezone handling for Philippine users
- Notifications are frontend-only with sample data - no database integration needed
- Test cybercrime report form validation and evidence file upload limits
- Maintain clear separation: Reports Tab shows active cases, History Tab shows completed cases
- Ensure police unit assignments match the crime type categories as defined in the complaint model

## Security Considerations
- Row Level Security (RLS) policies in Supabase control data access
- Firebase ID tokens authenticate Supabase requests  
- Profile picture uploads require proper authentication
- Service role keys should not be exposed in client code

## Performance Notes
- Report queries use efficient status-based filtering for active vs completed cases
- Database queries include proper filtering to avoid placeholder data
- Image caching implemented for profile pictures and evidence files
- Evidence file uploads include compression and validation for optimal performance

## Cybercrime Reporting System

### Crime Type Categories
The app includes 10 major cybercrime categories with 60+ specific crime types:
- 📱 **Communication & Social Media Crimes** → Cyber Crime Investigation Cell
- 💰 **Financial & Economic Crimes** → Economic Offenses Wing
- 🔒 **Data & Privacy Crimes** → Cyber Security Division
- 💻 **Malware & System Attacks** → Cyber Crime Technical Unit
- 👥 **Harassment & Exploitation** → Cyber Crime Against Women and Children
- 🚫 **Content-Related Crimes** → Special Investigation Team
- ⚡ **System Disruption & Sabotage** → Critical Infrastructure Protection Unit
- 🏛️ **Government & Terrorism** → National Security Cyber Division
- 🔍 **Technical Exploitation** → Advanced Cyber Forensics Unit
- 🎯 **Targeted Attacks** → Special Cyber Operations Unit

### Report Processing
- Automatic police unit assignment based on crime type
- Complaint number generation (format: CYB-YYYY-XXX) 
- Status tracking: Pending → Under Investigation → Resolved/Dismissed
- Evidence file validation (5 files max, 25MB total limit)
- Optional contact information for follow-up

### Frontend-Only Features
- **Notifications**: Sample notification data for development/demo
- **Report Status**: Mock status updates for UI testing
- **Sample Complaints**: Predefined complaint data in reports tab for development
- **Sample History**: Predefined completed report data in history tab for development

## Tab Structure

### Mobile App Tab Organization
The mobile app has a clear, logical tab structure for cybercrime reporting:

1. **Reports Tab** - Active cybercrime reports and complaints
   - Shows current/active cases (Pending, Under Investigation, Requires More Info)
   - "History" button navigates to completed reports
   - Sample data: Current complaint submissions
   - Focus: Active case management and new report submission

2. **Resources Tab** - Legal resources and educational materials  
   - Philippine cybercrime laws and regulations
   - Government agency contacts and procedures
   - Educational content for legal awareness
   - Focus: Static reference materials

3. **History Tab** - Completed Cybercrime Reports
   - Shows completed cases (Resolved, Dismissed)
   - Filter by completion status
   - Detailed view of resolved/dismissed reports
   - Focus: Case closure archive and outcomes

4. **Notifications Tab** - System notifications and updates
   - Frontend-only sample notifications
   - Report status updates and security alerts
   - System announcements and legal updates
   - Focus: User communication

5. **Profile Tab** - User account and personal data
   - User profile management and avatar upload
   - Personal information and settings
   - Account security features
   - Focus: Personal account management

6. **Settings Tab** - App preferences and configuration
   - Theme switching and language preferences
   - Notification settings and app configuration
   - Support and contact information
   - Focus: App customization

### Web App Interface Organization

#### Admin Dashboard Views
1. **Dashboard** - System overview and metrics
2. **Case Management** - All cybercrime reports and investigations
3. **User Management** - User accounts and permissions
4. **PNP Units** - Police unit management and assignments
5. **System Settings** - Application configuration
6. **Notifications** - System-wide notifications and alerts

#### PNP Officer Dashboard Views
1. **Dashboard** - Officer's case overview and workload
2. **My Cases** - Assigned cases and investigations
3. **Case Search** - Search and filter all cases
4. **Evidence Viewer** - Evidence files and chain of custody
5. **Profile** - Officer profile and preferences

### Key Architecture Principles
- **Clear separation**: Reports Tab = Active Cases, History Tab = Completed Cases
- **Status-based organization**: Reports filtered by active statuses, History by completion statuses
- **Role-based access**: Web app separates Admin and PNP officer functionality
- **Evidence management**: Secure file upload and storage across all report-related features
- **Police unit integration**: Automatic assignment based on crime type categories
- **Cross-platform consistency**: Shared data models and status workflows

## Additional Dependencies and Services

### Mobile App Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.1.1           # State management
  firebase_core: ^3.13.1     # Firebase initialization
  firebase_auth: ^5.5.4      # Authentication
  supabase_flutter: ^2.9.0   # Database operations
  cached_network_image: ^3.4.1 # Image caching
  image_picker: ^1.1.2       # Camera/gallery access
  url_launcher: ^6.2.4       # External URL handling
  intl: ^0.20.2             # Internationalization
  google_generative_ai: ^0.4.7 # Gemini AI integration
  uuid: ^4.1.0              # Unique ID generation
  share_plus: ^11.0.0       # Content sharing
  timeago: ^3.7.1           # Relative time formatting
```

### Web App Dependencies (package.json)
```json
dependencies:
  "next": "15.4.4",
  "react": "19.1.0", 
  "react-dom": "19.1.0",
  "@radix-ui/react-*": "Various", // UI component primitives
  "@supabase/supabase-js": "^2.52.1", // Supabase client
  "firebase": "^11.2.0",           // Firebase integration
  "lucide-react": "^0.525.0",     // Icon library
  "tailwindcss": "^3.4.1",        // Utility-first CSS
  "typescript": "^5",              // Type safety
  "clsx": "^2.1.1",              // Conditional classnames
  "date-fns": "^4.1.0",          // Date utilities
  "class-variance-authority": "^0.7.1", // Component variant management
  "react-day-picker": "^9.8.0",  // Date picker component
  "tailwind-merge": "^3.3.1",    // Tailwind class merging
  "tailwindcss-animate": "^1.0.7" // Tailwind animations
}
```

### Technology Stack Summary
#### Mobile App (Flutter)
- **Framework**: Flutter 3.0+ with Dart
- **Authentication**: Firebase Auth 
- **Database**: Supabase with Row Level Security
- **State Management**: Provider pattern
- **AI Integration**: Google Generative AI (Gemini)
- **Storage**: Supabase Storage for evidence files
- **Notifications**: Custom notification provider (frontend-only)

#### Web App (Next.js)
- **Framework**: Next.js 15.4.4 with React 19.1.0
- **Language**: TypeScript with strict mode
- **Styling**: Tailwind CSS with custom design system and animations
- **UI Components**: Custom components built on Radix UI primitives
- **State Management**: React hooks (useState, useEffect)
- **Development**: Turbopack for fast development builds
- **Data**: Mock data system for development/demo (ready for Supabase integration)
- **Authentication**: Firebase integration prepared
- **Backend Integration**: Supabase client configured

## Integration Between Mobile and Web Apps

### Shared Data Models
Both applications use compatible data structures:
- **Complaint/Case ID Format**: CYB-YYYY-XXX (e.g., CYB-2025-001)
- **Status Workflow**: Pending → Under Investigation → Requires More Info → Resolved/Dismissed
- **Crime Type Categories**: 10 categories with 60+ specific crime types
- **Evidence File Structure**: Compatible file handling and metadata
- **Police Unit Assignments**: Shared unit names and specializations

### Role Separation
- **Mobile App**: Public-facing for citizens to submit cybercrime reports
- **Web App**: Internal PNP use for case management and investigation
- **User Types**: Citizens (mobile) vs. PNP Officers/Admins (web)
- **Access Levels**: Report submission (mobile) vs. Investigation tools (web)

### Development Workflow Recommendations
1. **Mobile-First Development**: Start with Flutter app for core functionality
2. **Web Dashboard Second**: Build web app for administrative features
3. **Shared Database Schema**: Ensure both apps use same Supabase structure
4. **Mock Data Alignment**: Keep web app mock data aligned with mobile app data models
5. **Cross-Platform Testing**: Test report submission flow from mobile to web investigation

## Database Schema and Web App Integration

### Supabase Tables for Web App
The WEB_SUPABASE_TABLES.md contains additional tables specifically for web app functionality:

#### Admin Profiles Table
- **Purpose**: System administrators with role-based permissions
- **Fields**: firebase_uid, email, full_name, role, permissions, department, employee_id
- **Roles**: SYSTEM_ADMIN, SUPER_ADMIN, SUPPORT_ADMIN
- **Integration**: Links with Firebase Auth for web admin access

#### PNP Officer Profiles Table
- **Purpose**: Philippine National Police officers using the web dashboard
- **Fields**: firebase_uid, email, full_name, badge_number, rank, unit, region, specialization
- **Units**: All 10 specialized cybercrime units (Cyber Crime Investigation Cell, Economic Offenses Wing, etc.)
- **Ranks**: Complete PNP hierarchy from Police Officer I to Police Colonel
- **Regions**: All 16 Philippines regions + BARMM

#### Case Assignments Table
- **Purpose**: Links complaints to officers and admins with assignment tracking
- **Fields**: complaint_id, officer_id, admin_id, assignment_type, status, notes
- **Assignment Types**: primary, secondary, consultant, reviewer
- **Integration**: Connects existing complaints table with new officer profiles

### Web App Database Integration Strategy
1. **Existing Tables**: Continue using user_profiles, complaints, evidence_files, notifications from mobile app
2. **New Tables**: Add admin_profiles, pnp_officer_profiles, case_assignments for web functionality
3. **Shared Data**: Same complaint format (CYB-YYYY-XXX), status workflow, crime types
4. **Role Separation**: Citizens (user_profiles) vs Officers (pnp_officer_profiles) vs Admins (admin_profiles)
5. **Case Management**: case_assignments table enables proper workflow and responsibility tracking