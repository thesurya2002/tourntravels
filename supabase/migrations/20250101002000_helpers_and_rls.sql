CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
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
    WHERE id = auth.uid() AND status = 'active' AND role IN ('support', 'admin', 'super_admin')
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
    WHERE id = auth.uid() AND status = 'active' AND role IN ('admin', 'super_admin')
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
    WHERE id = auth.uid() AND status = 'active' AND role = 'super_admin'
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
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.raw_user_meta_data ->> 'mobile',
    'customer',
    'active'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_booking_number()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  seq_value integer;
BEGIN
  seq_value := nextval('public.booking_number_seq');
  RETURN 'TNT-' || to_char(now() AT TIME ZONE COALESCE((SELECT business_timezone FROM public.settings LIMIT 1), 'Asia/Kolkata'), 'YYMMDD') || '-' || lpad(seq_value::text, 6, '0');
END;
$$;

CREATE SEQUENCE IF NOT EXISTS public.booking_number_seq START WITH 1 INCREMENT BY 1;

CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_settings_updated_at BEFORE UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_car_categories_updated_at BEFORE UPDATE ON public.car_categories FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_cars_updated_at BEFORE UPDATE ON public.cars FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_destinations_updated_at BEFORE UPDATE ON public.destinations FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_packages_updated_at BEFORE UPDATE ON public.packages FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_trips_updated_at BEFORE UPDATE ON public.trips FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_trip_fares_updated_at BEFORE UPDATE ON public.trip_fares FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_drivers_updated_at BEFORE UPDATE ON public.drivers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_coupons_updated_at BEFORE UPDATE ON public.coupons FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_bookings_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_reviews_updated_at BEFORE UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_enquiries_updated_at BEFORE UPDATE ON public.enquiries FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_newsletter_subscribers_updated_at BEFORE UPDATE ON public.newsletter_subscribers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_content_faqs_updated_at BEFORE UPDATE ON public.content_faqs FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_content_testimonials_updated_at BEFORE UPDATE ON public.content_testimonials FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_content_gallery_updated_at BEFORE UPDATE ON public.content_gallery FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_content_banners_updated_at BEFORE UPDATE ON public.content_banners FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_email_outbox_updated_at BEFORE UPDATE ON public.email_outbox FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE VIEW public.public_settings WITH (security_invoker = false) AS
SELECT business_name, support_email, support_phone, whatsapp_number, address, business_timezone
FROM public.settings;

COMMENT ON VIEW public.public_settings IS
  'Public allow-list view. Owner rights intentionally expose only the explicitly selected safe settings columns.';

CREATE VIEW public.public_reviews WITH (security_invoker = false) AS
SELECT r.id, r.rating, r.comment, r.created_at, p.full_name AS author_name
FROM public.reviews r
JOIN public.profiles p ON p.id = r.user_id
WHERE r.status = 'approved';

COMMENT ON VIEW public.public_reviews IS
  'Public allow-list view. Owner rights intentionally expose only approved review fields.';

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

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.car_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cars ENABLE ROW LEVEL SECURITY;
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
REVOKE ALL ON TABLE public.profiles FROM anon, authenticated;
REVOKE ALL ON TABLE public.settings FROM anon, authenticated;
REVOKE ALL ON TABLE public.car_categories FROM anon, authenticated;
REVOKE ALL ON TABLE public.cars FROM anon, authenticated;
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

