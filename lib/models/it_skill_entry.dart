/// One IT skill/software entry — mirrors Naukri's "IT skills" accomplishment
/// (Skill/Software name, version, years+months of experience, last used).
class ITSkillEntry {
  final String name;
  final String? version;
  final String? experienceYears;
  final String? experienceMonths;
  final String? lastUsed;

  const ITSkillEntry({
    required this.name,
    this.version,
    this.experienceYears,
    this.experienceMonths,
    this.lastUsed,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'experienceYears': experienceYears,
        'experienceMonths': experienceMonths,
        'lastUsed': lastUsed,
      };

  factory ITSkillEntry.fromJson(Map<String, dynamic> json) => ITSkillEntry(
        name: json['name'] as String? ?? '',
        version: json['version'] as String?,
        experienceYears: json['experienceYears'] as String?,
        experienceMonths: json['experienceMonths'] as String?,
        lastUsed: json['lastUsed'] as String?,
      );
}
