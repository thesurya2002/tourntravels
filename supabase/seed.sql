-- SAMPLE DATA - NEVER RUN IN PRODUCTION

INSERT INTO public.settings (id, business_timezone, business_name, support_email)
VALUES (true, 'Asia/Kolkata', NULL, NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.car_categories (name, slug, description, sort_order, is_active)
VALUES
  ('Sample Sedan', 'sample-sedan', 'Sample sedan category', 1, true),
  ('Sample SUV', 'sample-suv', 'Sample SUV category', 2, true),
  ('Sample Hatchback', 'sample-hatchback', 'Sample hatchback category', 3, true),
  ('Sample Premium', 'sample-premium', 'Sample premium category', 4, false)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.destinations (name, slug, region, short_description, description, is_featured, status, sort_order)
VALUES
  ('Sample Shimla', 'sample-shimla', 'North', 'Sample hill destination', 'Sample destination copy', true, 'published', 1),
  ('Sample Jaipur', 'sample-jaipur', 'North', 'Sample desert destination', 'Sample destination copy', true, 'published', 2),
  ('Sample Kerala', 'sample-kerala', 'South', 'Sample coastal destination', 'Sample destination copy', false, 'draft', 3),
  ('Sample Goa', 'sample-goa', 'West', 'Sample beach destination', 'Sample destination copy', false, 'archived', 4)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.content_faqs (question, answer, sort_order, status)
VALUES
  ('Sample FAQ', 'This is sample answer content.', 1, 'published'),
  ('Draft FAQ', 'This should stay hidden.', 2, 'draft')
ON CONFLICT DO NOTHING;

INSERT INTO public.content_testimonials (author_name, author_location, quote, rating, sort_order, status)
VALUES
  ('Sample Traveller', 'Bengaluru', 'Sample testimonial text.', 5, 1, 'published'),
  ('Sample Reviewer', 'Delhi', 'Draft rating copy.', 4, 2, 'draft')
ON CONFLICT DO NOTHING;

INSERT INTO public.content_gallery (title, image_path, alt_text, sort_order, status)
VALUES
  ('Sample gallery image', '/images/sample-1.jpg', 'Sample destination image', 1, 'published'),
  ('Draft gallery image', '/images/sample-2.jpg', 'Hidden draft image', 2, 'draft')
ON CONFLICT DO NOTHING;

INSERT INTO public.content_banners (title, subtitle, cta_label, cta_url, image_path, sort_order, status)
VALUES
  ('Sample Banner', 'Explore journeys', 'View trips', '/trips', '/images/banner.jpg', 1, 'published'),
  ('Draft Banner', 'Hidden copy', 'Read more', '/about', '/images/draft.jpg', 2, 'draft')
ON CONFLICT DO NOTHING;