CREATE POLICY "profiles_select_self" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_select_staff" ON public.profiles FOR SELECT USING (public.is_staff());
CREATE POLICY "profiles_update_self" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_admin_update" ON public.profiles FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "settings_read_staff" ON public.settings FOR SELECT USING (public.is_staff());
CREATE POLICY "settings_update_admin" ON public.settings FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "catalogue_public_read" ON public.destinations FOR SELECT USING (status = 'published');
CREATE POLICY "catalogue_admin_all" ON public.destinations FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "packages_public_read" ON public.packages FOR SELECT USING (status = 'published');
CREATE POLICY "packages_admin_all" ON public.packages FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "trips_public_read" ON public.trips FOR SELECT USING (status = 'published');
CREATE POLICY "trips_admin_all" ON public.trips FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "cars_public_read" ON public.cars FOR SELECT USING (status = 'active');
CREATE POLICY "cars_admin_all" ON public.cars FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "trip_fares_public_read" ON public.trip_fares FOR SELECT USING (EXISTS (SELECT 1 FROM public.trips t WHERE t.id = trip_fares.trip_id AND t.status = 'published'));
CREATE POLICY "trip_fares_admin_all" ON public.trip_fares FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "drivers_staff_read" ON public.drivers FOR SELECT USING (public.is_staff());
CREATE POLICY "drivers_admin_all" ON public.drivers FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "pricing_rules_staff_read" ON public.pricing_rules FOR SELECT USING (public.is_staff());
CREATE POLICY "pricing_rules_admin_all" ON public.pricing_rules FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "refund_tiers_public_read" ON public.refund_policy_tiers FOR SELECT USING (is_active = true);
CREATE POLICY "refund_tiers_admin_all" ON public.refund_policy_tiers FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "coupon_staff_read" ON public.coupons FOR SELECT USING (public.is_staff());
CREATE POLICY "coupon_admin_all" ON public.coupons FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "bookings_own_select" ON public.bookings FOR SELECT USING (auth.uid() = user_id OR public.is_staff());
CREATE POLICY "bookings_admin_update" ON public.bookings FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "booking_history_self_read" ON public.booking_status_history FOR SELECT USING (EXISTS (SELECT 1 FROM public.bookings b WHERE b.id = booking_status_history.booking_id AND b.user_id = auth.uid()) OR public.is_staff());
CREATE POLICY "payments_self_read" ON public.payments FOR SELECT USING (EXISTS (SELECT 1 FROM public.bookings b WHERE b.id = payments.booking_id AND b.user_id = auth.uid()) OR public.is_staff());
CREATE POLICY "payment_events_staff_read" ON public.payment_events FOR SELECT USING (public.is_staff());
CREATE POLICY "refunds_self_read" ON public.refunds FOR SELECT USING (EXISTS (SELECT 1 FROM public.payments p JOIN public.bookings b ON b.id = p.booking_id WHERE p.id = refunds.payment_id AND b.user_id = auth.uid()) OR public.is_staff());
CREATE POLICY "coupon_redemptions_self_read" ON public.coupon_redemptions FOR SELECT USING (user_id = auth.uid() OR public.is_staff());

CREATE POLICY "reviews_self_select" ON public.reviews FOR SELECT USING (user_id = auth.uid() OR public.is_staff());
CREATE POLICY "reviews_insert_self" ON public.reviews FOR INSERT WITH CHECK (user_id = auth.uid() AND status = 'pending');
CREATE POLICY "reviews_update_self_pending" ON public.reviews FOR UPDATE USING (user_id = auth.uid() AND status = 'pending') WITH CHECK (user_id = auth.uid() AND status = 'pending');
CREATE POLICY "reviews_admin_all" ON public.reviews FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "enquiries_insert_public" ON public.enquiries FOR INSERT WITH CHECK (status = 'new');
CREATE POLICY "enquiries_staff_select" ON public.enquiries FOR SELECT USING (public.is_staff());
CREATE POLICY "enquiries_admin_update" ON public.enquiries FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "newsletter_insert_public" ON public.newsletter_subscribers FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "newsletter_staff_select" ON public.newsletter_subscribers FOR SELECT USING (public.is_staff());
CREATE POLICY "newsletter_admin_all" ON public.newsletter_subscribers FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "faq_public_read" ON public.content_faqs FOR SELECT USING (status = 'published');
CREATE POLICY "content_admin_all" ON public.content_faqs FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "testimonial_public_read" ON public.content_testimonials FOR SELECT USING (status = 'published');
CREATE POLICY "testimonial_admin_all" ON public.content_testimonials FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "gallery_public_read" ON public.content_gallery FOR SELECT USING (status = 'published');
CREATE POLICY "gallery_admin_all" ON public.content_gallery FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
CREATE POLICY "banner_public_read" ON public.content_banners FOR SELECT USING (status = 'published');
CREATE POLICY "banner_admin_all" ON public.content_banners FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

GRANT EXECUTE ON FUNCTION public.current_user_role() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_staff() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.generate_booking_number() TO anon, authenticated;
