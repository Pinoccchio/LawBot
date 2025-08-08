# LawBot - AI-Powered Cybercrime Reporting Platform

## Overview

LawBot is a comprehensive AI-powered cybercrime reporting and investigation platform designed for the Philippines. It consists of a Flutter mobile app for citizens to report cybercrimes and a Next.js web application for PNP officers and administrators to manage investigations.

## Project Components

### 1. Flutter Mobile App (✅ Fully Functional)
Public-facing cybercrime reporting system with AI-enhanced features:
- **AI-Powered Reporting**: 10 crime categories with 67+ specific crime types
- **Smart Evidence Suggestions**: AI-generated contextual recommendations
- **Report Credibility Meter**: Real-time completeness scoring
- **Pattern Detection**: Cross-report scammer identification
- **Dynamic Forms**: 32 configurable fields that adapt by crime type
- **Evidence Upload**: Support for images, videos, documents (max 5 files, 25MB)
- **Real-time Updates**: Live case status tracking

### 2. Next.js Web Application (✅ Interface Complete, 🔧 Database Integration Pending)
Administrative and investigative dashboard for law enforcement:
- **Dual-Role Interface**: Separate dashboards for Admins and PNP Officers
- **AI Case Management**: Priority-based case handling
- **Evidence Viewer**: Secure evidence management with chain of custody
- **Advanced Analytics**: Performance metrics and case statistics
- **Officer Assignment**: Workload management and case distribution

## Tech Stack

### Mobile App
- **Framework**: Flutter 3.0+ with Dart
- **Authentication**: Firebase Auth
- **Database**: Supabase (PostgreSQL)
- **AI Integration**: Google Gemini 2.0 Flash
- **State Management**: Provider pattern
- **Key Features**: AI caching system with 20-40x performance improvement

### Web App
- **Framework**: Next.js 15.4.4 with React 19.1.0
- **Language**: TypeScript
- **Styling**: Tailwind CSS with custom design system
- **UI Components**: Radix UI primitives
- **Authentication**: Firebase Auth (ready for integration)

## Quick Start

### Mobile App Setup
```bash
# Clone the repository
git clone [repository-url]
cd LawBot

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Web App Setup
```bash
# Navigate to web app
cd nextjs_web/LawbotWeb

# Install dependencies
npm install

# Run development server
npm run dev
```

## Key Documentation

- **`CLAUDE.md`** - Complete project documentation and AI integration guide
- **`CURRENT_DATABASE_SCHEMA.md`** - Database schema reference (15 tables)
- **`nextjs_web/LawbotWeb/CLAUDE.md`** - Web app specific documentation
- **`nextjs_web/LawbotWeb/ENVIRONMENT_SETUP.md`** - Web app environment configuration

## Database Setup

1. Create a Supabase project
2. Run the SQL scripts from `CURRENT_DATABASE_SCHEMA.md`
3. Configure authentication with Firebase
4. Set up Supabase Storage bucket for evidence files

## Environment Configuration

### Mobile App
- Add `google-services.json` to `android/app/`
- Configure iOS in `ios/Runner/GoogleService-Info.plist`
- Update Supabase credentials in `lib/config/supabase_config.dart`
- Add Gemini API key for AI features

### Web App
- Configure Firebase in `src/lib/firebase.ts`
- Set up Supabase client in `src/lib/supabase.ts`
- Update environment variables as per `ENVIRONMENT_SETUP.md`

## AI Features

The platform includes sophisticated AI capabilities:
- **Risk Assessment**: Automatic case prioritization (0-100 score)
- **Evidence Guidance**: Context-aware evidence suggestions
- **Pattern Detection**: Identifies potential scammers across reports
- **Credibility Scoring**: Report quality assessment
- **Smart Caching**: Reduces API costs with intelligent caching

## Development Status

### ✅ Completed
- Mobile app with all AI features
- Web app user interface
- Database schema with 15 tables
- AI integration with caching
- Authentication setup

### 🔧 In Progress
- Web app database integration
- Real-time synchronization
- Production deployment configuration

## Contributing

Please read `CLAUDE.md` for detailed development guidelines and architecture information.

## License

[License information to be added]