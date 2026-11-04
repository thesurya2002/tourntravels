CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TYPE public.user_role AS ENUM ('customer', 'support', 'admin', 'super_admin');
CREATE TYPE public.account_status AS ENUM ('active', 'blocked');
CREATE TYPE public.service_mode AS ENUM ('with_driver', 'self_drive');
CREATE TYPE public.car_status AS ENUM ('active', 'inactive', 'maintenance');
CREATE TYPE public.content_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE public.price_basis AS ENUM ('per_person', 'per_vehicle', 'fixed');
CREATE TYPE public.booking_type AS ENUM ('trip', 'package');
CREATE TYPE public.booking_status AS ENUM ('draft', 'pending_payment', 'confirmed', 'driver_assigned', 'in_progress', 'completed', 'cancelled', 'expired');
CREATE TYPE public.payment_status AS ENUM ('unpaid', 'pending', 'paid', 'partially_refunded', 'refunded', 'failed');
CREATE TYPE public.payment_record_status AS ENUM ('created', 'authorized', 'captured', 'failed');
CREATE TYPE public.refund_status AS ENUM ('initiated', 'processed', 'failed');
CREATE TYPE public.coupon_type AS ENUM ('flat', 'percent');
CREATE TYPE public.review_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE public.enquiry_status AS ENUM ('new', 'contacted', 'closed');
CREATE TYPE public.email_status AS ENUM ('queued', 'sending', 'sent', 'failed');
CREATE TYPE public.pricing_rule_type AS ENUM ('surcharge_flat', 'surcharge_percent', 'discount_percent');
