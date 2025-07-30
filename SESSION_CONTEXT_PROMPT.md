# LawBot Project Context & Analysis Prompt

**Use this prompt when starting a new Claude Code session to quickly understand the LawBot project structure and current state.**

---

## Initial Analysis Request

Please analyze this LawBot cybercrime reporting platform project in the following order:

### 1. Project Overview Analysis
First, read and understand the project structure:
- Read `CLAUDE.md` - Core project instructions and architecture
- Read `DOCUMENTATION.md` - Comprehensive project documentation  
- Read `DATABASE_SCHEMA_OVERVIEW.md` - Complete database schema for both platforms
- Read `WEB_SUPABASE_TABLES_REVISED.md` - Web app specific database tables

### 2. Flutter Mobile App Analysis
Analyze the Flutter mobile application structure:

```bash
# Use these commands to explore the Flutter app
cd .
ls -la
flutter --version
flutter doctor
ls lib/
```

**Key Flutter Files to Examine:**
- `pubspec.yaml` - Dependencies and project configuration
- `lib/main.dart` - App entry point and initialization
- `lib/services/` - Authentication, database, and API services
- `lib/models/` - Data models (especially complaint_model.dart)
- `lib/screens/` - UI screens and navigation
- `lib/providers/` - State management providers
- `lib/config/` - Firebase and Supabase configuration

**Analysis Focus:**
- Authentication flow (Firebase + Supabase integration)
- Cybercrime reporting workflow
- Evidence file upload system
- Notification system
- State management architecture

### 3. Next.js Web App Analysis
Analyze the Next.js web application structure:

```bash
# Use these commands to explore the web app
cd nextjs_web
ls -la
cat package.json
ls src/
```

**Key Web App Files to Examine:**
- `package.json` - Dependencies and scripts
- `src/app/` - Next.js 13+ app router structure
- `src/components/` - React components (especially admin modals)
- `src/lib/` - Services, utilities, and database connections
- `src/contexts/` - React context providers
- `tailwind.config.js` - Styling configuration

**Analysis Focus:**
- Admin dashboard functionality
- PNP officer management system
- Case assignment workflows
- Dynamic PNP units integration (recently implemented)
- Authentication with Firebase
- Database integration with Supabase

### 4. Recent Work Context
We recently completed:

✅ **Dynamic PNP Units Integration** - Replaced hardcoded PNP units in both Add Officer and Edit Officer modals with dynamic database fetching using `PNPUnitsService.getAllUnits({ status: 'active' })`

**Files Modified:**
- `nextjs_web/LawbotWeb/src/components/admin/modals/add-officer-modal.tsx`
- `nextjs_web/LawbotWeb/src/components/admin/modals/edit-officer-modal.tsx`

**What Was Implemented:**
- Dynamic unit fetching from database
- Loading states and error handling
- Real-time unit updates
- Better UX with unit details (name, code, category)

✅ **PNP Officer Portal Integration with Real Supabase Data** - Replaced mock data with actual database integration across the PNP officer portal

**Files Modified:**
- `nextjs_web/LawbotWeb/src/lib/pnp-officer-service.ts` (Created)
- `nextjs_web/LawbotWeb/src/components/pnp/views/profile-view.tsx` (Complete rewrite)
- `nextjs_web/LawbotWeb/src/components/pnp/views/pnp-dashboard-view.tsx` (Major updates)
- `nextjs_web/LawbotWeb/src/components/pnp/pnp-header.tsx` (Enhanced)
- `nextjs_web/LawbotWeb/src/components/ui/alert.tsx` (Created)

**What Was Implemented:**
- Comprehensive PNP Officer Service with CRUD operations
- Real officer profile management with unit information
- Actual case assignment integration
- Loading states and error handling throughout PNP portal
- Performance statistics from real data
- Fixed TypeScript errors in array property access

✅ **Flutter Mobile App Real Database Integration** - Comprehensive modernization of Flutter app to match web app's database integration approach

**Files Modified:**
- `lib/services/database_service.dart` (Major expansion with complaint CRUD operations)
- `lib/services/complaint_service.dart` (Created - Advanced complaint operations with validation)
- `lib/services/realtime_service.dart` (Created - Real-time Supabase subscriptions)
- `lib/providers/realtime_provider.dart` (Created - Provider for real-time state management)
- `lib/models/complaint_model.dart` (Enhanced with priority, risk_score, assignedUnit, title fields)
- `lib/screens/tabs/reports_tab.dart` (Updated to use real database queries)
- `lib/screens/tabs/history_tab.dart` (Updated to use real database queries)
- `lib/screens/complaint_form_screen.dart` (Updated to submit to real database)

