import 'package:file_picker/file_picker.dart';

class UploadedFileEntry {
  final PlatformFile sourceFile;
  final String fileDocId;
  final String storagePath;
  final String downloadUrl;
  final String fileName;
  final int fileSize;

  UploadedFileEntry({
    required this.sourceFile,
    required this.fileDocId,
    required this.storagePath,
    required this.downloadUrl,
    required this.fileName,
    required this.fileSize,
  });
}

class FileUploadFailure {
  final PlatformFile sourceFile;
  final String reason;
  final bool retryable;

  FileUploadFailure({
    required this.sourceFile,
    required this.reason,
    required this.retryable,
  });
}

class UploadBatchResult {
  final int attemptedCount;
  final List<UploadedFileEntry> uploadedEntries;
  final List<FileUploadFailure> failedEntries;

  UploadBatchResult({
    required this.attemptedCount,
    required this.uploadedEntries,
    required this.failedEntries,
  });

  int get uploadedCount => uploadedEntries.length;
  int get failedCount => failedEntries.length;
  bool get hasFailures => failedEntries.isNotEmpty;
  bool get hasSuccesses => uploadedEntries.isNotEmpty;

  List<PlatformFile> get retryableFiles =>
      failedEntries.where((f) => f.retryable).map((f) => f.sourceFile).toList();
}
