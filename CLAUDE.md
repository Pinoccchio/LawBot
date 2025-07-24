# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LawBot is a Flutter mobile application that serves as a cybercrime reporting system for Philippine National Police (PNP). The app uses a hybrid architecture with Firebase for authentication and Supabase for database operations, focusing on comprehensive cybercrime report management and tracking.

### Key Features
- **Cybercrime Reporting System**: Comprehensive reporting with 10 crime categories and 60+ specific crime types
- **Report Tracking**: Real-time status updates with complaint numbers and police unit assignment
- **Evidence Upload**: Support for images, videos, and documents (max 5 files, 25MB total)
- **Police Unit Assignment**: Automatic routing to specialized PNP units based on crime type
- **Report History**: Track completed cases (resolved/dismissed) separately from active reports
- **Frontend Notifications**: Sample notification system for app updates and report status

## Development Commands

### Core Flutter Commands
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

### Platform-Specific Commands
```bash
# Android-specific build
cd android && ./gradlew assembleRelease

# Install on connected device
flutter install

# List connected devices
flutter devices
```

## Architecture Overview

### Dual Backend Strategy
The app uses a unique dual-backend approach:
- **Firebase**: Handles user authentication (sign up, sign in, password reset)
- **Supabase**: Manages all data operations (cybercrime reports, user profiles, evidence files, notifications)

Authentication flow: Firebase Auth → Get ID token → Use for Supabase RLS policies

### State Management
Uses Provider pattern with these key providers:
- `AuthProvider`: Manages authentication state
- `ThemeProvider`: Handles light/dark theme switching  
- `LanguageProvider`: Manages localization
- `NotificationProvider`: Handles frontend-only notifications with sample data

### Key Services Architecture
- `AuthService`: Firebase authentication operations
- `DatabaseService`: Supabase data operations for cybercrime report management
- `ComplaintModel`: Core data structure for cybercrime reports with comprehensive status tracking

## Configuration Requirements

### Firebase Setup
1. Ensure `google-services.json` is in `android/app/`
2. iOS configuration in `ios/Runner/GoogleService-Info.plist`
3. Firebase config generated in `lib/firebase_options.dart`

### Supabase Configuration
- Database credentials in `lib/config/supabase_config.dart`
- **WARNING**: Contains actual API keys - ensure proper environment handling in production

### API Keys and Environment
- Supabase anon key and service role key are embedded (review security)
- Evidence upload endpoints for file storage and management

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

### Tab Organization
The app has a clear, logical tab structure for cybercrime reporting:

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

### Key Architecture Principles
- **Clear separation**: Reports Tab = Active Cases, History Tab = Completed Cases
- **Status-based organization**: Reports filtered by active statuses, History by completion statuses
- **Evidence management**: Secure file upload and storage across all report-related features
- **Police unit integration**: Automatic assignment based on crime type categories