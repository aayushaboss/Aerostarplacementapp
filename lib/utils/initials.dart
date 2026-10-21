/// Shared avatar-initials extraction — single source used everywhere a name
/// gets reduced to 1-2 letters (was three near-identical, slightly drifted
/// copies before).
String initialsFor(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return 'AE';
  // rune-based (not string-index) extraction so a leading emoji or other
  // surrogate-pair character isn't split in half; RegExp split collapses
  // repeated/irregular whitespace instead of producing empty parts.
  String firstChar(String s) => s.runes.isEmpty ? '' : String.fromCharCode(s.runes.first);
  final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'AE';
  final initials = firstChar(parts[0]) + (parts.length > 1 ? firstChar(parts[1]) : '');
  return initials.isEmpty ? 'AE' : initials.toUpperCase();
}
