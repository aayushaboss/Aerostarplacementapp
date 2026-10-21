/// Shared narrative helpers for Career DNA copy — used by both the
/// downloadable PDF (career_dna_report_pdf.dart) and the on-screen compact
/// trait-summary card (career_dna_trait_summary.dart), so both draw from
/// the exact same generated sentences rather than two copies that could
/// drift apart. Extracted verbatim from career_dna_report_pdf.dart's own
/// former private `_firstSentence`/`_narrativeSentences`/`_joinList` — pure
/// extraction, output is byte-identical to before.
library;

/// The opening sentence only, e.g. "You're a builder." from "You're a
/// builder. You value follow-through."
String firstSentence(String text) {
  final match = RegExp(r'^.*?[.!?](?=\s|$)').firstMatch(text);
  return match?.group(0) ?? text;
}

/// Top 3 dimensions named plainly as strengths, bottom 2 framed as still
/// developing, no numbers anywhere, second person throughout, kept as two
/// separate sentences so callers can render them as distinct paragraphs.
(String, String) narrativeSentences(Map<String, int> scores, Map<String, String> phrases) {
  final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final strengths = sorted.take(3).map((e) => phrases[e.key] ?? e.key).toList();
  final growing = sorted.reversed.take(2).map((e) => phrases[e.key] ?? e.key).toList();

  final strengthsSentence = 'Looking at how you actually answered, your standout strengths are ${joinList(strengths)} — these come through clearly and are genuinely worth leaning into.';
  final growingSentence = "You're still growing into ${joinList(growing)} — with a bit of intentional practice, that's real room to build, not something holding you back.";
  return (strengthsSentence, growingSentence);
}

String joinList(List<String> items) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items.first;
  return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}
