-- ═══════════════════════════════════════════════════════════════════
-- SafeBuy Nepal — Supabase Storage policies
-- Run manually in: Supabase Dashboard → SQL Editor
--
-- ⚠ READ THIS FIRST — WHICH OPTION TO RUN
--
-- SafeBuy Nepal authenticates users with FIREBASE (phone OTP /
-- Google), not Supabase Auth. That means every request the app makes
-- to Supabase uses the `anon` role — the `authenticated` role and
-- auth.uid() are NEVER populated.
--
--   • OPTION A (below) is the textbook per-user policy set. It only
--     works if users also sign in to Supabase. With this app's
--     Firebase-auth architecture it will BLOCK all uploads.
--   • OPTION B is the policy set that matches this app today.
--     RUN OPTION B.
--
-- Security note for Option B: uploads are allowed to holders of the
-- public anon key (i.e., the app). Protection comes from the bucket
-- file-size limits, MIME restrictions, private-bucket reads still
-- requiring signed URLs, and no UPDATE/DELETE policies (files are
-- immutable once uploaded). Per-user isolation can be added later by
-- minting Supabase JWTs from Firebase via an edge function.
-- ═══════════════════════════════════════════════════════════════════

-- Enable RLS on storage.objects (usually already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════════
-- OPTION A — per-user policies (requires Supabase Auth; NOT active
-- in the current Firebase-auth architecture — kept for documentation)
-- ═══════════════════════════════════════════════════════════════════

-- -- KYC Documents policies (private bucket)
-- CREATE POLICY "Users upload own KYC docs"
-- ON storage.objects FOR INSERT TO authenticated
-- WITH CHECK (
--   bucket_id = 'kyc-documents' AND
--   (storage.foldername(name))[1] = auth.uid()::text
-- );
--
-- CREATE POLICY "Users view own KYC docs"
-- ON storage.objects FOR SELECT TO authenticated
-- USING (
--   bucket_id = 'kyc-documents' AND
--   (storage.foldername(name))[1] = auth.uid()::text
-- );
--
-- -- Evidence Files policies (private bucket)
-- CREATE POLICY "Users upload own evidence"
-- ON storage.objects FOR INSERT TO authenticated
-- WITH CHECK (
--   bucket_id = 'evidence-files' AND
--   (storage.foldername(name))[1] = auth.uid()::text
-- );
--
-- CREATE POLICY "Users view own evidence"
-- ON storage.objects FOR SELECT TO authenticated
-- USING (
--   bucket_id = 'evidence-files' AND
--   (storage.foldername(name))[1] = auth.uid()::text
-- );
--
-- -- Review Images policies (public bucket)
-- CREATE POLICY "Public can view review images"
-- ON storage.objects FOR SELECT TO public
-- USING (bucket_id = 'review-images');
--
-- CREATE POLICY "Auth users upload review images"
-- ON storage.objects FOR INSERT TO authenticated
-- WITH CHECK (bucket_id = 'review-images');
--
-- -- QR Codes policies (public bucket)
-- CREATE POLICY "Public can view QR codes"
-- ON storage.objects FOR SELECT TO public
-- USING (bucket_id = 'qr-codes');
--
-- CREATE POLICY "Auth users upload QR codes"
-- ON storage.objects FOR INSERT TO authenticated
-- WITH CHECK (
--   bucket_id = 'qr-codes' AND
--   (storage.foldername(name))[1] = auth.uid()::text
-- );
--
-- -- Profile Images policies (public bucket)
-- CREATE POLICY "Public can view profile images"
-- ON storage.objects FOR SELECT TO public
-- USING (bucket_id = 'profile-images');
--
-- CREATE POLICY "Users upload own profile image"
-- ON storage.objects FOR INSERT TO authenticated
-- WITH CHECK (
--   bucket_id = 'profile-images' AND
--   (storage.foldername(name))[1] = auth.uid()::text
-- );

-- ═══════════════════════════════════════════════════════════════════
-- OPTION B — RUN THIS ONE (works with Firebase-authenticated app)
-- ═══════════════════════════════════════════════════════════════════

-- KYC Documents (private): app can upload; reads only via signed URLs
CREATE POLICY "App uploads KYC docs"
ON storage.objects FOR INSERT TO anon
WITH CHECK (bucket_id = 'kyc-documents');

-- Evidence Files (private): app can upload; reads only via signed URLs
CREATE POLICY "App uploads evidence"
ON storage.objects FOR INSERT TO anon
WITH CHECK (bucket_id = 'evidence-files');

-- Review Images (public bucket)
CREATE POLICY "Public can view review images"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'review-images');

CREATE POLICY "App uploads review images"
ON storage.objects FOR INSERT TO anon
WITH CHECK (bucket_id = 'review-images');

-- QR Codes (public bucket)
CREATE POLICY "Public can view QR codes"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'qr-codes');

CREATE POLICY "App uploads QR codes"
ON storage.objects FOR INSERT TO anon
WITH CHECK (bucket_id = 'qr-codes');

-- Profile Images (public bucket)
CREATE POLICY "Public can view profile images"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'profile-images');

CREATE POLICY "App uploads profile images"
ON storage.objects FOR INSERT TO anon
WITH CHECK (bucket_id = 'profile-images');

-- NOTE: no UPDATE or DELETE policies are created on purpose —
-- uploaded files are immutable from the client (fraud-evidence
-- integrity). Admins manage files from the Supabase dashboard.
