/// SharedPreferences key for the Courses tab's persisted recent-searches
/// list — mirrors search_screen.dart's own `_recentSearchesKey` (kept local
/// there since it has only that one consumer); this one gets its own
/// lib/utils file since it's introduced specifically to bring Courses to
/// parity with that existing pattern, matching the one-file-per-key
/// convention already used by the other prefs keys in this directory.
const recentCourseSearchesPrefsKey = 'recent_course_searches';
