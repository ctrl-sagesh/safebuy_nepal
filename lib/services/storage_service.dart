import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

/// SafeBuy Nepal — file storage on Firebase Storage (Blaze plan).
///
/// Pure Firebase architecture: Auth, Firestore, Storage, and Cloud
/// Functions all run on Firebase. Storage paths mirror the deployed
/// storage.rules:
///   kyc/{userId}/…            (private — authenticated reads only)
///   evidence/{userId}/{reportId}/… (private)
///   review_images/{reviewId}/…     (public read)
///   qr_codes/{userId}/…            (public read)
///   profiles/{userId}/…            (public read)
///
/// All images are compressed (max 800px, quality 75) before upload.
class StorageService {
  static FirebaseStorage get _storage => FirebaseStorage.instance;
  static const _uuid = Uuid();

  // ─── COMPRESS IMAGE ─────────────────────────────────────────
  static Future<Uint8List> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: 75,
        minWidth: 800,
        minHeight: 800,
      );
      return result ?? await file.readAsBytes();
    } catch (_) {
      return file.readAsBytes();
    }
  }

  static Future<String> _upload({
    required String path,
    required Uint8List bytes,
    required String friendlyLabel,
  }) async {
    try {
      final ref = _storage.ref(path);
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception(
          '$friendlyLabel upload failed: ${e.message ?? 'storage error'}');
    } catch (_) {
      throw Exception(
          '$friendlyLabel upload failed. Check your connection.');
    }
  }

  // ─── KYC DOCUMENT UPLOAD ────────────────────────────────────
  /// [docType] is one of: selfie, citizenship, pan, location1-3.
  static Future<String> uploadKycDocument({
    required File file,
    required String userId,
    required String docType,
  }) async {
    final bytes = await _compressImage(file);
    return _upload(
      path: 'kyc/$userId/${docType}_${_uuid.v4()}.jpg',
      bytes: bytes,
      friendlyLabel: 'KYC',
    );
  }

  // ─── EVIDENCE UPLOAD ────────────────────────────────────────
  static Future<String> uploadEvidence({
    required File file,
    required String reportId,
    required String evidenceType,
    required String userId,
  }) async {
    final bytes = await _compressImage(file);
    return _upload(
      path: 'evidence/$userId/$reportId/${evidenceType}_${_uuid.v4()}.jpg',
      bytes: bytes,
      friendlyLabel: 'Evidence',
    );
  }

  // ─── REVIEW IMAGE UPLOAD ────────────────────────────────────
  static Future<String> uploadReviewImage({
    required File file,
    required String reviewId,
  }) async {
    final bytes = await _compressImage(file);
    return _upload(
      path: 'review_images/$reviewId/review_${_uuid.v4()}.jpg',
      bytes: bytes,
      friendlyLabel: 'Review image',
    );
  }

  // ─── QR CODE UPLOAD ─────────────────────────────────────────
  static Future<String> uploadQrCode({
    required File file,
    required String sellerId,
  }) async {
    final bytes = await file.readAsBytes();
    return _upload(
      path: 'qr_codes/$sellerId/qr_${_uuid.v4()}.jpg',
      bytes: bytes,
      friendlyLabel: 'QR',
    );
  }

  // ─── PROFILE IMAGE UPLOAD ───────────────────────────────────
  static Future<String> uploadProfileImage({
    required File file,
    required String userId,
  }) async {
    final bytes = await _compressImage(file);
    return _upload(
      path: 'profiles/$userId/profile_${_uuid.v4()}.jpg',
      bytes: bytes,
      friendlyLabel: 'Profile',
    );
  }

  // ─── DELETE FILE ────────────────────────────────────────────
  /// Deletes a file by its download URL. Note: storage rules block
  /// client deletes for evidence/KYC/QR (fraud-record integrity) —
  /// those throw a friendly error.
  static Future<void> deleteFile(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } on FirebaseException catch (e) {
      throw Exception('Delete failed: ${e.message ?? 'not permitted'}');
    } catch (_) {
      throw Exception('Delete failed. Check your connection.');
    }
  }
}
