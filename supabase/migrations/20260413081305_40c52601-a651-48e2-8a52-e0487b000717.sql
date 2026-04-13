-- Track failed login attempts per email
CREATE TABLE public.failed_login_attempts (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  email text NOT NULL,
  attempt_count integer NOT NULL DEFAULT 1,
  locked_until timestamp with time zone,
  last_attempt_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Unique constraint on email so we upsert
CREATE UNIQUE INDEX idx_failed_login_email ON public.failed_login_attempts (email);

-- Enable RLS but allow public access via server function only
ALTER TABLE public.failed_login_attempts ENABLE ROW LEVEL SECURITY;

-- No direct client access; all access goes through security definer functions

-- Function to check if an email is locked out
CREATE OR REPLACE FUNCTION public.check_login_lockout(p_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  result jsonb;
  rec record;
BEGIN
  SELECT * INTO rec FROM public.failed_login_attempts WHERE email = p_email;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('locked', false, 'attempts', 0);
  END IF;

  -- If locked and lock hasn't expired
  IF rec.locked_until IS NOT NULL AND rec.locked_until > now() THEN
    RETURN jsonb_build_object(
      'locked', true,
      'attempts', rec.attempt_count,
      'locked_until', rec.locked_until
    );
  END IF;

  -- If lock expired, reset
  IF rec.locked_until IS NOT NULL AND rec.locked_until <= now() THEN
    DELETE FROM public.failed_login_attempts WHERE email = p_email;
    RETURN jsonb_build_object('locked', false, 'attempts', 0);
  END IF;

  RETURN jsonb_build_object('locked', false, 'attempts', rec.attempt_count);
END;
$$;

-- Function to record a failed attempt (locks after 5)
CREATE OR REPLACE FUNCTION public.record_failed_login(p_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  new_count integer;
  lock_time timestamp with time zone;
BEGIN
  INSERT INTO public.failed_login_attempts (email, attempt_count, last_attempt_at)
  VALUES (p_email, 1, now())
  ON CONFLICT (email) DO UPDATE
    SET attempt_count = public.failed_login_attempts.attempt_count + 1,
        last_attempt_at = now()
  RETURNING attempt_count INTO new_count;

  IF new_count >= 5 THEN
    lock_time := now() + interval '15 minutes';
    UPDATE public.failed_login_attempts
      SET locked_until = lock_time
      WHERE email = p_email;
    RETURN jsonb_build_object('locked', true, 'attempts', new_count, 'locked_until', lock_time);
  END IF;

  RETURN jsonb_build_object('locked', false, 'attempts', new_count);
END;
$$;

-- Function to clear attempts on successful login
CREATE OR REPLACE FUNCTION public.clear_failed_logins(p_email text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  DELETE FROM public.failed_login_attempts WHERE email = p_email;
END;
$$;