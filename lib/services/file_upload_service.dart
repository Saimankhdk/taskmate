import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../models/upload_models.dart';

typedef UploadProgressCallback = void Function(String fileKey, double progress);

class FileUploadService {
  final FirebaseFirestore? firestore;
  final FirebaseStorage? storage;
  final Random _rng;

  FileUploadService({
    this.firestore,
    this.storage,
    Random? random,
  }) : _rng = random ?? Random();

  Future<UploadBatchResult> uploadFiles({
    required List<PlatformFile> files,
    required String ownerUid,
    String? groupId,
    String? chatId,
    UploadProgressCallback? onProgress,
  }) async {
    final normalizedGroupId = (groupId != null && groupId.trim().isNotEmpty)
        ? groupId.trim()
        : null;
    final normalizedChatId = (chatId != null && chatId.trim().isNotEmpty)
        ? chatId.trim()
        : null;

    final uploaded = <UploadedFileEntry>[];
    final failed = <FileUploadFailure>[];

    for (final file in files) {
      final fileKey = '${file.name}_${file.size}';
      try {
        final entry = await _uploadSingle(
          file: file,
          ownerUid: ownerUid,
          groupId: normalizedGroupId,
          chatId: normalizedChatId,
          fileKey: fileKey,
          onProgress: onProgress,
        );
        uploaded.add(entry);
      } on _UploadServiceException catch (e) {
        failed.add(
          FileUploadFailure(
            sourceFile: file,
            reason: e.message,
            retryable: e.retryable,
          ),
        );
        onProgress?.call(fileKey, 0);
      } catch (e) {
        failed.add(
          FileUploadFailure(
            sourceFile: file,
            reason: 'Unexpected upload error: $e',
            retryable: file.bytes != null,
          ),
        );
        onProgress?.call(fileKey, 0);
      }
    }

    return UploadBatchResult(
      attemptedCount: files.length,
      uploadedEntries: uploaded,
      failedEntries: failed,
    );
  }

