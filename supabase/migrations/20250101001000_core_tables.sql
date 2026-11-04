CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name text,
  mobile text,
  avatar_path text,
  role public.user_role NOT NULL DEFAULT 'customer',
  status public.account_status NOT NULL DEFAULT 'active',
  blocked_reason text,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

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
  booking_number text NOT NULL UNIQUE,
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
  CHECK (total_paise = subtotal_paise + tax_paise - discount_paise),
  CHECK ((booking_type = 'trip' AND trip_id IS NOT NULL AND package_id IS NULL) OR (booking_type = 'package' AND package_id IS NOT NULL AND trip_id IS NULL))
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
