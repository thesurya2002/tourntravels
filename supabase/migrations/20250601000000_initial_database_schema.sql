CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TYPE public.user_role AS ENUM ('customer', 'support', 'admin', 'super_admin');
CREATE TYPE public.account_status AS ENUM ('active', 'blocked');
CREATE TYPE public.service_mode AS ENUM ('with_driver', 'self_drive');
CREATE TYPE public.car_status AS ENUM ('active', 'inactive', 'maintenance');
CREATE TYPE public.content_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE public.price_basis AS ENUM ('per_person', 'per_vehicle', 'fixed');
CREATE TYPE public.booking_type AS ENUM ('trip', 'package');
CREATE TYPE public.booking_status AS ENUM (
  'draft',
  'pending_payment',
  'confirmed',
  'driver_assigned',
  'in_progress',
  'completed',
  'cancelled',
  'expired'
);
CREATE TYPE public.payment_status AS ENUM ('unpaid', 'pending', 'paid', 'partially_refunded', 'refunded', 'failed');
CREATE TYPE public.payment_record_status AS ENUM ('created', 'authorized', 'captured', 'failed');
CREATE TYPE public.refund_status AS ENUM ('initiated', 'processed', 'failed');
CREATE TYPE public.coupon_type AS ENUM ('flat', 'percent');
CREATE TYPE public.review_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE public.enquiry_status AS ENUM ('new', 'contacted', 'closed');
CREATE TYPE public.email_status AS ENUM ('queued', 'sending', 'sent', 'failed');
CREATE TYPE public.pricing_rule_type AS ENUM ('surcharge_flat', 'surcharge_percent', 'discount_percent');

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name text,
  mobile text CHECK (mobile IS NULL OR mobile ~ '^[0-9+()\s-]{7,20}$'),
  avatar_path text,
  role public.user_role NOT NULL DEFAULT 'customer',
  status public.account_status NOT NULL DEFAULT 'active',
  blocked_reason text,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.profiles IS 'User profile records linked to auth.users.';
COMMENT ON COLUMN public.profiles.role IS 'Business role used for staff authorization checks.';