  Future<UploadedFileEntry> _uploadSingle({
    required PlatformFile file,
    required String ownerUid,
    required String? groupId,
    required String? chatId,
    required String fileKey,
    UploadProgressCallback? onProgress,
  }) async {
    final source = await _resolveSource(file);
    if (source == null) {
      final hasBytes = file.bytes != null;
      final hasPath = (file.path ?? '').trim().isNotEmpty;
      final hasReadStream = file.readStream != null;
      throw _UploadServiceException(
        'Could not read ${file.name}. '
        '(bytes:$hasBytes path:$hasPath stream:$hasReadStream) '
        'Try selecting it again.',
        retryable: false,
      );
    }

    final originalName = file.name.trim().isNotEmpty
        ? file.name.trim()
        : 'file';
    final safeName = _safeFileName(originalName);
    final ext = safeName.contains('.')
        ? safeName.split('.').last.toLowerCase()
        : '';
    final category = _autoCategoryFromExt(ext);
    final mimeType =
        lookupMimeType(safeName, headerBytes: file.bytes ?? const <int>[]) ??
        'application/octet-stream';
    final storagePath = [
      'uploads',
      ownerUid,
      if (groupId != null) 'groups/$groupId',
      if (chatId != null) 'chats/$chatId',
      '${DateTime.now().microsecondsSinceEpoch}_${_rng.nextInt(2147483647)}_$safeName',
    ].join('/');
    final ref = _storage.ref(storagePath);

    String? url;
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final task = source.createTask(
          ref: ref,
          metadata: SettableMetadata(contentType: mimeType),
        );
        task.snapshotEvents.listen((snapshot) {
          final total = snapshot.totalBytes;
          if (total > 0) {
            onProgress?.call(fileKey, snapshot.bytesTransferred / total);
          }
        });
        final snap = await task;
        url = await snap.ref.getDownloadURL();
        break;
      } on FirebaseException catch (e) {
        if (attempt == 2) {
          throw _UploadServiceException(
            _friendlyStorageError(file.name, e),
            retryable: source.isRetryable && _isStorageRetryable(e),
          );
        }
      } catch (_) {
        if (attempt == 2) {
          throw _UploadServiceException(
            'Upload failed for ${file.name}. Check your connection and try again.',
            retryable: source.isRetryable,
          );
        }
      }
    }

    if (url == null) {
      throw _UploadServiceException(
        'Upload failed for ${file.name}.',
        retryable: source.isRetryable,
      );
    }

    try {
      final docRef = await _firestore.collection('files').add({
        'ownerUid': ownerUid,
        'name': safeName,
        'ext': ext,
        'size': file.size,
        'mimeType': mimeType,
        'category': category,
        'url': url,
        'storagePath': storagePath,
        'groupId': groupId,
        'chatId': chatId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      onProgress?.call(fileKey, 1);
      return UploadedFileEntry(
        sourceFile: file,
        fileDocId: docRef.id,
        storagePath: storagePath,
        downloadUrl: url,
        fileName: safeName,
        fileSize: file.size,
      );
    } on FirebaseException catch (e) {
      // Keep Storage and Firestore consistent if metadata write fails.
      await ref.delete().catchError((_) {});
      throw _UploadServiceException(
        _friendlyFirestoreError(file.name, e),
        retryable: _isFirestoreRetryable(e),
      );
    } catch (_) {
      // Keep Storage and Firestore consistent if metadata write fails.
      await ref.delete().catchError((_) {});
      throw _UploadServiceException(
        'Uploaded ${file.name} but failed to save metadata. File rolled back safely.',
        retryable: true,
      );
    }
  }

  Future<_UploadSource?> _resolveSource(PlatformFile file) async {
    if (file.bytes != null) {
      return _BytesUploadSource(file.bytes!);
    }
    final path = file.path;
    if (path != null && path.trim().isNotEmpty) {
      try {
        final bytes = await XFile(_normalizeFilePath(path)).readAsBytes();
        if (bytes.isNotEmpty) {
          return _BytesUploadSource(bytes);
        }
      } catch (_) {
        // Fall back to stream if path read is unavailable.
      }
    }
    final stream = file.readStream;
    if (stream != null) {
      final chunks = <int>[];
      try {
        await for (final chunk in stream) {
          chunks.addAll(chunk);
        }
        if (chunks.isNotEmpty) {
          return _BytesUploadSource(Uint8List.fromList(chunks));
        }
      } catch (_) {
        // Ignore and return null below.
      }
    }
    return null;
  }

  String _normalizeFilePath(String rawPath) {
    final trimmed = rawPath.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'file') {
      try {
        return uri.toFilePath();
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  bool _isStorageRetryable(FirebaseException e) {
    switch (e.code) {
      case 'retry-limit-exceeded':
      case 'canceled':
      case 'unknown':
      case 'quota-exceeded':
        return true;
      case 'permission-denied':
      case 'unauthorized':
      case 'unauthenticated':
      case 'object-not-found':
      case 'bucket-not-found':
      case 'project-not-found':
      case 'invalid-checksum':
      case 'invalid-argument':
      case 'no-default-bucket':
        return false;
      default:
        return true;
    }
  }

  bool _isFirestoreRetryable(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
      case 'unauthenticated':
      case 'invalid-argument':
      case 'failed-precondition':
        return false;
      default:
        return true;
    }
  }

  String _friendlyStorageError(String fileName, FirebaseException e) {
    final msg = (e.message ?? '').trim();
    switch (e.code) {
      case 'permission-denied':
      case 'unauthorized':
      case 'unauthenticated':
        return 'Upload blocked by Firebase Storage rules for $fileName. '
            'Please sign in and confirm Storage rules allow writes to your uploads path.';
      case 'no-default-bucket':
      case 'bucket-not-found':
      case 'project-not-found':
        return 'Upload failed: Firebase Storage bucket is not configured correctly (${e.code}).';
      case 'retry-limit-exceeded':
      case 'quota-exceeded':
        return 'Upload temporarily failed for $fileName (${e.code}). Try again in a moment.';
      default:
        return msg.isEmpty
            ? 'Upload failed for $fileName (${e.code}).'
            : 'Upload failed for $fileName (${e.code}): $msg';
    }
  }

  String _friendlyFirestoreError(String fileName, FirebaseException e) {
    final msg = (e.message ?? '').trim();
    switch (e.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return 'Uploaded $fileName but could not save metadata due to Firestore rules (${e.code}). '
            'File was rolled back safely.';
      default:
        return msg.isEmpty
            ? 'Uploaded $fileName but metadata save failed (${e.code}). File was rolled back safely.'
            : 'Uploaded $fileName but metadata save failed (${e.code}): $msg. '
                  'File was rolled back safely.';
    }
  }

  String _autoCategoryFromExt(String ext) {
    final e = ext.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(e)) {
      return 'Images';
    }
    if (e == 'pdf') return 'PDFs';
    if (['doc', 'docx', 'rtf'].contains(e)) return 'Word Docs';
    if (['mp4', 'mov', 'mkv', 'webm'].contains(e)) return 'Videos';
    return 'Important';
  }

  String _safeFileName(String raw) {
    final sanitized = raw
        .replaceAll(RegExp(r'[^a-zA-Z0-9._ -]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sanitized.isEmpty ? 'file' : sanitized;
  }

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => storage ?? FirebaseStorage.instance;
}

class _UploadServiceException implements Exception {
  final String message;
  final bool retryable;

  _UploadServiceException(this.message, {required this.retryable});
}

abstract class _UploadSource {
  bool get isRetryable;

  UploadTask createTask({
    required Reference ref,
    required SettableMetadata metadata,
  });
}

class _BytesUploadSource implements _UploadSource {
  final Uint8List bytes;

  _BytesUploadSource(this.bytes);

  @override
  bool get isRetryable => true;

  @override
  UploadTask createTask({
    required Reference ref,
    required SettableMetadata metadata,
  }) {
    return ref.putData(bytes, metadata);
  }
}
