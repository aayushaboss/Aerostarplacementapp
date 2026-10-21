import 'dart:typed_data';

import 'upload_repository.dart';

/// No-op, matching today's actual behavior (bytes are held locally, never
/// uploaded anywhere) — returns a fake local reference rather than a real URL.
class MockUploadRepository implements UploadRepository {
  @override
  Future<String> uploadResume(Uint8List bytes, String filename) async => 'local://resume/$filename';

  @override
  Future<String> uploadProfilePhoto(Uint8List bytes, String filename) async => 'local://photo/$filename';
}
