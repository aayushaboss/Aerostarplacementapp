import 'dart:typed_data';

/// Resume PDF / profile photo uploads — not rewired into any screen this
/// pass (resume_screen.dart and profile_edit_screen.dart still hold bytes
/// locally, see BACKEND_API_CONTRACT.md), but the seam exists so that
/// follow-up work has a clear place to plug into rather than inventing one
/// from scratch.
abstract class UploadRepository {
  /// Returns a URL/reference to the uploaded file.
  Future<String> uploadResume(Uint8List bytes, String filename);
  Future<String> uploadProfilePhoto(Uint8List bytes, String filename);
}
