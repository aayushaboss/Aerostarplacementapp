/// Word-by-word search matching shared by the jobs and courses search.
///
/// A search like "marketing intern mumbai" used to look for that exact phrase inside a
/// single field, so it found nothing. Now each word must be found somewhere in the item
/// (title, company, city, type...), in any order, so it matches a Marketing Intern job in
/// Mumbai.
library;

/// Words that carry no meaning in a search ("jobs in Mumbai" is the same as "Mumbai").
const _stopWords = {'a', 'an', 'and', 'at', 'for', 'in', 'job', 'jobs', 'near', 'of', 'the', 'to', 'with'};

/// The meaningful words of [query], lower case. "Marketing Intern, Mumbai" becomes
/// [marketing, intern, mumbai]. Empty for a blank query.
List<String> searchTokens(String? query) {
  if (query == null) return const [];
  final words = query.toLowerCase().split(RegExp(r'[\s,;/|]+')).where((w) => w.isNotEmpty).toList();
  final meaningful = words.where((w) => !_stopWords.contains(w)).toList();
  // A query made only of stop words ("jobs") still searches for what was typed.
  return meaningful.isEmpty ? words : meaningful;
}

String _compact(String s) => s.replaceAll(RegExp(r'[\s\-_/]+'), '');

/// Trailing plural "s" removed ("internships" matches "Internship"), but not from short words.
String _stem(String w) => (w.length > 4 && w.endsWith('s') && !w.endsWith('ss')) ? w.substring(0, w.length - 1) : w;

/// Whether every word in [tokens] appears somewhere in [fields]. "full time" and
/// "fulltime" both match "Full-time".
bool matchesAllTokens(List<String> tokens, Iterable<String> fields) {
  if (tokens.isEmpty) return true;
  final haystack = fields.map((f) => f.toLowerCase()).join(' | ');
  final compactHaystack = _compact(haystack);
  for (final token in tokens) {
    final t = _stem(token);
    if (haystack.contains(t) || compactHaystack.contains(_compact(t))) continue;
    return false;
  }
  return true;
}

/// Points for a word found in the 1st, 2nd, 3rd... field given to [searchScore].
const _fieldWeights = [10, 6, 5, 3, 3, 2, 1, 1];

/// How well [fields] answer [tokens]: higher is better. [fields] are given most important
/// first (title, then company, then the rest); a word found in an earlier field scores more,
/// and a word at the start of a field scores a little more again.
int searchScore(List<String> tokens, List<String> fields) {
  var score = 0;
  for (final token in tokens) {
    final t = _stem(token);
    for (var i = 0; i < fields.length; i++) {
      final f = fields[i].toLowerCase();
      final at = f.indexOf(t);
      if (at < 0) continue;
      final weight = i < _fieldWeights.length ? _fieldWeights[i] : 1;
      score += weight + (at == 0 ? 2 : 0);
      break;
    }
  }
  return score;
}
