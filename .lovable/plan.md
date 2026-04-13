

## Plan: Branded Auth Emails + Forgot Password Dialog

### What we will build

**1. Forgot Password popup dialog**
Replace the current inline "Forgot password?" button (which requires email to already be filled in the login form) with a proper Dialog popup:
- Clicking "Forgot password?" opens a modal with its own email input field
- User enters their email and clicks "Send Reset Link"
- Shows loading state while sending, success/error feedback via toast
- Can be used independently of the login form state

**2. Custom branded auth email templates**
Set up ExpoPay-branded email templates for password reset, signup confirmation, magic links, etc. This requires configuring an email domain first.

### Implementation steps

**Step 1 -- Update Login.tsx: Forgot Password Dialog**
- Add a `forgotOpen` state and `resetEmail` state
- Replace the inline button+logic with a Dialog containing:
  - Email input with Mail icon
  - "Send Reset Link" button with loading state
  - Calls `supabase.auth.resetPasswordForEmail` on submit
- Import Dialog components from `@/components/ui/dialog`

**Step 2 -- Set up email domain**
No email domain is configured yet. We need to set one up before we can create branded templates. You will be prompted to configure your sender domain (e.g., `notify@yourdomain.com`).

**Step 3 -- Scaffold and brand auth email templates**
Once the domain is set:
- Scaffold all 6 auth email templates (signup, recovery, magic-link, invite, email-change, reauthentication)
- Apply ExpoPay branding: green primary (`hsl(152, 100%, 30%)`), gold accent (`hsl(45, 100%, 50%)`), dark secondary (`hsl(200, 60%, 22%)`), Space Grotesk headings, Inter body text, `0.625rem` border radius
- Deploy the auth-email-hook edge function

### Technical details
- Files changed: `src/pages/Login.tsx`
- Files created: auth email templates under `supabase/functions/_shared/email-templates/`
- Edge function deployed: `auth-email-hook`
- The Forgot Password dialog uses the existing `Dialog` component from the UI library

