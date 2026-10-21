/// Joins the last two words with a non-breaking space so short strings
/// (subtitles, captions, hints) never wrap leaving a single word alone on
/// its own line -- the browser/Flutter line-breaker can still wrap the
/// pair down together at any container width, it just can't split between
/// them. Safer than a hardcoded newline since it works at any screen size.
String noOrphan(String text) {
  const nbsp = ' ';
  final trimmed = text.trimRight();
  final lastSpace = trimmed.lastIndexOf(' ');
  if (lastSpace == -1) return text;
  return trimmed.substring(0, lastSpace) + nbsp + trimmed.substring(lastSpace + 1);
}
