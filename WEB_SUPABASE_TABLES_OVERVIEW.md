# Web App Supabase Tables Overview

This document provides an overview of all database tables used by the LawBot web application for admin and PNP officer access.

## Setup Prerequisites

**⚠️ PREREQUISITE**: Run DOCUMENTATION.md database setup first to create the `update_updated_at_column()` function and base tables.

**⚠️ DEBUGGING**: RLS is disabled on all tables for debugging purposes. **ENABLE IN PRODUCTION!**

## Database Tables

The LawBot database consists of the following tables:

### Base Tables (from DOCUMENTATION.md)
- **user_profiles**: Regular citizens who submit cybercrime reports
- **complaints**: Cybercrime reports submitted by citizens
- **evidence_files**: Files uploaded as evidence for complaints
- **notifications**: System notifications for users

### Admin Tables (from WEB_SUPABASE_TABLES_*.md)
- **admin_profiles**: System administrators who manage the platform
- **pnp_officer_profiles**: Philippine National Police officers who investigate cases
- **case_assignments**: Tracks which officers are assigned to which cases
- **pnp_units**: Specialized cybercrime investigation units
- **pnp_unit_crime_types**: Junction table for PNP units and their crime types

## Database Schema

```
├── auth.users (Supabase built-in)
├── user_profiles (for regular citizens)
├── admin_profiles (for system administrators)
├── pnp_officer_profiles (for PNP officers)
├── pnp_units
│   └── pnp_unit_crime_types
├── complaints
│   ├── evidence_files
│   ├── status_history
│   └── case_assignments (linking cases to officers/admins)
└── notifications
```

## Table Relationships

1. **Authentication**
   - Firebase Authentication → auth.users
   - auth.users → user_profiles, admin_profiles, pnp_officer_profiles

2. **Cybercrime Reporting**
   - user_profiles → complaints (submitter)
   - complaints → evidence_files (evidence for cases)
   - complaints → pnp_units (specialized unit handling the case)

3. **Investigation Management**
   - pnp_units → pnp_officer_profiles (officers belong to units)
   - pnp_units → pnp_unit_crime_types (units handle specific crime types)
   - complaints → case_assignments (case assignments to officers)
   - pnp_officer_profiles → case_assignments (officers assigned to cases)
   - admin_profiles → case_assignments (admins assigned to cases)

## Setup Order

**⚠️ IMPORTANT - Run SQL in this exact sequence:**

1. **First: Run the main database setup from DOCUMENTATION.md**
   - Creates the required `update_updated_at_column()` function
   - Creates base tables: `user_profiles`, `complaints`, `evidence_files`, `notifications`

2. **Second: Run each table section in order**
   - Admin Profiles Table (WEB_SUPABASE_TABLES_ADMIN.md)
   - PNP Officer Profiles Table (WEB_SUPABASE_TABLES_OFFICERS.md)
   - Case Assignments Table (WEB_SUPABASE_TABLES_ASSIGNMENTS.md)
   - PNP Units Table (WEB_SUPABASE_TABLES_UNITS.md)
   - PNP Unit Crime Types Table (included in WEB_SUPABASE_TABLES_UNITS.md)
   - PNP Officer Profiles Update (included in WEB_SUPABASE_TABLES_OFFICERS.md)
   - Complaints Table Update (WEB_SUPABASE_TABLES_COMPLAINTS_UPDATE.md)

3. **Finally: Verify all tables are created in the Table Editor**
   - Check that all tables, indexes, and triggers are created
   - Note: RLS is disabled for debugging (uncomment RLS statements for production)

## Individual Table Documentation

For detailed information about each table, refer to the following files:

- **WEB_SUPABASE_TABLES_ADMIN.md**: Admin profiles table
- **WEB_SUPABASE_TABLES_OFFICERS.md**: PNP officer profiles table
- **WEB_SUPABASE_TABLES_ASSIGNMENTS.md**: Case assignments table
- **WEB_SUPABASE_TABLES_UNITS.md**: PNP units and crime types tables
- **WEB_SUPABASE_TABLES_COMPLAINTS_UPDATE.md**: Updates to the complaints table

Each file contains:
- Complete SQL schema for the table
- Detailed field descriptions
- Indexes and performance considerations
- Triggers and functions
- Relationships with other tables
- Setup instructions