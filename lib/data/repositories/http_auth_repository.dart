import '../../models/user.dart';
import '../api_client.dart';
import 'auth_repository.dart';

/// Not wired to anything real yet — see BACKEND_API_CONTRACT.md for the
/// intended endpoints. Every method throws until DataConfig.mode is
/// switched to http and these are filled in against a real base URL.
class HttpAuthRepository implements AuthRepository {
  final ApiClient client;
  const HttpAuthRepository(this.client);

  @override
  Future<void> requestOtp(String identifier) =>
      throw UnimplementedError('POST /auth/otp/request — see BACKEND_API_CONTRACT.md');

  @override
  Future<User> verifyOtp(String identifier, String code, {bool returning = false}) =>
      throw UnimplementedError('POST /auth/otp/verify — see BACKEND_API_CONTRACT.md');

  @override
  Future<User> googleSignIn() => throw UnimplementedError('POST /auth/google — see BACKEND_API_CONTRACT.md');

  @override
  Future<User> updateProfile(User current, User Function(User current) patch) =>
      throw UnimplementedError('PATCH /users/me — see BACKEND_API_CONTRACT.md');

  @override
  Future<User?> findAccountByIdentifier(String identifier) =>
      throw UnimplementedError('GET /users/me (token-based) — see BACKEND_API_CONTRACT.md');
}