CREATE TABLE public.settings (
  id boolean PRIMARY KEY DEFAULT true CHECK (id = true),
  business_name text,
  business_timezone text NOT NULL DEFAULT 'Asia/Kolkata',
  support_email text,
  support_phone text,
  whatsapp_number text,
  address text,
  gst_registered boolean DEFAULT false,
  gstin text,
  gst_rate_bps integer,
  booking_hold_minutes integer,
  advance_payment_percent integer,
  cancellation_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.car_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  description text,
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.cars (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid NOT NULL REFERENCES public.car_categories (id) ON DELETE RESTRICT,
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  brand text,
  model text,
  service_mode public.service_mode NOT NULL DEFAULT 'with_driver',
  seats integer NOT NULL CHECK (seats > 0),
  luggage_capacity integer,
  has_ac boolean DEFAULT true,
  fuel_type text,
  transmission text,
  price_per_km_paise bigint CHECK (price_per_km_paise IS NULL OR price_per_km_paise >= 0),
  price_per_day_paise bigint CHECK (price_per_day_paise IS NULL OR price_per_day_paise >= 0),
  min_charge_paise bigint CHECK (min_charge_paise IS NULL OR min_charge_paise >= 0),
  driver_allowance_paise bigint CHECK (driver_allowance_paise IS NULL OR driver_allowance_paise >= 0),
  image_paths text[] DEFAULT '{}',
  features text[] DEFAULT '{}',
  registration_number text UNIQUE,
  status public.car_status NOT NULL DEFAULT 'active',
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.car_blocked_dates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  car_id uuid NOT NULL REFERENCES public.cars (id) ON DELETE CASCADE,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL CHECK (ends_at > starts_at),
  reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  EXCLUDE USING gist (car_id WITH =, tstzrange(starts_at, ends_at, '[)') WITH &&)
);

CREATE TABLE public.destinations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  region text,
  short_description text,
  description text,
  image_path text,
  is_featured boolean NOT NULL DEFAULT false,
  status public.content_status NOT NULL DEFAULT 'draft',
  sort_order integer DEFAULT 0,
  seo_title text,
  seo_description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  destination_id uuid REFERENCES public.destinations (id) ON DELETE SET NULL,
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  summary text,
  description text,
  duration_days integer NOT NULL CHECK (duration_days > 0),
  duration_nights integer NOT NULL CHECK (duration_nights >= 0),
  price_paise bigint NOT NULL CHECK (price_paise >= 0),
  price_basis public.price_basis NOT NULL DEFAULT 'per_person',
  category text,
  itinerary jsonb DEFAULT '[]'::jsonb,
  inclusions text[] DEFAULT '{}',
  exclusions text[] DEFAULT '{}',
  highlights text[] DEFAULT '{}',
  terms text,
  image_paths text[] DEFAULT '{}',
  is_featured boolean NOT NULL DEFAULT false,
  status public.content_status NOT NULL DEFAULT 'draft',
  seo_title text,
  seo_description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.trips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  origin text,
  destination text,
  distance_km numeric,
  duration_text text,
  description text,
  image_paths text[] DEFAULT '{}',
  is_featured boolean NOT NULL DEFAULT false,
  status public.content_status NOT NULL DEFAULT 'draft',
  seo_title text,
  seo_description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.trip_fares (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id uuid NOT NULL REFERENCES public.trips (id) ON DELETE CASCADE,
  car_category_id uuid NOT NULL REFERENCES public.car_categories (id) ON DELETE RESTRICT,
  fare_paise bigint NOT NULL CHECK (fare_paise >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (trip_id, car_category_id)
);

CREATE TABLE public.drivers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL,
  mobile text,
  licence_number text NOT NULL UNIQUE,
  is_active boolean NOT NULL DEFAULT true,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.pricing_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  rule_type public.pricing_rule_type NOT NULL,
  value integer NOT NULL,
  starts_on date,
  ends_on date,
  applies_to_booking_type public.booking_type,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.refund_policy_tiers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  min_hours_before_start integer NOT NULL CHECK (min_hours_before_start >= 0),
  refund_percent smallint NOT NULL CHECK (refund_percent BETWEEN 0 AND 100),
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.coupons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE CHECK (code ~ '^[A-Z0-9-]+$'),
  coupon_type public.coupon_type NOT NULL,
  value integer NOT NULL CHECK (value >= 0),
  max_discount_paise bigint CHECK (max_discount_paise IS NULL OR max_discount_paise >= 0),
  min_order_paise bigint CHECK (min_order_paise IS NULL OR min_order_paise >= 0),
  valid_from timestamptz,
  valid_to timestamptz,
  usage_limit integer,
  per_user_limit integer,
  used_count integer NOT NULL DEFAULT 0 CHECK (used_count >= 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_number text NOT NULL UNIQUE DEFAULT public.generate_booking_number(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  booking_type public.booking_type NOT NULL,
  trip_id uuid REFERENCES public.trips (id) ON DELETE RESTRICT,
  package_id uuid REFERENCES public.packages (id) ON DELETE RESTRICT,
  car_id uuid REFERENCES public.cars (id) ON DELETE RESTRICT,
  driver_id uuid REFERENCES public.drivers (id) ON DELETE RESTRICT,
  pickup_location text,
  drop_location text,
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  passengers integer NOT NULL CHECK (passengers > 0),
  traveller_name text,
  traveller_phone text,
  traveller_email text,
  special_requests text,
  fare_breakdown jsonb DEFAULT '{}'::jsonb,
  subtotal_paise bigint NOT NULL CHECK (subtotal_paise >= 0),
  tax_paise bigint NOT NULL CHECK (tax_paise >= 0),
  discount_paise bigint NOT NULL CHECK (discount_paise >= 0),
  total_paise bigint NOT NULL CHECK (total_paise >= 0),
  advance_required_paise bigint,
  coupon_id uuid REFERENCES public.coupons (id) ON DELETE SET NULL,
  status public.booking_status NOT NULL DEFAULT 'draft',
  payment_status public.payment_status NOT NULL DEFAULT 'unpaid',
  expires_at timestamptz,
  cancelled_at timestamptz,
  cancelled_reason text,
  internal_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (end_at > start_at),
  CHECK ((booking_type = 'trip' AND trip_id IS NOT NULL AND package_id IS NULL) OR (booking_type = 'package' AND package_id IS NOT NULL AND trip_id IS NULL) OR (booking_type IS NOT NULL)),
  CHECK (total_paise = subtotal_paise + tax_paise - discount_paise),
  EXCLUDE USING gist (
    car_id WITH =,
    tstzrange(start_at, end_at, '[)') WITH &&
  ) WHERE (car_id IS NOT NULL AND status IN ('pending_payment', 'confirmed', 'driver_assigned', 'in_progress'))
);

CREATE TABLE public.booking_status_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL REFERENCES public.bookings (id) ON DELETE CASCADE,
  old_status public.booking_status,
  new_status public.booking_status NOT NULL,
  changed_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL UNIQUE REFERENCES public.bookings (id) ON DELETE RESTRICT,
  razorpay_order_id text NOT NULL UNIQUE,
  razorpay_payment_id text UNIQUE,
  amount_paise bigint NOT NULL CHECK (amount_paise >= 0),
  currency text NOT NULL DEFAULT 'INR' CHECK (currency = 'INR'),
  method text,
  status public.payment_record_status NOT NULL DEFAULT 'created',
  signature_verified boolean NOT NULL DEFAULT false,
  failure_reason text,
  raw_payload jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.payment_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  razorpay_event_id text NOT NULL UNIQUE,
  event_type text NOT NULL,
  payment_id uuid REFERENCES public.payments (id) ON DELETE SET NULL,
  payload jsonb,
  processed_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.refunds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id uuid NOT NULL REFERENCES public.payments (id) ON DELETE RESTRICT,
  razorpay_refund_id text UNIQUE,
  amount_paise bigint NOT NULL CHECK (amount_paise > 0),
  status public.refund_status NOT NULL DEFAULT 'initiated',
  reason text,
  initiated_by uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.coupon_redemptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id uuid NOT NULL REFERENCES public.coupons (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  booking_id uuid NOT NULL UNIQUE REFERENCES public.bookings (id) ON DELETE CASCADE,
  discount_paise bigint NOT NULL CHECK (discount_paise >= 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  booking_id uuid NOT NULL UNIQUE REFERENCES public.bookings (id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment text,
  status public.review_status NOT NULL DEFAULT 'pending',
  is_featured boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.enquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL,
  mobile text,
  message text NOT NULL,
  status public.enquiry_status NOT NULL DEFAULT 'new',
  assigned_to uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  admin_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.newsletter_subscribers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  is_active boolean NOT NULL DEFAULT true,
  subscribed_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.content_faqs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question text NOT NULL,
  answer text NOT NULL,
  sort_order integer DEFAULT 0,
  status public.content_status NOT NULL DEFAULT 'draft',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.content_testimonials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_name text NOT NULL,
  author_location text,
  quote text NOT NULL,
  rating integer CHECK (rating BETWEEN 1 AND 5),
  sort_order integer DEFAULT 0,
  status public.content_status NOT NULL DEFAULT 'draft',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.content_gallery (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  image_path text NOT NULL,
  alt_text text,
  sort_order integer DEFAULT 0,
  status public.content_status NOT NULL DEFAULT 'draft',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.content_banners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  subtitle text,
  cta_label text,
  cta_url text,
  image_path text,
  starts_at timestamptz,
  ends_at timestamptz,
  sort_order integer DEFAULT 0,
  status public.content_status NOT NULL DEFAULT 'draft',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.email_outbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template text NOT NULL,
  to_email text NOT NULL,
  payload jsonb,
  status public.email_status NOT NULL DEFAULT 'queued',
  attempts integer NOT NULL DEFAULT 0,
  last_error text,
  scheduled_for timestamptz NOT NULL DEFAULT now(),
  sent_at timestamptz,
  related_booking_id uuid REFERENCES public.bookings (id) ON DELETE SET NULL,
  related_user_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid REFERENCES public.profiles (id) ON DELETE SET NULL,
  actor_role public.user_role,
  action text NOT NULL,
  entity_type text NOT NULL,
  entity_id uuid,
  before jsonb,
  after jsonb,
  ip inet,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_profiles_role ON public.profiles (role);
CREATE INDEX idx_bookings_user_start ON public.bookings (user_id, start_at DESC);
CREATE INDEX idx_bookings_status ON public.bookings (status);
CREATE INDEX idx_bookings_payment_status ON public.bookings (payment_status);
CREATE INDEX idx_bookings_start_at ON public.bookings (start_at);
CREATE INDEX idx_bookings_car_id ON public.bookings (car_id);
CREATE INDEX idx_bookings_expires_at ON public.bookings (expires_at) WHERE status = 'pending_payment';
CREATE INDEX idx_cars_status_category ON public.cars (status, category_id);
CREATE INDEX idx_packages_status_featured ON public.packages (status, is_featured);
CREATE INDEX idx_trips_status_featured ON public.trips (status, is_featured);
CREATE INDEX idx_destinations_status ON public.destinations (status);
CREATE INDEX idx_payments_booking_id ON public.payments (booking_id);
CREATE INDEX idx_payment_events_payment_id ON public.payment_events (payment_id);
CREATE INDEX idx_reviews_status ON public.reviews (status);
CREATE INDEX idx_enquiries_status ON public.enquiries (status);
CREATE INDEX idx_email_outbox_status_scheduled ON public.email_outbox (status, scheduled_for);
CREATE INDEX idx_audit_logs_entity ON public.audit_logs (entity_type, entity_id);
CREATE INDEX idx_audit_logs_actor ON public.audit_logs (actor_id, created_at DESC);
CREATE INDEX idx_coupon_redemptions_user_coupon ON public.coupon_redemptions (user_id, coupon_id);

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS public.user_role
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('support', 'admin', 'super_admin') AND status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin') AND status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'super_admin' AND status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, mobile, role, status)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NULL),
    COALESCE(NEW.raw_user_meta_data->>'mobile', NULL),
    'customer',
    'active'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_booking_number()
RETURNS text
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  business_date text;
  sequence_value bigint;
BEGIN
  business_date := to_char(now() AT TIME ZONE COALESCE((SELECT business_timezone FROM public.settings LIMIT 1), 'Asia/Kolkata'), 'YYMMDD');
  sequence_value := nextval('public.booking_number_seq');
  RETURN 'TNT-' || business_date || '-' || lpad(sequence_value::text, 6, '0');
END;
$$;

CREATE SEQUENCE public.booking_number_seq START WITH 1 INCREMENT BY 1;

CREATE TRIGGER trg_set_updated_at_profilest
BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_car_categories BEFORE UPDATE ON public.car_categories FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_cars BEFORE UPDATE ON public.cars FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_car_blocked_dates BEFORE UPDATE ON public.car_blocked_dates FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_destinations BEFORE UPDATE ON public.destinations FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_packages BEFORE UPDATE ON public.packages FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_trips BEFORE UPDATE ON public.trips FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_trip_fares BEFORE UPDATE ON public.trip_fares FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_drivers BEFORE UPDATE ON public.drivers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_pricing_rules BEFORE UPDATE ON public.pricing_rules FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_refund_policy_tiers BEFORE UPDATE ON public.refund_policy_tiers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_coupons BEFORE UPDATE ON public.coupons FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_bookings BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_reviews BEFORE UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_enquiries BEFORE UPDATE ON public.enquiries FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_newsletter_subscribers BEFORE UPDATE ON public.newsletter_subscribers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_content_faqs BEFORE UPDATE ON public.content_faqs FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_content_testimonials BEFORE UPDATE ON public.content_testimonials FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_content_gallery BEFORE UPDATE ON public.content_gallery FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_content_banners BEFORE UPDATE ON public.content_banners FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_set_updated_at_email_outbox BEFORE UPDATE ON public.email_outbox FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

REVOKE ALL ON FUNCTION public.current_user_role() FROM public;
GRANT EXECUTE ON FUNCTION public.current_user_role() TO anon, authenticated;
REVOKE ALL ON FUNCTION public.is_staff() FROM public;
GRANT EXECUTE ON FUNCTION public.is_staff() TO anon, authenticated;
REVOKE ALL ON FUNCTION public.is_admin() FROM public;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;
REVOKE ALL ON FUNCTION public.is_super_admin() FROM public;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM public;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon, authenticated;
REVOKE ALL ON FUNCTION public.generate_booking_number() FROM public;
GRANT EXECUTE ON FUNCTION public.generate_booking_number() TO anon, authenticated;

CREATE VIEW public.public_settings WITH (security_invoker = false) AS
SELECT business_name, support_email, support_phone, whatsapp_number, address, business_timezone
FROM public.settings;

GRANT SELECT ON public.public_settings TO anon, authenticated;
COMMENT ON VIEW public.public_settings IS
  'Public allow-list view. Owner rights intentionally expose only the explicitly selected safe settings columns.';

CREATE VIEW public.public_reviews WITH (security_invoker = false) AS
SELECT r.id, r.rating, r.comment, r.created_at, p.full_name AS author_name
FROM public.reviews r
JOIN public.profiles p ON p.id = r.user_id
WHERE r.status = 'approved';

GRANT SELECT ON public.public_reviews TO anon, authenticated;
COMMENT ON VIEW public.public_reviews IS
  'Public allow-list view. Owner rights intentionally expose only approved review fields.';

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.car_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.car_blocked_dates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.destinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_fares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pricing_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refund_policy_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupon_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.newsletter_subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_testimonials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_gallery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.profiles REPLICA IDENTITY FULL;

REVOKE ALL ON TABLE public.profiles FROM anon, authenticated;
REVOKE ALL ON TABLE public.settings FROM anon, authenticated;
REVOKE ALL ON TABLE public.car_categories FROM anon, authenticated;
REVOKE ALL ON TABLE public.cars FROM anon, authenticated;
REVOKE ALL ON TABLE public.car_blocked_dates FROM anon, authenticated;
REVOKE ALL ON TABLE public.destinations FROM anon, authenticated;
REVOKE ALL ON TABLE public.packages FROM anon, authenticated;
REVOKE ALL ON TABLE public.trips FROM anon, authenticated;
REVOKE ALL ON TABLE public.trip_fares FROM anon, authenticated;
REVOKE ALL ON TABLE public.drivers FROM anon, authenticated;
REVOKE ALL ON TABLE public.pricing_rules FROM anon, authenticated;
REVOKE ALL ON TABLE public.refund_policy_tiers FROM anon, authenticated;
REVOKE ALL ON TABLE public.coupons FROM anon, authenticated;
REVOKE ALL ON TABLE public.bookings FROM anon, authenticated;
REVOKE ALL ON TABLE public.booking_status_history FROM anon, authenticated;
REVOKE ALL ON TABLE public.payments FROM anon, authenticated;
REVOKE ALL ON TABLE public.payment_events FROM anon, authenticated;
REVOKE ALL ON TABLE public.refunds FROM anon, authenticated;
REVOKE ALL ON TABLE public.coupon_redemptions FROM anon, authenticated;
REVOKE ALL ON TABLE public.reviews FROM anon, authenticated;
REVOKE ALL ON TABLE public.enquiries FROM anon, authenticated;
REVOKE ALL ON TABLE public.newsletter_subscribers FROM anon, authenticated;
REVOKE ALL ON TABLE public.content_faqs FROM anon, authenticated;
REVOKE ALL ON TABLE public.content_testimonials FROM anon, authenticated;
REVOKE ALL ON TABLE public.content_gallery FROM anon, authenticated;
REVOKE ALL ON TABLE public.content_banners FROM anon, authenticated;
REVOKE ALL ON TABLE public.email_outbox FROM anon, authenticated;
REVOKE ALL ON TABLE public.audit_logs FROM anon, authenticated;

CREATE POLICY "profiles_select_own" ON public.profiles
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles_select_staff" ON public.profiles
FOR SELECT USING (public.is_staff());

CREATE POLICY "profiles_update_own" ON public.profiles
FOR UPDATE USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id AND
  (full_name IS NOT NULL OR old.full_name = full_name) AND
  (mobile IS NOT NULL OR old.mobile = mobile) AND
  (avatar_path IS NOT NULL OR old.avatar_path = avatar_path)
);

CREATE POLICY "profiles_admin_update" ON public.profiles
FOR UPDATE USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "settings_select_staff" ON public.settings
FOR SELECT USING (public.is_staff());

CREATE POLICY "settings_admin_update" ON public.settings
FOR UPDATE USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "catalogue_public_select" ON public.destinations
FOR SELECT USING (status = 'published'::public.content_status);

CREATE POLICY "catalogue_admin_all" ON public.destinations
FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "package_public_select" ON public.packages
FOR SELECT USING (status = 'published'::public.content_status);

CREATE POLICY "package_admin_all" ON public.packages
FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "trip_public_select" ON public.trips
FOR SELECT USING (status = 'published'::public.content_status);

CREATE POLICY "trip_admin_all" ON public.trips
FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "cars_public_select" ON public.cars
FOR SELECT USING (status = 'active'::public.car_status);

CREATE POLICY "cars_admin_all" ON public.cars
FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "trip_fares_public_select" ON public.trip_fares
FOR SELECT USING (EXISTS (SELECT 1 FROM public.trips t WHERE t.id = trip_fares.trip_id AND t.status = 'published'::public.content_status));

CREATE POLICY "trip_fares_admin_all" ON public.trip_fares
FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "staff_read_car_blocked_dates" ON public.car_blocked_dates
FOR SELECT USING (public.is_staff());

CREATE POLICY "admin_all_car_blocked_dates" ON public.car_blocked_dates
FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "staff_read_drivers" ON public.drivers FOR SELECT USING (public.is_staff());
CREATE POLICY "admin_all_drivers" ON public.drivers FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "staff_read_pricing_rules" ON public.pricing_rules FOR SELECT USING (public.is_staff());
CREATE POLICY "admin_all_pricing_rules" ON public.pricing_rules FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "public_refund_policy_select" ON public.refund_policy_tiers FOR SELECT USING (is_active = true);
CREATE POLICY "admin_all_refund_tiers" ON public.refund_policy_tiers FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "staff_read_coupons" ON public.coupons FOR SELECT USING (public.is_staff());
CREATE POLICY "admin_all_coupons" ON public.coupons FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "bookings_customer_select_own" ON public.bookings
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "bookings_staff_select" ON public.bookings
FOR SELECT USING (public.is_staff());

CREATE POLICY "bookings_admin_update" ON public.bookings
FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "booking_history_customer_select_own" ON public.booking_status_history
FOR SELECT USING (EXISTS (SELECT 1 FROM public.bookings b WHERE b.id = booking_status_history.booking_id AND b.user_id = auth.uid()));
CREATE POLICY "booking_history_staff_select" ON public.booking_status_history
FOR SELECT USING (public.is_staff());

CREATE POLICY "payments_customer_select_own" ON public.payments
FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.bookings b WHERE b.id = payments.booking_id AND b.user_id = auth.uid())
);
CREATE POLICY "payments_staff_select" ON public.payments FOR SELECT USING (public.is_staff());

CREATE POLICY "payment_events_staff_select" ON public.payment_events FOR SELECT USING (public.is_staff());
CREATE POLICY "payment_events_admin_only" ON public.payment_events FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "refunds_customer_select_own" ON public.refunds
FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.payments p JOIN public.bookings b ON b.id = p.booking_id WHERE p.id = refunds.payment_id AND b.user_id = auth.uid())
);
CREATE POLICY "refunds_staff_select" ON public.refunds FOR SELECT USING (public.is_staff());

CREATE POLICY "coupon_redemptions_customer_select_own" ON public.coupon_redemptions
FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "coupon_redemptions_staff_select" ON public.coupon_redemptions FOR SELECT USING (public.is_staff());

CREATE POLICY "reviews_insert_own_completed" ON public.reviews
FOR INSERT WITH CHECK (
  user_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM public.bookings b WHERE b.id = booking_id AND b.user_id = auth.uid() AND b.status = 'completed'
  ) AND status = 'pending'
);
CREATE POLICY "reviews_select_own" ON public.reviews FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "reviews_update_own_pending" ON public.reviews
FOR UPDATE USING (user_id = auth.uid() AND status = 'pending')
WITH CHECK (user_id = auth.uid() AND status = 'pending');
CREATE POLICY "reviews_admin_manage" ON public.reviews FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "enquiries_insert_any" ON public.enquiries
FOR INSERT WITH CHECK (status = 'new');
CREATE POLICY "enquiries_staff_select" ON public.enquiries FOR SELECT USING (public.is_staff());
CREATE POLICY "enquiries_admin_update" ON public.enquiries FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "newsletter_insert" ON public.newsletter_subscribers FOR INSERT WITH CHECK (true);
CREATE POLICY "newsletter_staff_select" ON public.newsletter_subscribers FOR SELECT USING (public.is_staff());
CREATE POLICY "newsletter_admin_update" ON public.newsletter_subscribers FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "content_public_select" ON public.content_faqs FOR SELECT USING (status = 'published'::public.content_status);
CREATE POLICY "content_admin_all_faqs" ON public.content_faqs FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "content_testimonials_public_select" ON public.content_testimonials FOR SELECT USING (status = 'published'::public.content_status);
CREATE POLICY "content_admin_all_testimonials" ON public.content_testimonials FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "content_gallery_public_select" ON public.content_gallery FOR SELECT USING (status = 'published'::public.content_status);
CREATE POLICY "content_admin_all_gallery" ON public.content_gallery FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "content_banners_public_select" ON public.content_banners FOR SELECT USING (status = 'published'::public.content_status);
CREATE POLICY "content_admin_all_banners" ON public.content_banners FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "email_outbox_staff_select" ON public.email_outbox FOR SELECT USING (public.is_admin());
CREATE POLICY "email_outbox_server_only" ON public.email_outbox FOR ALL USING (false) WITH CHECK (false);

CREATE POLICY "audit_logs_admin_select" ON public.audit_logs FOR SELECT USING (public.is_admin());
CREATE POLICY "audit_logs_server_only" ON public.audit_logs FOR INSERT WITH CHECK (false);

INSERT INTO public.settings (id, business_name, business_timezone, support_email, support_phone, whatsapp_number, address, gst_registered, gstin, gst_rate_bps)
VALUES (true, NULL, 'Asia/Kolkata', NULL, NULL, NULL, NULL, false, NULL, NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.car_categories (name, slug, description, sort_order, is_active)
VALUES
('Sedan', 'sedan', 'Sample sedan category', 1, true),
('SUV', 'suv', 'Sample SUV category', 2, true),
('Hatchback', 'hatchback', 'Sample hatchback category', 3, true),
('Premium', 'premium', 'Sample premium category', 4, true)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.content_faqs (question, answer, sort_order, status)
VALUES
('Sample question', 'This is a sample answer.', 1, 'published'),
('Draft question', 'This is a draft answer.', 2, 'draft')
ON CONFLICT DO NOTHING;
