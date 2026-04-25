-- Function to allow super admins to delete a user (cascades to profile, role, auth)
CREATE OR REPLACE FUNCTION public.delete_user_cascade(_target_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_id uuid := auth.uid();
  target_email text;
BEGIN
  -- Only super admins can call this
  IF NOT public.has_role(caller_id, 'super_admin'::app_role) THEN
    RAISE EXCEPTION 'Only super admins can delete users';
  END IF;

  -- Prevent self-deletion
  IF caller_id = _target_user_id THEN
    RAISE EXCEPTION 'You cannot delete your own account';
  END IF;

  -- Capture email for audit
  SELECT email INTO target_email FROM public.profiles WHERE user_id = _target_user_id;

  -- Delete role(s)
  DELETE FROM public.user_roles WHERE user_id = _target_user_id;

  -- Delete profile
  DELETE FROM public.profiles WHERE user_id = _target_user_id;

  -- Delete the auth user (cascades sessions etc.)
  DELETE FROM auth.users WHERE id = _target_user_id;

  RETURN jsonb_build_object('success', true, 'email', target_email);
END;
$$;