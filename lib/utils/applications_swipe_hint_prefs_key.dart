/// SharedPreferences key for whether the Applications tracker's "swipe a
/// card left to delete it" hint banner has already been shown. Mirrors
/// `fomo_prefs_key.dart`'s shape — its own doc comment scopes that key
/// specifically to the FOMO notification-permission nudge, so this concept
/// gets its own key rather than reusing that one.
const applicationsSwipeHintShownPrefsKey = 'applications_swipe_hint_shown';
