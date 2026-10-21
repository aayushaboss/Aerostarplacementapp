import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/mock_auth_repository.dart';
import '../mockData/mock_applications.dart' show setApplicationsUser;
import '../models/user.dart';

/// Mirrors frontend/src/context/AuthContext.tsx.
/// Provider + shared_preferences so segment/user/onboarding progress
/// survive an app restart, not just in-app navigation.
///
/// Owns the current session only (token + cached profile) — every identity
/// operation that would actually hit a server (OTP, Google sign-in, profile
/// updates) is delegated to [_authRepository]; see AuthRepository/
/// MockAuthRepository in lib/data/repositories/.
class AppState extends ChangeNotifier {
  static const _tokenKey = 'aerostar_access_token';
  static const _demoUserKey = 'aerostar_demo_user';
  static const _savedOpportunitiesKey = 'saved_opportunities';
  static const _viewedStoriesKey = 'viewed_skill_stories';
  static const _readNotificationsKey = 'read_notifications';

  final AuthRepository _authRepository;
  AppState({AuthRepository? authRepository}) : _authRepository = authRepository ?? MockAuthRepository();

  /// DEV-ONLY toggle: while true, every fresh app load starts signed out so
  /// onboarding can be retested end-to-end on every refresh. MockAuthRepository's
  /// accounts map (used by the "I already have an account" returning-user
  /// path) is left intact either way, so that path still works when
  /// explicitly testing it via login. Flip to false to restore normal
  /// session persistence across app restarts.
  static const _devAlwaysStartSignedOut = false;

  User? _user;
  bool _loading = true;
  List<String> _savedOpportunityIds = [];
  List<String> _viewedStoryIds = [];
  List<String> _readNotificationIds = [];

  // Ephemeral, in-memory only (not persisted) — set right as
  // onboarding_complete_screen.dart hands off to Home, consumed exactly
  // once by whichever Home screen builds first, so the very first Home
  // arrival can read differently from every visit after it without
  // needing a real "first login ever" concept on the User model.
  bool _justOnboarded = false;
  void markJustOnboarded() => _justOnboarded = true;
  bool consumeJustOnboarded() {
    final was = _justOnboarded;
    _justOnboarded = false;
    return was;
  }

  User? get user => _user;
  bool get loading => _loading;
  List<String> get savedOpportunityIds => List.unmodifiable(_savedOpportunityIds);

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _savedOpportunityIds = prefs.getStringList(_savedOpportunitiesKey) ?? [];
    _viewedStoryIds = prefs.getStringList(_viewedStoriesKey) ?? [];
    _readNotificationIds = prefs.getStringList(_readNotificationsKey) ?? [];

