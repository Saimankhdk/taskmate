import 'package:capstone_project/models/upload_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UploadBatchResult computes retryable failures and counters', () {
    final retryableFile = PlatformFile(
      name: 'retry.txt',
      size: 10,
      bytes: null,
      readStream: null,
    );
    final nonRetryableFile = PlatformFile(
      name: 'no-retry.txt',
      size: 12,
      bytes: null,
      readStream: null,
    );

    final result = UploadBatchResult(
      attemptedCount: 2,
      uploadedEntries: const [],
      failedEntries: [
        FileUploadFailure(
          sourceFile: retryableFile,
          reason: 'temporary',
          retryable: true,
        ),
        FileUploadFailure(
          sourceFile: nonRetryableFile,
          reason: 'permanent',
          retryable: false,
        ),
      ],
    );

    expect(result.attemptedCount, 2);
    expect(result.uploadedCount, 0);
    expect(result.failedCount, 2);
    expect(result.hasFailures, isTrue);
    expect(result.retryableFiles.length, 1);
    expect(result.retryableFiles.first.name, 'retry.txt');
  });
}
