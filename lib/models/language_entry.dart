/// Mirrors Naukri's "Languages Known" entry — a name plus how well you
/// know it, not just a bare word. Matches this app's convention of plain
/// strings for fixed option sets (see JobPreferences.workMode) rather than
/// an enum, so the option list can live alongside the UI that offers it.
class LanguageEntry {
  final String name;
  final String proficiency;
  final bool isNative;

  const LanguageEntry({required this.name, required this.proficiency, this.isNative = false});

  Map<String, dynamic> toJson() => {'name': name, 'proficiency': proficiency, 'isNative': isNative};

  factory LanguageEntry.fromJson(Map<String, dynamic> json) => LanguageEntry(
        name: json['name'] as String? ?? '',
        proficiency: json['proficiency'] as String? ?? 'Intermediate',
        isNative: json['isNative'] as bool? ?? false,
      );
}
