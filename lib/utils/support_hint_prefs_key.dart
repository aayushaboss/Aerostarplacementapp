/// SharedPreferences key for whether the Profile tab's "Support & Help" row
/// has already had its one-time discovery badge seen/dismissed. Mirrors
/// `applications_swipe_hint_prefs_key.dart`'s exact shape — "Support &
/// Help" was re-enabled in Round U after being fully absent, so it has zero
/// prior exposure to any user; this is a single targeted hint pointing at
/// it, not a general tour system.
const supportHintSeenPrefsKey = 'support_hint_seen';
