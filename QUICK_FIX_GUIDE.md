# Quick Fix Guide: Status Update Firebase UID Issue

## 🚀 **Simple 3-Step Fix**

### **Step 1: Apply Database Migration**
```sql
-- Copy and paste this into your Supabase SQL editor:

-- Drop old constraint referencing auth.users
ALTER TABLE status_history DROP CONSTRAINT IF EXISTS status_history_updated_by_user_id_fkey;
ALTER TABLE status_history DROP CONSTRAINT IF EXISTS fk_status_history_updated_by_user_id;

-- Change column type from UUID to TEXT
ALTER TABLE status_history ALTER COLUMN updated_by_user_id TYPE TEXT;

-- Add new FK referencing pnp_officer_profiles.firebase_uid
ALTER TABLE status_history 
ADD CONSTRAINT fk_status_history_updated_by_firebase_uid 
FOREIGN KEY (updated_by_user_id) REFERENCES pnp_officer_profiles(firebase_uid) ON DELETE SET NULL;
```

### **Step 2: Verify Fix Applied**
```sql
-- Should show the new constraint referencing pnp_officer_profiles
SELECT 
  tc.constraint_name, 
  ccu.table_name AS references_table,
  ccu.column_name AS references_column
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu 
  ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'status_history' 
  AND tc.constraint_type = 'FOREIGN KEY'
  AND ccu.column_name = 'firebase_uid';
```

### **Step 3: Test Status Update**
1. **Web App**: Login as PNP officer → Update any case status
2. **Check Console**: Should see `✅ Status history added with enhanced data including Firebase UID`
3. **Database**: Run query below to confirm Firebase UID is captured

```sql
-- Should show officer data linked via Firebase UID
SELECT 
  sh.status,
  sh.updated_by,
  sh.updated_by_user_id,
  po.full_name,
  po.badge_number
FROM status_history sh
JOIN pnp_officer_profiles po ON po.firebase_uid = sh.updated_by_user_id
ORDER BY sh.timestamp DESC 
LIMIT 3;
```

## ✅ **Expected Results**

**Before Fix:**
- ❌ `updated_by_user_id: null`
- ❌ Console error: "foreign key constraint violation"

**After Fix:**
- ✅ `updated_by_user_id: "firebase-uid-123"`
- ✅ Console: "Status history added successfully"
- ✅ Can JOIN with officer profiles for reports

## 🔧 **What This Fix Does**

1. **Removes broken reference** to Supabase's auth.users table
2. **Creates proper reference** to your pnp_officer_profiles.firebase_uid
3. **Maintains referential integrity** with your actual authentication system
4. **Enables audit trail** with full officer traceability

## 📊 **Verification Checklist**

- [ ] Database migration runs without errors
- [ ] New FK constraint shows pnp_officer_profiles reference
- [ ] Web app status updates work without console errors
- [ ] Mobile app timeline shows officer names correctly
- [ ] Database queries can JOIN status_history with officer profiles

## 🆘 **Troubleshooting**

**If migration fails:**
- Check that `pnp_officer_profiles` table exists
- Verify `firebase_uid` column exists in `pnp_officer_profiles`
- Ensure no existing invalid data in `updated_by_user_id`

**If status updates still show null:**
- Check Firebase authentication is working
- Verify officer profile exists with correct `firebase_uid`
- Check browser console for authentication errors

That's it! The fix aligns your database schema with your Firebase + Supabase authentication architecture.