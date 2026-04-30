
DO $$
DECLARE
  target_ids uuid[] := ARRAY[
    '9cf94166-10ce-4a44-9685-7f948b086a59',
    'da2759d2-7a31-4120-afe6-0371fced4767',
    '88b7c7a6-cead-4e56-b4fb-90429f946737',
    '24d84ea3-fa29-439c-8729-364a7fd790cb',
    '221622b7-b6c5-4227-bbba-994b0df439fc'
  ]::uuid[];
  rec record;
BEGIN
  FOR rec IN SELECT user_id, email FROM public.profiles WHERE user_id = ANY(target_ids) LOOP
    INSERT INTO public.audit_logs (action, action_type, user_name, user_role, details)
    VALUES (
      'User deleted: ' || rec.email,
      'config',
      'Super Admin',
      'super_admin',
      jsonb_build_object('target_user_id', rec.user_id, 'target_email', rec.email, 'method', 'manual_admin_request')
    );
  END LOOP;

  UPDATE public.batches SET initiator_user_id = NULL WHERE initiator_user_id = ANY(target_ids);
  UPDATE public.batches SET approver_user_id  = NULL WHERE approver_user_id  = ANY(target_ids);

  DELETE FROM public.user_roles WHERE user_id = ANY(target_ids);
  DELETE FROM public.profiles  WHERE user_id = ANY(target_ids);
  DELETE FROM auth.users       WHERE id      = ANY(target_ids);
END $$;
