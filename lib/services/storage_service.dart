import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/config/supabase_config.dart';

/// SafeBuy Nepal — file storage on Supabase.
///
/// Hybrid architecture: Firebase provides Auth + Firestore; Supabase
/// provides all file storage (Firebase Storage needs Blaze billing,
/// unavailable from Nepal — OR_BACR2_44).
///
/// Private buckets (kyc-documents, evidence-files) return 1-year signed
/// URLs; public buckets return permanent public URLs.
class StorageService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const _uuid = Uuid();

  // ─── COMPRESS IMAGE ─────────────────────────────────────────
  static Future<Uint8List> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 75,
      minWidth: 800,
      minHeight: 800,
    );
    return result ?? await file.readAsBytes();
  }

  // ─── KYC DOCUMENT UPLOAD ────────────────────────────────────
  static Future<String> uploadKycDocument({
    required File file,
    required String userId,
    required String docType,
  }) async {
    try {
      final bytes = await _compressImage(file);
      final fileName = '${docType}_${_uuid.v4()}.jpg';
      final filePath = '$userId/$fileName';

      await _client.storage.from(kycBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final signedUrl = await _client.storage
          .from(kycBucket)
          .createSignedUrl(filePath, 31536000);

      return signedUrl;
    } on StorageException catch (e) {
      throw Exception('KYC upload failed: ${e.message}');
    } catch (e) {
      throw Exception('KYC upload failed. Check your connection.');
    }
  }

  // ─── EVIDENCE UPLOAD ────────────────────────────────────────
  static Future<String> uploadEvidence({
    required File file,
    required String reportId,
    required String evidenceType,
    required String userId,
  }) async {
    try {
      final bytes = await _compressImage(file);
      final fileName = '${evidenceType}_${_uuid.v4()}.jpg';
      final filePath = '$userId/$reportId/$fileName';

      await _client.storage.from(evidenceBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final signedUrl = await _client.storage
          .from(evidenceBucket)
          .createSignedUrl(filePath, 31536000);

      return signedUrl;
    } on StorageException catch (e) {
      throw Exception('Evidence upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Evidence upload failed. Check your connection.');
    }
  }

  // ─── REVIEW IMAGE UPLOAD ────────────────────────────────────
  static Future<String> uploadReviewImage({
    required File file,
    required String reviewId,
  }) async {
    try {
      final bytes = await _compressImage(file);
      final fileName = 'review_${_uuid.v4()}.jpg';
      final filePath = '$reviewId/$fileName';

      await _client.storage.from(reviewBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      return _client.storage.from(reviewBucket).getPublicUrl(filePath);
    } on StorageException catch (e) {
      throw Exception('Review image upload failed: ${e.message}');
    } catch (e) {
      throw Exception(
          'Review image upload failed. Check your connection.');
    }
  }

  // ─── QR CODE UPLOAD ─────────────────────────────────────────
  static Future<String> uploadQrCode({
    required File file,
    required String sellerId,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = 'qr_${_uuid.v4()}.jpg';
      final filePath = '$sellerId/$fileName';

      await _client.storage.from(qrBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      return _client.storage.from(qrBucket).getPublicUrl(filePath);
    } on StorageException catch (e) {
      throw Exception('QR upload failed: ${e.message}');
    } catch (e) {
      throw Exception('QR upload failed. Check your connection.');
    }
  }

  // ─── PROFILE IMAGE UPLOAD ───────────────────────────────────
  static Future<String> uploadProfileImage({
    required File file,
    required String userId,
  }) async {
    try {
      final bytes = await _compressImage(file);
      final fileName = 'profile_${_uuid.v4()}.jpg';
      final filePath = '$userId/$fileName';

      await _client.storage.from(profileBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return _client.storage.from(profileBucket).getPublicUrl(filePath);
    } on StorageException catch (e) {
      throw Exception('Profile upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Profile upload failed. Check your connection.');
    }
  }

  // ─── DELETE FILE ────────────────────────────────────────────
  static Future<void> deleteFile({
    required String bucket,
    required String filePath,
  }) async {
    try {
      await _client.storage.from(bucket).remove([filePath]);
    } on StorageException catch (e) {
      throw Exception('Delete failed: ${e.message}');
    } catch (e) {
      throw Exception('Delete failed. Check your connection.');
    }
  }

  // ─── GET FRESH SIGNED URL ───────────────────────────────────
  static Future<String> getSignedUrl({
    required String bucket,
    required String filePath,
    int expiresInSeconds = 3600,
  }) async {
    try {
      return await _client.storage
          .from(bucket)
          .createSignedUrl(filePath, expiresInSeconds);
    } on StorageException catch (e) {
      throw Exception('URL generation failed: ${e.message}');
    } catch (e) {
      throw Exception('URL generation failed.');
    }
  }
}