**What Was Implemented:**
- Comprehensive complaint CRUD operations with automatic priority/risk calculation
- Evidence file upload integration with Supabase Storage (25MB limit, 5 files max)
- Real-time status update subscriptions using Supabase realtime channels
- Advanced complaint filtering, searching, and analytics
- Duplicate complaint detection and validation
- Officer assignment display with unit information
- Automatic complaint number generation (CYB-YYYY-XXX format)
- Enhanced complaint model aligned with web app database schema
- Real-time notifications for status changes

### 5. Current Project State
- ✅ Flutter mobile app: Comprehensive cybercrime reporting system with real database integration
- ✅ Flutter mobile app: Real-time status updates and notifications via Supabase subscriptions
- ✅ Next.js web app: Administrative dashboard with dynamic PNP units
- ✅ Next.js web app: PNP Officer portal with real Supabase data integration
- ✅ Database schema: Complete with 10 tables supporting both platforms
- ✅ Authentication: Firebase Auth + Supabase RLS integration
- ✅ File storage: Supabase storage for evidence files and profile pictures
- ✅ Cross-platform consistency: Shared data models, status workflows, and crime type categories

### 6. Architecture Understanding
After analysis, you should understand:

**Multi-Platform Architecture:**
- Flutter app: Citizen-facing cybercrime reporting
- Next.js web app: PNP administrative dashboard
- Shared Supabase database with role-based access

**Key Integrations:**
- Firebase Authentication (both platforms)
- Supabase Database (shared data)
- Google Generative AI (mobile app only)
- Philippine regions API (web app)
- PNP units management system

**Data Flow:**
1. Citizens submit reports via Flutter app → Supabase database
2. PNP officers/admins manage cases via Next.js web app
3. Status updates flow back to mobile app notifications
4. Evidence files shared between platforms

### 7. Development Commands Reference

**Flutter Mobile App:**
```bash
flutter pub get          # Install dependencies
flutter run              # Run development
flutter build apk        # Build Android
flutter analyze          # Code analysis
flutter test             # Run tests
```

**Next.js Web App:**
```bash
cd nextjs_web/LawbotWeb
npm install              # Install dependencies  
npm run dev              # Run development server
npm run build            # Build for production
npm run lint             # Lint code
npx tsc --noEmit         # TypeScript check
```

### 8. Key Technologies Stack

**Mobile App (Flutter):**
- Flutter 3.0+ with Dart
- Firebase Auth, Supabase Flutter
- Provider state management
- Google Generative AI (Gemini)
- Image picker, cached network image

**Web App (Next.js):**
- Next.js 15.4.4 with React 19.1.0
- TypeScript, Tailwind CSS
- Radix UI components
- Firebase web SDK
- Supabase JavaScript client

**Shared Backend:**
- Firebase Authentication
- Supabase PostgreSQL database
- Supabase Storage (evidence files)
- Row Level Security (RLS) policies

---

## Quick Start Analysis Commands

Run these commands immediately after reading the documentation:

```bash
# 1. Check project structure
ls -la
find . -name "*.dart" -o -name "*.tsx" -o -name "*.ts" | head -20

# 2. Examine Flutter app
cat pubspec.yaml
ls lib/
cat lib/main.dart

# 3. Examine Next.js web app  
cd nextjs_web/LawbotWeb
cat package.json
ls src/
ls src/components/admin/modals/

# 4. Check recent dynamic units implementation
cat src/lib/pnp-units-service.ts
grep -n "PNPUnitsService" src/components/admin/modals/add-officer-modal.tsx
```

---

## Expected Understanding After Analysis

After completing this analysis, you should be able to:

1. **Explain the dual-platform architecture** and how data flows between Flutter and Next.js apps
2. **Identify the 10 database tables** and their relationships across both platforms  
3. **Understand the cybercrime reporting workflow** from citizen submission to PNP investigation
4. **Navigate both codebases** and locate key files for features like authentication, reporting, admin panels
5. **Recognize the recent dynamic PNP units work** and how it improved the system
6. **Debug issues** in either platform by understanding the shared data models and services
7. **Implement new features** that maintain consistency across both applications

---

## Ready to Continue Development

Once you've completed this analysis, you'll be fully equipped to:
- Fix bugs in either Flutter or Next.js applications
- Add new features that span both platforms
- Optimize database queries and relationships
- Enhance the admin dashboard functionality
- Improve the mobile app user experience
- Integrate additional APIs or services

**Current Priority Areas:**
- ✅ Testing the dynamic PNP units integration (Complete)
- ✅ PNP Officer portal real data integration (Complete)
- ✅ Flutter mobile app real database integration (Complete)
- ✅ Real-time status updates and notifications (Complete)
- 🔄 **NEXT: Testing and refinement of cross-platform integration**
- Enhancing case assignment workflows in web admin
- Performance optimization and monitoring
- User experience improvements based on real-world testing
- Documentation and deployment preparation

Use this context to pick up development work seamlessly and maintain the high code quality and architecture standards established in this project.