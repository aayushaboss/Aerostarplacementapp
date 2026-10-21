// Prototype mock data — delete when real recruiter-analytics API is wired.
import '../models/user.dart';

// Masked to 31 bits at every step, not just at the end — on web (dart2js),
// `int` is backed by a JS `number`, which loses precision past 2^53.
// Folding `hash * 31 + codeUnit` over a 20+ character email/identifier
// blows past that well before the loop finishes, and the resulting
// imprecise value collapses toward suspiciously round numbers under `%
// max` (a whole day's worth of counts silently landing on 0 is exactly
// that). Masking after every multiply keeps the running value inside the
// safe-integer range for both web and native the entire way through.
int _seeded(String seed, int salt, int max) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7FFFFFFF;
  }
  hash = (hash + salt) & 0x7FFFFFFF;
  return hash % max;
}

const _activityCompanies = [
  'Zerodha', 'Razorpay', 'Flipkart', 'Swiggy',
  'PhonePe', 'Zomato', 'OYO', 'Lenskart',
  'Groww', 'Meesho', 'Zepto', 'CRED',
];

const _actionTypes = [
  'Viewed your profile',
  'Downloaded your resume',
  'Shortlisted you',
  'Saved your profile',
];

class SearchAppearance {
  final DateTime date;
  final int count;
  const SearchAppearance({required this.date, required this.count});
}

/// Daily search-appearance counts for the last 14 days — how many recruiter
/// searches this profile turned up in, mirroring Naukri's own "Search
/// Appearances" trend chart instead of leaving it as a bare number nobody
/// can drill into.
List<SearchAppearance> searchAppearancesFor(User? user) {
  final seed = user?.identifier ?? 'guest';
  final now = DateTime.now();
  return List.generate(14, (i) {
    final date = now.subtract(Duration(days: 13 - i));
    final count = _seeded(seed, i + 1, 6);
    return SearchAppearance(date: date, count: count);
  });
}

/// Search phrases that plausibly surfaced this profile — built from the
/// student's own interested roles/skills/city instead of a fixed list, so
/// it actually reflects who they are rather than reading as filler text.
List<String> searchKeywordsFor(User? user) {
  final roles = user?.roles ?? const <String>[];
  final skills = user?.resume?.skills ?? const <String>[];
  final city = user?.city;
  final keywords = <String>[];
  for (final r in roles.take(3)) {
    keywords.add(city != null && city.isNotEmpty ? '$r intern $city' : '$r intern');
  }
  for (final s in skills.take(3)) {
    keywords.add('$s developer');
  }
  if (keywords.isEmpty) keywords.add('Fresher ${city ?? ''}'.trim());
  return keywords.take(5).toList();
}

class RecruiterAction {
  final String company;
  final String action;
  final DateTime at;
  const RecruiterAction({required this.company, required this.action, required this.at});
}

/// Recruiter-attributed activity feed — "Company X viewed your profile"
/// style entries, mirroring Naukri's actual "Recruiter Actions" list
/// instead of a bare count with nowhere to see who.
List<RecruiterAction> recruiterActionsFor(User? user) {
  final seed = user?.identifier ?? 'guest';
  final now = DateTime.now();
  final count = 3 + _seeded(seed, 99, 6);
  return List.generate(count, (i) {
    final company = _activityCompanies[_seeded(seed, i * 3 + 1, _activityCompanies.length)];
    final action = _actionTypes[_seeded(seed, i * 5 + 2, _actionTypes.length)];
    final at = now.subtract(Duration(days: _seeded(seed, i * 7 + 3, 21), hours: _seeded(seed, i * 11 + 4, 24)));
    return RecruiterAction(company: company, action: action, at: at);
  })
    ..sort((a, b) => b.at.compareTo(a.at));
}