    if (_devAlwaysStartSignedOut) {
      await prefs.remove(_tokenKey);
      await prefs.remove(_demoUserKey);
      _setUser(null);
      _loading = false;
      notifyListeners();
      return;
    }

    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      _setUser(null);
      _loading = false;
      notifyListeners();
      return;
    }
    final identifier = token.startsWith('demo:') ? token.substring(5) : 'guest';
    // This recovery fallback only runs when the primary session cache
    // (_demoUserKey) is already gone — see AuthRepository.findAccountByIdentifier's
    // own doc comment for why this is mock-shaped rather than how a real
    // backend would resolve it.
    final saved = await _loadSessionUser(prefs) ?? await _authRepository.findAccountByIdentifier(identifier);
    if (saved == null) {
      // A token with no recoverable profile anywhere = a stale/tampered
      // token. Clear it and start signed out rather than fabricating a
      // blank user (which used to drop straight into onboarding with a
      // half-real identity).
      await prefs.remove(_tokenKey);
      _setUser(null);
    } else {
      _setUser(saved);
    }
    _loading = false;
    notifyListeners();
  }

  /// Bumped whenever mock data mutates outside of AppState's own fields
  /// (an application deleted/restored, a booking created/cancelled/
  /// rescheduled) — a generic "something a kept-alive tab's cached state
  /// depends on just changed elsewhere" signal, distinct from [refresh]
  /// (which re-reads session/user state specifically). Screens that derive
  /// their view from listApplications()/listBookings() etc. should
  /// `context.watch<AppState>()` and re-run their own load on change,
  /// since StatefulShellRoute.indexedStack keeps every tab's State alive
  /// and nothing else tells a backgrounded tab its data is stale.
  int _dataVersion = 0;
  int get dataVersion => _dataVersion;
  void bumpDataVersion() {
    _dataVersion++;
    notifyListeners();
  }

  // In-memory only, not persisted — a lightweight "you were applying to
  // X" reminder for the resume gate's "Not now" dismiss, not a durable
  // cross-session record. Set when the user backs out of the gate sheet
  // without finishing their resume; cleared once they act on the
  // reminder or start a genuinely different apply flow.
  String? _pendingApplyOpportunityId;
  String? get pendingApplyOpportunityId => _pendingApplyOpportunityId;
  void setPendingApplyOpportunity(String? id) {
    if (_pendingApplyOpportunityId == id) return;
    _pendingApplyOpportunityId = id;
    notifyListeners();
  }

  bool isOpportunitySaved(String id) => _savedOpportunityIds.contains(id);

  Future<void> toggleSavedOpportunity(String id) async {
    _savedOpportunityIds = _savedOpportunityIds.contains(id)
        ? _savedOpportunityIds.where((x) => x != id).toList()
        : [..._savedOpportunityIds, id];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedOpportunitiesKey, _savedOpportunityIds);
  }

  bool isNotificationRead(String id) => _readNotificationIds.contains(id);

  /// True once every notification in [ids] has been marked read — used to
  /// drive the Home bell's unread dot from real state instead of a
  /// hardcoded `unread: true`.
  bool hasUnreadNotifications(List<String> ids) =>
      ids.any((id) => !_readNotificationIds.contains(id));

  /// Marks every id in [ids] read in one batch — called when the
  /// Notifications screen opens, mirroring how markStoryViewed marks a
  /// single story read on open, just bulked since a whole list is shown
  /// at once here rather than one story at a time.
  Future<void> markNotificationsRead(List<String> ids) async {
    final newlyRead = ids.where((id) => !_readNotificationIds.contains(id));
    if (newlyRead.isEmpty) return;
    _readNotificationIds = [..._readNotificationIds, ...newlyRead];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readNotificationsKey, _readNotificationIds);
  }

  bool isStoryViewed(String id) => _viewedStoryIds.contains(id);

  /// Instagram-style: opening a story is enough to mark it viewed, whether
  /// or not the user answers every question.
  Future<void> markStoryViewed(String id) async {
    if (_viewedStoryIds.contains(id)) return;
    _viewedStoryIds = [..._viewedStoryIds, id];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_viewedStoriesKey, _viewedStoryIds);
  }

  /// The one place `_user` is assigned — keeps the applications store
  /// scoped to whoever's signed in (so one account never sees another's
  /// applications, and a fresh signup starts with an empty tab). Callers
  /// still `notifyListeners()` themselves.
  void _setUser(User? u) {
    _user = u;
    setApplicationsUser(u?.id);
  }

  /// Caches the current session's profile locally only — the "accounts
  /// directory" itself (what makes a profile resumable across sign-outs) is
  /// AuthRepository's concern now, see MockAuthRepository.
  Future<void> _persistSessionUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_demoUserKey, jsonEncode(user.toJson()));
  }

  Future<User?> _loadSessionUser(SharedPreferences prefs) async {
    final raw = prefs.getString(_demoUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('AppState: corrupted $_demoUserKey, treating as signed out — $e');
      return null;
    }
  }

  Future<void> requestOtp(String identifier) => _authRepository.requestOtp(identifier);

  /// returning=true → existing-account login; skip onboarding if no saved profile yet (prototype).
  Future<User> verifyOtp(String identifier, String code, {bool returning = false}) async {
    // Throws (otp_expired / otp_invalid) before anything below runs — see
    // AuthRepository.verifyOtp / MockAuthRepository.
    final next = await _authRepository.verifyOtp(identifier, code, returning: returning);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, 'demo:$identifier');
    await _persistSessionUser(next);
    _setUser(next);
    notifyListeners();
    return next;
  }

  /// Prototype stand-in for "Continue with Google" — a real integration
  /// would hand back a verified name/email instantly, no OTP step.
  /// Segment, college/class, and everything else Google wouldn't actually
  /// know still gets asked on the profile screen right after.
  ///
  /// Deliberately always starts a fresh, blank onboarding — never resumes
  /// a previously-saved profile for this identity, even if one exists.
  /// An earlier version of this method resumed an already-onboarded
  /// account instead, but per direct, explicit instruction every tap of
  /// "Continue with Google" must go through the full onboarding flow.
  Future<User> mockGoogleSignIn() async {
    final next = await _authRepository.googleSignIn();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, 'demo:${next.identifier}');
    await _persistSessionUser(next);
    _setUser(next);
    notifyListeners();
    return next;
  }

  Future<User> updateProfile(User Function(User current) patch) async {
    final current = _user;
    if (current == null) {
      // Every real caller runs with a signed-in user (onboarding, profile
      // edit, resume build, career-quiz submit/unlock — all router-gated).
      // Fabricating a tokenless "demo-guest" here just silently corrupts
      // state; fail loudly instead.
      throw StateError('updateProfile called with no signed-in user');
    }
    final updated = await _authRepository.updateProfile(current, patch);
    _setUser(updated);
    await _persistSessionUser(updated);
    notifyListeners();
    return updated;
  }

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      // Signed out — possibly from another tab. Only notify if this tab
      // actually had a user in memory, so a refresh before first sign-in
      // isn't a no-op churn of listeners.
      if (_user != null) {
        _setUser(null);
        notifyListeners();
      }
      return;
    }
    final saved = await _loadSessionUser(prefs);
    if (saved != null) {
      _setUser(saved);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // Keep the profile in MockAuthRepository's accounts map so the same
    // phone/email can log back in without re-doing onboarding.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_demoUserKey);
    // Per-account state that would otherwise leak into whoever signs in
    // next on this browser: saved jobs, read-notification state, viewed
    // stories, and the in-memory "you were applying to X" reminder.
    _savedOpportunityIds = [];
    _viewedStoryIds = [];
    _readNotificationIds = [];
    _pendingApplyOpportunityId = null;
    await prefs.remove(_savedOpportunitiesKey);
    await prefs.remove(_viewedStoriesKey);
    await prefs.remove(_readNotificationsKey);
    _setUser(null);
    notifyListeners();
  }
}
