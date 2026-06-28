import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

class StorageService {
  FirebaseStorage? _storage;

  FirebaseStorage get storage {
    _storage ??= FirebaseStorage.instance;
    return _storage!;
  }

  /// Upload evidence image to Storage.
  /// Returns the download URL, or throws if Storage is not enabled.
  Future<String> uploadEvidence({
    required File file,
    required String reportId,
    required String evidenceType,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    // Validate file size
    final sizeBytes = await file.length();
    if (sizeBytes > AppConstants.maxFileSizeBytes) {
      throw Exception(
          'File size exceeds ${AppConstants.maxFileSizeMb}MB limit. Please compress the image and try again.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path =
        'evidence/$userId/$reportId/${evidenceType}_$timestamp.jpg';
    final ref = storage.ref(path);

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': userId,
          'reportId': reportId,
          'evidenceType': evidenceType,
        },
      ),
    );

    // Listen to progress
    uploadTask.snapshotEvents.listen((snapshot) {
      if (onProgress != null && snapshot.totalBytes > 0) {
        final progress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      }
    });

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Get download URL for a storage path.
  Future<String> getDownloadUrl(String path) async {
    return await storage.ref(path).getDownloadURL();
  }

  /// Evidence files cannot be deleted from client (security).
  Future<void> deleteEvidence(String path) async {
    throw UnsupportedError(
        'Evidence deletion is not permitted from the client. Contact admin.');
  }
}
