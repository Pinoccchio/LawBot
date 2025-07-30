# Admin Profiles Table

This table stores information about system administrators who manage the LawBot platform.

## Table Schema

```sql
-- Drop existing table
DROP TABLE IF EXISTS admin_profiles CASCADE;

-- Create admin_profiles table for system administrators
CREATE TABLE IF NOT EXISTS admin_profiles (
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

-- Create indexes for performance
CREATE INDEX idx_admin_profiles_firebase_uid ON admin_profiles(firebase_uid);
CREATE INDEX idx_admin_profiles_email ON admin_profiles(email);
CREATE INDEX idx_admin_profiles_status ON admin_profiles(status);

-- Apply updated_at trigger
CREATE TRIGGER update_admin_profiles_updated_at
  BEFORE UPDATE ON admin_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS disabled for debugging purposes
-- ALTER TABLE admin_profiles ENABLE ROW LEVEL SECURITY;
```

## Table Details

### Fields

- **id**: Primary key, automatically generated UUID
- **firebase_uid**: Unique identifier from Firebase Authentication
- **email**: Admin's email address (unique)
- **full_name**: Admin's full name
- **phone_number**: Optional contact number
- **role**: Admin permission level
  - SYSTEM_ADMIN: Standard administrator with system management capabilities
  - SUPER_ADMIN: Advanced administrator with elevated permissions
  - SUPPORT_ADMIN: Limited administrator for support functions
- **status**: Account status
  - active: Account is currently in use
  - suspended: Account temporarily disabled
  - inactive: Account permanently disabled
- **created_at**: Timestamp when the record was created
- **updated_at**: Timestamp when the record was last updated

### Indexes

- **idx_admin_profiles_firebase_uid**: Optimizes lookups by Firebase UID
- **idx_admin_profiles_email**: Optimizes lookups by email address
- **idx_admin_profiles_status**: Optimizes filtering by account status

### Triggers

- **update_admin_profiles_updated_at**: Automatically updates the updated_at timestamp when a record is modified

## Related Tables

- **pnp_units**: Admin profiles create and manage PNP units
- **case_assignments**: Admin profiles can assign cases to officers

## Setup Instructions

Run this SQL after setting up the base tables from DOCUMENTATION.md, which creates the required `update_updated_at_column()` function.