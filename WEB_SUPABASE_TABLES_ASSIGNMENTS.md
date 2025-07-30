# Case Assignments Table

This table tracks which officers and admins are assigned to specific cybercrime cases.

## Table Schema

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
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'transferred')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for performance
CREATE INDEX idx_case_assignments_complaint_id ON case_assignments(complaint_id);
CREATE INDEX idx_case_assignments_officer_id ON case_assignments(officer_id);
CREATE INDEX idx_case_assignments_status ON case_assignments(status);

-- RLS disabled for debugging purposes
-- ALTER TABLE case_assignments ENABLE ROW LEVEL SECURITY;
```

## Table Details

### Fields

- **id**: Primary key, automatically generated UUID
- **complaint_id**: Foreign key reference to the complaints table
- **officer_id**: Foreign key reference to the pnp_officer_profiles table (optional)
- **admin_id**: Foreign key reference to the admin_profiles table (optional)
- **assigned_by**: Name or identifier of the person who made the assignment
- **status**: Current status of the assignment
  - active: Assignment is currently in effect
  - completed: Assignment has been fulfilled
  - transferred: Assignment has been moved to another officer
- **notes**: Optional comments or instructions about the assignment
- **created_at**: Timestamp when the assignment was created

### Indexes

- **idx_case_assignments_complaint_id**: Optimizes lookups by complaint ID
- **idx_case_assignments_officer_id**: Optimizes lookups by officer ID
- **idx_case_assignments_status**: Optimizes filtering by assignment status

## Relationships

The case_assignments table functions as a junction table that connects:

1. **Complaints**: The cybercrime cases being investigated
2. **PNP Officer Profiles**: The officers assigned to investigate cases
3. **Admin Profiles**: The administrators who may be involved in case oversight

This design allows:
- Multiple officers to be assigned to a single case
- Tracking of case assignment history over time
- Clear delegation of responsibilities in the investigation process

## Usage Patterns

1. **Case Assignment**: When a new complaint is received, an admin assigns it to one or more officers
2. **Assignment Updates**: As the case progresses, assignments may be modified
3. **Audit Trail**: The table provides a history of who was assigned to which cases
4. **Workload Management**: Helps administrators balance case distribution among officers

## Setup Instructions

Run this SQL after setting up the admin_profiles and pnp_officer_profiles tables. This table depends on the complaints table from the main DOCUMENTATION.md setup.