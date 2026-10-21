import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mockData/mock_applications.dart' show demoShowcaseUserId;
import '../../models/user.dart';
import 'auth_repository.dart';

/// Extracted verbatim from AppState (which used to hardcode every one of
/// these behind a `// TODO: replace with real API call`) — behavior is
/// unchanged, just moved behind the AuthRepository seam. Owns the
/// SharedPreferences-backed "accounts directory" (`_usersMapKey`) that
/// simulates a real backend's user table; AppState itself only keeps the
/// current session's token + cached profile, which is a genuinely separate,
/// session-local concern.
class MockAuthRepository implements AuthRepository {
  static const _usersMapKey = 'aerostar_demo_users';

  /// Prototype stand-in for a real SMS/email-delivered code — fixed so
  /// testers have something predictable to type, rather than every code
  /// silently succeeding regardless of what's entered.
  static const demoOtpCode = '123456';
  static const _otpValidity = Duration(minutes: 5);

  String? _pendingOtpCode;
  DateTime? _otpSentAt;

  @override
  Future<void> requestOtp(String identifier) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _pendingOtpCode = demoOtpCode;
    _otpSentAt = DateTime.now();
  }

  @override
  Future<User> verifyOtp(String identifier, String code, {bool returning = false}) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final sentAt = _otpSentAt;
    if (sentAt == null || DateTime.now().difference(sentAt) > _otpValidity) {
      throw Exception('otp_expired');
    }
    if (code != _pendingOtpCode) {
      throw Exception('otp_invalid');
    }
    _pendingOtpCode = null;
    _otpSentAt = null;

    final prefs = await SharedPreferences.getInstance();
    User next;
    if (returning) {
      // Checks both the plain identifier key and the Google-namespaced one
      // (mirrors findAccountByIdentifier, used by AppState.bootstrap's own
      // recovery fallback) — "I already have an account" is the one place
      // this cross-namespace check is correct: the user is explicitly
      // asserting ownership of this identifier, so an account created via
      // Google using this same email should be found when logging back in
      // through the phone/email OTP path too.
      final saved = await _getSavedUser(prefs, identifier) ?? await _getSavedUser(prefs, 'google:$identifier');
      // Whether complete or still mid-onboarding, a genuinely saved profile
      // for this identifier is resumed as-is. Only when nothing is saved at
      // all do we fall through to a new signup.
      next = saved ?? _makeNewUser(identifier);
    } else {
      // New signup: always start fresh onboarding — do not reuse a previous completed profile.
      next = _makeNewUser(identifier);
    }
    await _persistToAccountsMap(prefs, next);
    return next;
  }

  /// Prototype stand-in for "Continue with Google" — a real integration
  /// would hand back a verified name/email instantly, no OTP step.
  /// Deliberately always starts a fresh, blank onboarding — never resumes a
  /// previously-saved profile for this identity (see AppState's original
  /// doc comment: every tap of "Continue with Google" must go through the
  /// full onboarding flow, per direct instruction).
  @override
  Future<User> googleSignIn() async {
    await Future.delayed(const Duration(milliseconds: 500));
    const identifier = 'aayusha.pagare@gmail.com';
    final next = User(
      // Stable id (not a per-login timestamp) so this account's
      // applications survive a re-login, and so it can own the seed
      // "showcase" applications — see demoShowcaseUserId's own doc comment.
      id: demoShowcaseUserId,
      identifier: identifier,
      signInMethod: 'google',
      name: 'Aayusha Pagare',
      onboardingComplete: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await _persistToAccountsMap(prefs, next);
    return next;
  }

  @override
  Future<User> updateProfile(User current, User Function(User current) patch) async {
    final updated = patch(current);
    final prefs = await SharedPreferences.getInstance();
    await _persistToAccountsMap(prefs, updated);
    return updated;
  }

  /// Used by AppState.bootstrap()'s recovery fallback, when the session
  /// cache is gone but the token implies a previously-signed-in identity —
  /// same cross-namespace lookup verifyOtp's own returning-login branch uses.
  @override
  Future<User?> findAccountByIdentifier(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    return await _getSavedUser(prefs, identifier) ?? await _getSavedUser(prefs, 'google:$identifier');
  }

  User _makeNewUser(String identifier) => User(
        id: 'demo-$identifier',
        identifier: identifier,
        signInMethod: 'otp',
        // A real email sign-in still hands back nothing but the address
        // itself — no verified name the way Google's OAuth would — but the
        // local-part is a reasonable, genuinely-real guess worth prefilling.
        name: _deriveNameFromEmail(identifier),
        city: null,
        // Phone sign-up's identifier already *is* the phone number.
        phone: identifier.contains('@') ? null : identifier,
        segment: null,
        onboardingComplete: false,
      );

  /// `aayusha.pagare@gmail.com` → `'Aayusha Pagare'`. Returns null for a
  /// non-email identifier (bare phone number) or an email with nothing
  /// usable before the @.
  String? _deriveNameFromEmail(String identifier) {
    final at = identifier.indexOf('@');
    if (at <= 0) return null;
    final localPart = identifier.substring(0, at);
    final words = localPart
        .split(RegExp(r'[._-]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase());
    final name = words.join(' ');
    return name.isEmpty ? null : name;
  }

  Future<Map<String, dynamic>> _loadUsersMap(SharedPreferences prefs) async {
    final raw = prefs.getString(_usersMapKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('MockAuthRepository: corrupted $_usersMapKey, starting from an empty map — $e');
      return {};
    }
  }

  Future<void> _saveUsersMap(SharedPreferences prefs, Map<String, dynamic> map) async {
    await prefs.setString(_usersMapKey, jsonEncode(map));
  }

  // Strictly a single, exact key — no namespace-crossing here, so that a
  // *new*-signup lookup can never accidentally "become" the fixed Google
  // demo account.
  Future<User?> _getSavedUser(SharedPreferences prefs, String identifier) async {
    final map = await _loadUsersMap(prefs);
    final raw = map[identifier];
    if (raw == null) return null;
    return User.fromJson(raw as Map<String, dynamic>);
  }

  // Google-created accounts are namespaced so typing that exact fixed demo
  // email into the OTP phone/email flow can never coincidentally load the
  // Google-created record.
  String _accountMapKey(User user) => user.signInMethod == 'google' ? 'google:${user.identifier}' : user.identifier;

  Future<void> _persistToAccountsMap(SharedPreferences prefs, User user) async {
    final map = await _loadUsersMap(prefs);
    map[_accountMapKey(user)] = user.toJson();
    await _saveUsersMap(prefs, map);
  }
}
