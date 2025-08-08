# Test Plan: Status Update Fix Verification

## Pre-Migration Testing

### 1. Current State Verification
Before applying the database migration, verify the current issue:

```bash
# Start the web app
cd nextjs_web/LawbotWeb
npm run dev
```

1. **Login as PNP Officer**
   - Navigate to http://localhost:3000
   - Click "PNP Officer Login" 
   - Use test credentials
   - Verify you can access PNP dashboard

2. **Attempt Status Update**
   - Go to "My Cases" or "Case Search"
   - Find any case with non-resolved status
   - Click "Update Status" 
   - Change status to "Under Investigation"
   - Add notes and set urgency level
   - Submit update

3. **Check Browser Console**
   - Expected error: `❌ Database error adding status history`
   - Should see foreign key constraint violation
   - `updated_by_user_id` will be null in the response

4. **Check Mobile App**
   - Open Flutter mobile app
   - Navigate to case details
   - Verify status timeline shows empty or missing officer info

## Database Migration

### Apply the Fix
```sql
-- Execute the migration script
-- Make sure you have database access
\i database_migrations/fix_status_history_foreign_key.sql
```

### Verify Migration
```sql
-- Check constraint is removed
SELECT constraint_name FROM information_schema.table_constraints 
WHERE table_name = 'status_history' 
  AND constraint_type = 'FOREIGN KEY' 
  AND constraint_name LIKE '%updated_by_user_id%';
-- Should return 0 rows

-- Check UUID format constraint is added
SELECT constraint_name FROM information_schema.table_constraints 
WHERE table_name = 'status_history' 
  AND constraint_type = 'CHECK' 
  AND constraint_name = 'chk_updated_by_user_id_format';
-- Should return 1 row
```

## Post-Migration Testing

### 1. Web App Status Update Test
```bash
# Restart web app if needed
cd nextjs_web/LawbotWeb
npm run dev
```

1. **Login as PNP Officer**
   - Same login process as before
   - Verify authentication still works

2. **Status Update Test**
   - Navigate to case management
   - Select a case to update
   - Change status (e.g., Pending → Under Investigation)
   - Add detailed notes: "Starting investigation with new evidence review"
   - Set urgency level: "high" 
   - Enable notifications
   - Submit update

3. **Verify Success in Browser Console**
   - Expected logs:
     ```
     ✅ Officer profile loaded for status history: [Officer Name]
     ✅ Firebase UID format validated for audit trail
     ✅ Status history added with enhanced data including Firebase UID
     ✅ Audit trail: updated_by_user_id = [Firebase-UID]
     ✅ Case status updated successfully
     ```

### 2. Database Verification
```sql
-- Check the latest status history entry
SELECT 
    complaint_id,
    status,
    updated_by,
    updated_by_user_id,
    remarks,
    urgency_level,
    timestamp
FROM status_history 
ORDER BY timestamp DESC 
LIMIT 3;

-- Verify Firebase UID format
SELECT 
    updated_by_user_id,
    CASE 
        WHEN updated_by_user_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
        THEN 'Valid UUID Format' 
        ELSE 'Invalid Format' 
    END as uid_validation
FROM status_history 
WHERE updated_by_user_id IS NOT NULL
ORDER BY timestamp DESC 
LIMIT 5;
```

### Expected Results:
```
complaint_id          | status            | updated_by      | updated_by_user_id  | remarks                    | urgency_level
---------------------|------------------|----------------|-------------------|---------------------------|-------------
[uuid]               | Under Investigation | Officer John Doe | firebase-uid-123    | Starting investigation... | high
```

### Enhanced Verification with JOIN:
```sql
-- Verify the FK relationship works correctly
SELECT 
  sh.status,
  sh.updated_by,
  sh.updated_by_user_id,
  po.full_name,
  po.badge_number,
  po.rank,
  sh.timestamp
FROM status_history sh
JOIN pnp_officer_profiles po ON po.firebase_uid = sh.updated_by_user_id
WHERE sh.updated_by_user_id IS NOT NULL
ORDER BY sh.timestamp DESC 
LIMIT 5;
```

### 3. Mobile App Timeline Test

1. **Open Flutter Mobile App**
   ```bash
   cd ../  # Back to root directory
   flutter run
   ```

2. **Navigate to Case Details**
   - Go to "Reports" or "History" tab
   - Find the case you just updated
   - Tap to open details
   - Expand the "Status Timeline"

3. **Verify Timeline Display**
   - Should show latest status update
   - Updated by: "Officer John Doe" (not Firebase ID)
   - Timestamp should be recent
   - Notes should display correctly
   - Status should show "Under Investigation"

### 4. Cross-Platform Consistency Test

1. **Update Status from Web Again**
   - Change status: Under Investigation → Requires More Information
   - Add follow-up note
   - Set different urgency level

2. **Check Mobile App Real-time Update**
   - Pull to refresh case details
   - Verify new status appears in timeline
   - Verify all fields display properly

## Success Criteria

### ✅ Web App
- [ ] No database errors in console
- [ ] Officer name displays correctly in status updates
- [ ] Firebase UID is captured in `updated_by_user_id`
- [ ] Enhanced status fields (urgency, notes) save properly
- [ ] No foreign key constraint violations

### ✅ Database
- [ ] Foreign key constraint removed successfully
- [ ] UUID format constraint working
- [ ] Status history records have proper audit trail
- [ ] All enhanced fields populate correctly

### ✅ Mobile App
- [ ] Status timeline displays officer names
- [ ] Timeline expandable widget works
- [ ] Real-time updates reflect web app changes
- [ ] All status history information visible

### ✅ Integration
- [ ] Cross-platform consistency maintained
- [ ] Audit trail traceable from Firebase UID to officer
- [ ] No data loss or corruption
- [ ] Performance unaffected

## Troubleshooting

### If Firebase UID Still Shows as Null
1. Check Firebase authentication in browser dev tools
2. Verify `currentUserId` is set in PNP Officer Service
3. Confirm officer profile exists with correct `firebase_uid`

### If Status Updates Still Fail
1. Check browser console for specific error
2. Verify database migration applied correctly
3. Check table structure and constraints

### If Mobile App Doesn't Show Updates
1. Verify Flutter app is connected to same database
2. Check mobile app's complaint service loading
3. Test with manual database refresh

## Rollback Plan

If critical issues arise:
```sql
-- Emergency rollback (not recommended)
ALTER TABLE status_history 
ADD CONSTRAINT status_history_updated_by_user_id_fkey 
FOREIGN KEY (updated_by_user_id) REFERENCES auth.users(id);

-- Then set all updated_by_user_id to null
UPDATE status_history SET updated_by_user_id = null;
```

This test plan ensures the fix works correctly across both web and mobile applications while maintaining data integrity and audit functionality.