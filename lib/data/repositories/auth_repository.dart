import '../../models/user.dart';

/// Identity operations AppState delegates to instead of hardcoding them
/// inline. AppState still owns session bootstrap, token persistence
/// (SharedPreferences) and notifyListeners() — this interface covers only
/// the parts that would actually hit a server: sending/checking an OTP,
/// Google sign-in, and persisting a profile edit.
abstract class AuthRepository {
  Future<void> requestOtp(String identifier);

  /// Throws on an invalid/expired code (mirrors the current AppState
  /// behavior — Exception('otp_invalid') / Exception('otp_expired')).
  /// [returning] mirrors AppState.verifyOtp: true resumes a saved profile
  /// for [identifier] if one exists, false always starts a fresh signup.
  Future<User> verifyOtp(String identifier, String code, {bool returning = false});

  Future<User> googleSignIn();

  Future<User> updateProfile(User current, User Function(User current) patch);

  /// AppState.bootstrap()'s recovery path when a session token exists but
  /// the local session cache is gone — mock-shaped (looks accounts up by
  /// identifier); a real backend would resolve this via the token itself
  /// against a `/me`-style endpoint instead, so HttpAuthRepository's
  /// implementation of this method is expected to go away once that's
  /// wired up, not be filled in as-is.
  Future<User?> findAccountByIdentifier(String identifier);
}
