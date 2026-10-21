import 'dart:typed_data';

import '../api_client.dart';
import 'upload_repository.dart';

/// Not wired to anything real yet — see BACKEND_API_CONTRACT.md.
class HttpUploadRepository implements UploadRepository {
  final ApiClient client;
  const HttpUploadRepository(this.client);

  @override
  Future<String> uploadResume(Uint8List bytes, String filename) =>
      throw UnimplementedError('POST /uploads/resume (multipart) — see BACKEND_API_CONTRACT.md');

  @override
  Future<String> uploadProfilePhoto(Uint8List bytes, String filename) =>
      throw UnimplementedError('POST /uploads/photo (multipart) — see BACKEND_API_CONTRACT.md');
}
