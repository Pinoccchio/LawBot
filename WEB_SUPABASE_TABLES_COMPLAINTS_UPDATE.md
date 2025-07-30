# Complaints Table Update

This document describes the SQL changes needed to update the complaints table to integrate with PNP units.

## Update Complaints Table

```sql
-- Modify complaints table to reference pnp_units
-- First create a foreign key column to reference pnp_units
ALTER TABLE complaints ADD COLUMN unit_id UUID REFERENCES pnp_units(id) ON DELETE SET NULL;

-- Create an index for performance
CREATE INDEX idx_complaints_unit_id ON complaints(unit_id);

-- Create a function to update the unit's performance metrics
CREATE OR REPLACE FUNCTION update_unit_performance_stats(unit_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE pnp_units 
  SET 
    active_cases = (
      SELECT COUNT(*) 
      FROM complaints 
      WHERE unit_id = unit_id_param 
      AND status NOT IN ('Resolved', 'Dismissed')
    ),
    resolved_cases = (
      SELECT COUNT(*) 
      FROM complaints 
      WHERE unit_id = unit_id_param 
      AND status IN ('Resolved', 'Dismissed')
    ),
    success_rate = (
      SELECT CASE 
        WHEN COUNT(*) = 0 THEN 0 
        ELSE ROUND((COUNT(*) FILTER (WHERE status IN ('Resolved', 'Dismissed')) * 100.0 / COUNT(*)), 2)
      END
      FROM complaints 
      WHERE unit_id = unit_id_param
    ),
    updated_at = NOW()
  WHERE id = unit_id_param;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update unit performance metrics when complaints are modified
CREATE OR REPLACE FUNCTION trigger_update_unit_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Update stats for the assigned unit (handle both INSERT/UPDATE/DELETE)
  IF TG_OP = 'DELETE' THEN
    IF OLD.unit_id IS NOT NULL THEN
      PERFORM update_unit_performance_stats(OLD.unit_id);
    END IF;
    RETURN OLD;
  END IF;
  
  IF NEW.unit_id IS NOT NULL THEN
    PERFORM update_unit_performance_stats(NEW.unit_id);
  END IF;
  
  -- If unit assignment changed, update both old and new unit stats
  IF TG_OP = 'UPDATE' AND OLD.unit_id IS DISTINCT FROM NEW.unit_id THEN
    IF OLD.unit_id IS NOT NULL THEN
      PERFORM update_unit_performance_stats(OLD.unit_id);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger to complaints table
CREATE TRIGGER update_unit_stats_trigger
  AFTER INSERT OR UPDATE OR DELETE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_unit_stats();
```

## Changes Overview

This update modifies the existing complaints table (created in the main DOCUMENTATION.md setup) to:

1. Add a foreign key reference to the pnp_units table
2. Create functions and triggers to automatically update unit performance metrics

### New Fields

- **unit_id**: UUID reference to a specialized PNP unit handling the case

### New Indexes

- **idx_complaints_unit_id**: Optimizes lookups and filtering by unit ID

### New Functions and Triggers

- **update_unit_performance_stats**: Updates unit performance metrics based on complaint data
- **trigger_update_unit_stats**: Automatically updates unit statistics when complaints are modified

## Impact on Workflow

With this update, cybercrime complaints can now be directly assigned to specialized PNP units. This enables:

1. **Automatic Case Routing**: Cases are assigned to the appropriate unit based on crime type
2. **Unit Performance Tracking**: Each unit's case load and success rate is automatically updated
3. **Specialized Investigation**: Units with specific expertise handle matching case types
4. **Workload Distribution**: Case distribution across units can be monitored and balanced

## Relationship with Other Tables

This update creates relationships between:

- **complaints**: The cybercrime cases being investigated
- **pnp_units**: The specialized units handling different case types

## Setup Instructions

Run this SQL after creating the pnp_units table. Since the complaints table already exists (from the main DOCUMENTATION.md setup), this SQL modifies the existing table rather than creating a new one.