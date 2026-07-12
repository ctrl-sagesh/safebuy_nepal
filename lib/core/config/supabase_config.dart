/// SafeBuy Nepal — Supabase configuration.
///
/// Hybrid cloud architecture: Firebase handles Auth + Firestore,
/// Supabase handles ALL file storage (Firebase Storage requires the
/// Blaze billing plan, which cannot be activated from Nepal due to
/// payment gateway restrictions — error OR_BACR2_44).
///
/// The anon key is a public client key (safe to ship in the binary);
/// access control is enforced by Supabase bucket policies.
library;

const String supabaseUrl = 'https://evcjvbtdlqnnfqdzougx.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2Y2p2YnRkbHFubmZxZHpvdWd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NTc1NjIsImV4cCI6MjA5OTQzMzU2Mn0.vcjxymiIzJ44bVyIzM2Kb3Rztocj25Gyp8WQ55-FnHg';

// ── Storage buckets ─────────────────────────────────────────────────────────
const String kycBucket = 'kyc-documents'; // private, 10MB
const String evidenceBucket = 'evidence-files'; // private, 10MB
const String reviewBucket = 'review-images'; // public, 5MB
const String qrBucket = 'qr-codes'; // public, 2MB
const String profileBucket = 'profile-images'; // public, 5MB
