
CREATE OR REPLACE FUNCTION public.delete_user_cascade(_target_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  caller_id uuid := auth.uid();
  target_email text;
  target_full_name text;
  target_role app_role;
  detached_initiated uuid[];
  detached_approved  uuid[];
BEGIN
  IF NOT public.has_role(caller_id, 'super_admin'::app_role) THEN
    RAISE EXCEPTION 'Only super admins can delete users';
  END IF;

  IF caller_id = _target_user_id THEN
    RAISE EXCEPTION 'You cannot delete your own account';
  END IF;

  SELECT email, full_name INTO target_email, target_full_name
  FROM public.profiles WHERE user_id = _target_user_id;

  SELECT role INTO target_role
  FROM public.user_roles WHERE user_id = _target_user_id LIMIT 1;

  -- Detach (preserve) batches and capture which ones
  WITH upd AS (
    UPDATE public.batches SET initiator_user_id = NULL
    WHERE initiator_user_id = _target_user_id
    RETURNING id
  )
  SELECT COALESCE(array_agg(id), ARRAY[]::uuid[]) INTO detached_initiated FROM upd;

  WITH upd AS (
    UPDATE public.batches SET approver_user_id = NULL
    WHERE approver_user_id = _target_user_id
    RETURNING id
  )
  SELECT COALESCE(array_agg(id), ARRAY[]::uuid[]) INTO detached_approved FROM upd;

  DELETE FROM public.user_roles WHERE user_id = _target_user_id;
  DELETE FROM public.profiles  WHERE user_id = _target_user_id;
  DELETE FROM auth.users       WHERE id      = _target_user_id;

  RETURN jsonb_build_object(
    'success', true,
    'email', target_email,
    'full_name', target_full_name,
    'previous_role', target_role,
    'detached_initiated_batch_ids', to_jsonb(detached_initiated),
    'detached_approved_batch_ids',  to_jsonb(detached_approved),
    'detached_batch_count', array_length(detached_initiated, 1) + array_length(detached_approved, 1)
  );
END;
$function$;
