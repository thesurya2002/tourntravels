CREATE POLICY "storage_avatar_select_owner" ON storage.objects
FOR SELECT TO authenticated USING (
  bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "storage_avatar_insert_owner" ON storage.objects
FOR INSERT TO authenticated WITH CHECK (
  bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "storage_avatar_update_owner" ON storage.objects
FOR UPDATE TO authenticated USING (
  bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
) WITH CHECK (
  bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "storage_avatar_delete_owner" ON storage.objects
FOR DELETE TO authenticated USING (
  bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "storage_avatar_select_staff" ON storage.objects
FOR SELECT TO authenticated USING (
  bucket_id = 'avatars' AND public.is_staff()
);

CREATE POLICY "storage_invoices_select_owner" ON storage.objects
FOR SELECT TO authenticated USING (
  bucket_id = 'invoices' AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "storage_catalogue_public_read" ON storage.objects
FOR SELECT TO anon, authenticated USING (
  bucket_id IN ('car-images', 'package-images', 'trip-images', 'destination-images', 'content-images')
);

CREATE POLICY "storage_catalogue_admin_write" ON storage.objects
FOR INSERT TO authenticated WITH CHECK (
  bucket_id IN ('car-images', 'package-images', 'trip-images', 'destination-images', 'content-images') AND public.is_admin()
);

CREATE POLICY "storage_catalogue_admin_update" ON storage.objects
FOR UPDATE TO authenticated USING (
  bucket_id IN ('car-images', 'package-images', 'trip-images', 'destination-images', 'content-images') AND public.is_admin()
) WITH CHECK (
  bucket_id IN ('car-images', 'package-images', 'trip-images', 'destination-images', 'content-images') AND public.is_admin()
);

CREATE POLICY "storage_catalogue_admin_delete" ON storage.objects
FOR DELETE TO authenticated USING (
  bucket_id IN ('car-images', 'package-images', 'trip-images', 'destination-images', 'content-images') AND public.is_admin()
);

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('car-images', 'car-images', true, 5242880, ARRAY['image/jpeg','image/png','image/webp']),
  ('package-images', 'package-images', true, 5242880, ARRAY['image/jpeg','image/png','image/webp']),
  ('trip-images', 'trip-images', true, 5242880, ARRAY['image/jpeg','image/png','image/webp']),
  ('destination-images', 'destination-images', true, 5242880, ARRAY['image/jpeg','image/png','image/webp']),
  ('content-images', 'content-images', true, 5242880, ARRAY['image/jpeg','image/png','image/webp']),
  ('avatars', 'avatars', false, 2097152, ARRAY['image/jpeg','image/png','image/webp']),
  ('invoices', 'invoices', false, 5242880, ARRAY['application/pdf'])
ON CONFLICT (id) DO NOTHING;
