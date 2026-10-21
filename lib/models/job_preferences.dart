/// Backs the opportunity filter on college Home (`OpportunityFilterScreen`)
/// — everything here except roles/goal, which live on `User.roles`/
/// `User.goal` directly instead of a second, separately-capped copy (an
/// earlier version of this app duplicated roles here too, which meant a
/// user could set different roles in each place with no way to tell which
/// one the app was actually using — same reasoning kept this model's scope
/// narrow rather than widening it back out).
///
/// `expectedSalary` (Naukri-style "Career preferences" used to include it)
/// was dropped — it never actually narrowed the feed, and wasn't something
/// worth asking for on a filter meant to actually change what you see.
class JobPreferences {
  final List<String> cities;

  /// One of `Opportunity.workMode`'s real values (`Remote`/`Onsite`/
  /// `Hybrid`) — an earlier version of this field ("shift") used a
  /// different, mismatched vocabulary (`WFH`/`Hybrid`/`On-site`) that
  /// matched nothing on an actual `Opportunity`.
  final String? workMode;

  /// `Full-time`/`Part-time` — only ever meaningful for an `Opportunity`
  /// whose `type` is `'Full-time'`; every `Internship` has a null
  /// `employmentType`, so setting this while the Internship/Full-time
  /// facet is set to Internship correctly excludes everything rather than
  /// silently matching nothing for a confusing reason.
  final String? employmentType;

  const JobPreferences({
    this.cities = const [],
    this.workMode,
    this.employmentType,
  });

  bool get isEmpty => cities.isEmpty && workMode == null && employmentType == null;

  JobPreferences copyWith({
    List<String>? cities,
    String? workMode,
    String? employmentType,
  }) {
    return JobPreferences(
      cities: cities ?? this.cities,
      workMode: workMode ?? this.workMode,
      employmentType: employmentType ?? this.employmentType,
    );
  }

  Map<String, dynamic> toJson() => {
        'cities': cities,
        'workMode': workMode,
        'employmentType': employmentType,
      };

  factory JobPreferences.fromJson(Map<String, dynamic> json) => JobPreferences(
        cities: (json['cities'] as List?)?.cast<String>() ?? const [],
        workMode: json['workMode'] as String?,
        employmentType: json['employmentType'] as String?,
      );
}
