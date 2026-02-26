

## Plan: Add Email to User Management Page

### Problem
The current User Management table only shows user name and role. The `profiles` table lacks an `email` column, so the Super Admin cannot see or search by email when assigning roles.

### Solution

#### 1. Database Migration — Add `email` column to `profiles`
- Add a nullable `email` text column to the `profiles` table.
- Update the `handle_new_user()` trigger to also store the user's email from `NEW.email`.
- Backfill existing profiles with emails from `auth.users` using a one-time update in the migration (via a security definer function to avoid direct auth schema modification in RLS context).

#### 2. Update `UserManagement.tsx`
- Update the query to also fetch `email` from profiles.
- Add an "Email" column to the users table between "User" and "Current Role".
- Display the email in a smaller, muted style beneath or beside the user name.
- The table columns become: **User** (avatar + name + email), **Current Role**, **Change Role**.

### Technical Details

**Migration SQL:**
```sql
-- Add email column
ALTER TABLE public.profiles ADD COLUMN email text;

-- Backfill existing profiles
UPDATE public.profiles p
SET email = u.email
FROM auth.users u
WHERE p.user_id = u.id;

-- Update trigger to capture email on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, full_name, email)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''), NEW.email);
  RETURN NEW;
END;
$$;
```

**Frontend changes in `UserManagement.tsx`:**
- Add `email` to the `UserWithRole` interface.
- Fetch `email` in the profiles select query.
- Display email under the user's name in the User column as `<span className="text-xs text-muted-foreground">{u.email}</span>`.

### Files Changed
- **New migration** for the `email` column + trigger update
- **`src/pages/UserManagement.tsx`** — add email display

