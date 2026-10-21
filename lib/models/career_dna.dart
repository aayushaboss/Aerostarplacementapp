import 'user.dart';

/// dimension slug -> 0-100, normalized. A plain typedef (not a class) since
/// every level scores a different, fixed set of dimension slugs and nothing
/// needs to be shared beyond the shape itself — mirrors how AptitudeMatch's
/// own scores are plain fields, not a wrapped type.
typedef DimensionScores = Map<String, int>;

/// Level 1's classification — one of 6, see career_dna_level1_data.dart's
/// classifier. Mirrors AptitudeMatch's shape (a small, self-contained value
/// class with its own toJson/fromJson) rather than inventing a new pattern.
class CareerDnaArchetype {
  final String id;
  final String name;
  final String naturalStyle;
  final String growthAreaTitle;
  final String growthAreaText;
  final List<String> strengths;
  final List<String> environments;

  const CareerDnaArchetype({
    required this.id,
    required this.name,
    required this.naturalStyle,
    required this.growthAreaTitle,
    required this.growthAreaText,
    required this.strengths,
    required this.environments,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'naturalStyle': naturalStyle,
        'growthAreaTitle': growthAreaTitle,
        'growthAreaText': growthAreaText,
        'strengths': strengths,
        'environments': environments,
      };

  factory CareerDnaArchetype.fromJson(Map<String, dynamic> json) => CareerDnaArchetype(
        id: json['id'] as String,
        name: json['name'] as String,
        naturalStyle: json['naturalStyle'] as String,
        growthAreaTitle: json['growthAreaTitle'] as String,
        growthAreaText: json['growthAreaText'] as String,
        strengths: (json['strengths'] as List).cast<String>(),
        environments: (json['environments'] as List).cast<String>(),
      );
}

class CareerDnaLevel1Result {
  final DimensionScores dimensionScores;
  final CareerDnaArchetype archetype;
  final String completedAt;

  const CareerDnaLevel1Result({required this.dimensionScores, required this.archetype, required this.completedAt});

  Map<String, dynamic> toJson() => {
        'dimensionScores': dimensionScores,
        'archetype': archetype.toJson(),
        'completedAt': completedAt,
      };

  factory CareerDnaLevel1Result.fromJson(Map<String, dynamic> json) => CareerDnaLevel1Result(
        dimensionScores: (json['dimensionScores'] as Map).cast<String, int>(),
        archetype: CareerDnaArchetype.fromJson(json['archetype'] as Map<String, dynamic>),
        completedAt: json['completedAt'] as String,
      );
}

class CareerDnaLevel2Result {
  final DimensionScores dimensionScores;
  final List<String> careerExplorationChain;
  final String headlineText;
  final String completedAt;

  const CareerDnaLevel2Result({
    required this.dimensionScores,
    required this.careerExplorationChain,
    required this.headlineText,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'dimensionScores': dimensionScores,
        'careerExplorationChain': careerExplorationChain,
        'headlineText': headlineText,
        'completedAt': completedAt,
      };

  factory CareerDnaLevel2Result.fromJson(Map<String, dynamic> json) => CareerDnaLevel2Result(
        dimensionScores: (json['dimensionScores'] as Map).cast<String, int>(),
        careerExplorationChain: (json['careerExplorationChain'] as List).cast<String>(),
        headlineText: json['headlineText'] as String,
        completedAt: json['completedAt'] as String,
      );
}

/// Level 3's classification — an authored set of 6 (the source doc gives 3
/// as illustrative examples only; see career_dna_level3_data.dart), not a
/// fixed enum baked into the model itself, so a profile's own copy is
/// stored alongside the result rather than re-derived from just an id.
class CareerDnaSocialProfile {
  final String id;
  final String name;
  final String naturalStrength;
  final String watchOut;
  final List<String> environments;

  const CareerDnaSocialProfile({
    required this.id,
    required this.name,
    required this.naturalStrength,
    required this.watchOut,
    required this.environments,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'naturalStrength': naturalStrength,
        'watchOut': watchOut,
        'environments': environments,
      };

  factory CareerDnaSocialProfile.fromJson(Map<String, dynamic> json) => CareerDnaSocialProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        naturalStrength: json['naturalStrength'] as String,
        watchOut: json['watchOut'] as String,
        environments: (json['environments'] as List).cast<String>(),
      );
}

class CareerDnaLevel3Result {
  final DimensionScores dimensionScores;
  final CareerDnaSocialProfile profile;
  final String completedAt;

  const CareerDnaLevel3Result({required this.dimensionScores, required this.profile, required this.completedAt});

  Map<String, dynamic> toJson() => {
        'dimensionScores': dimensionScores,
        'profile': profile.toJson(),
        'completedAt': completedAt,
      };

  factory CareerDnaLevel3Result.fromJson(Map<String, dynamic> json) => CareerDnaLevel3Result(
        dimensionScores: (json['dimensionScores'] as Map).cast<String, int>(),
        profile: CareerDnaSocialProfile.fromJson(json['profile'] as Map<String, dynamic>),
        completedAt: json['completedAt'] as String,
      );
}

class CareerDnaLevel4Result {
  final DimensionScores dimensionScores;
  final int overallReadiness;
  final String band; // highlyReady|workplaceReady|developingReadiness|preparationRequired
  final String workStyleTitle;
  final String workStyleText;
  final String developmentAreaTitle;
  final String developmentAreaText;
  final String completedAt;

  const CareerDnaLevel4Result({
    required this.dimensionScores,
    required this.overallReadiness,
    required this.band,
    required this.workStyleTitle,
    required this.workStyleText,
    required this.developmentAreaTitle,
    required this.developmentAreaText,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'dimensionScores': dimensionScores,
        'overallReadiness': overallReadiness,
        'band': band,
        'workStyleTitle': workStyleTitle,
        'workStyleText': workStyleText,
        'developmentAreaTitle': developmentAreaTitle,
        'developmentAreaText': developmentAreaText,
        'completedAt': completedAt,
      };

  factory CareerDnaLevel4Result.fromJson(Map<String, dynamic> json) => CareerDnaLevel4Result(
        dimensionScores: (json['dimensionScores'] as Map).cast<String, int>(),
        overallReadiness: json['overallReadiness'] as int,
        band: json['band'] as String,
        workStyleTitle: json['workStyleTitle'] as String,
        workStyleText: json['workStyleText'] as String,
        developmentAreaTitle: json['developmentAreaTitle'] as String,
        developmentAreaText: json['developmentAreaText'] as String,
        completedAt: json['completedAt'] as String,
      );
}

class CareerDnaDirectionFit {
  final String name;
  final int fitPercent;
  const CareerDnaDirectionFit({required this.name, required this.fitPercent});

  Map<String, dynamic> toJson() => {'name': name, 'fitPercent': fitPercent};
  factory CareerDnaDirectionFit.fromJson(Map<String, dynamic> json) =>
      CareerDnaDirectionFit(name: json['name'] as String, fitPercent: json['fitPercent'] as int);
}

class CareerDnaRoleFit {
  final String name;
  final int fitPercent;
  const CareerDnaRoleFit({required this.name, required this.fitPercent});

  Map<String, dynamic> toJson() => {'name': name, 'fitPercent': fitPercent};
  factory CareerDnaRoleFit.fromJson(Map<String, dynamic> json) =>
      CareerDnaRoleFit(name: json['name'] as String, fitPercent: json['fitPercent'] as int);
}

class CareerDnaLevel5Result {
  final DimensionScores ownDimensionScores;
  final DimensionScores blendedDimensionScores;
  final List<CareerDnaDirectionFit> topDirections;
  final List<CareerDnaRoleFit> topRoles;
  final String confidenceTier; // high|moderate|exploratory
  final String confidenceText;
  final List<String> careerStrengths;
  final List<String> developmentAreas;
  final List<String> nextSteps;
  final String completedAt;

  const CareerDnaLevel5Result({
    required this.ownDimensionScores,
    required this.blendedDimensionScores,
    required this.topDirections,
    required this.topRoles,
    required this.confidenceTier,
    required this.confidenceText,
    required this.careerStrengths,
    required this.developmentAreas,
    required this.nextSteps,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'ownDimensionScores': ownDimensionScores,
        'blendedDimensionScores': blendedDimensionScores,
        'topDirections': topDirections.map((d) => d.toJson()).toList(),
        'topRoles': topRoles.map((r) => r.toJson()).toList(),
        'confidenceTier': confidenceTier,
        'confidenceText': confidenceText,
        'careerStrengths': careerStrengths,
        'developmentAreas': developmentAreas,
        'nextSteps': nextSteps,
        'completedAt': completedAt,
      };

  factory CareerDnaLevel5Result.fromJson(Map<String, dynamic> json) => CareerDnaLevel5Result(
        ownDimensionScores: (json['ownDimensionScores'] as Map).cast<String, int>(),
        blendedDimensionScores: (json['blendedDimensionScores'] as Map).cast<String, int>(),
        topDirections: (json['topDirections'] as List).map((d) => CareerDnaDirectionFit.fromJson(d as Map<String, dynamic>)).toList(),
        topRoles: (json['topRoles'] as List).map((r) => CareerDnaRoleFit.fromJson(r as Map<String, dynamic>)).toList(),
        confidenceTier: json['confidenceTier'] as String,
        confidenceText: json['confidenceText'] as String,
        careerStrengths: (json['careerStrengths'] as List).cast<String>(),
        developmentAreas: (json['developmentAreas'] as List).cast<String>(),
        nextSteps: (json['nextSteps'] as List).cast<String>(),
        completedAt: json['completedAt'] as String,
      );
}

/// One student's whole Career DNA journey. Each level field is null until
/// that level is completed — deliberately the ONLY thing persisted; raw
/// in-progress answers live in the quiz screen's own local widget state and
/// are genuinely lost on quit, mirroring aptitude_screen.dart's own
/// stricter (not autosaved) model.
class CareerDnaProfile {
  final CareerDnaLevel1Result? level1;
  final CareerDnaLevel2Result? level2;
  final CareerDnaLevel3Result? level3;
  final CareerDnaLevel4Result? level4;
  final CareerDnaLevel5Result? level5;

  /// Levels 2-5 that have each individually been paid for (₹51 per level —
  /// no single payment unlocks more than one). Level 1's report never
  /// appears here — it's always free, checked separately by
  /// `isLevelReportUnlocked` below rather than being stored as a payment.
  final List<int> paidLevels;

  const CareerDnaProfile({
    this.level1,
    this.level2,
    this.level3,
    this.level4,
    this.level5,
    this.paidLevels = const [],
  });

  int get completedLevelCount => [level1, level2, level3, level4, level5].where((l) => l != null).length;
  bool get allLevelsComplete => completedLevelCount == 5;

  /// Whether that level's quiz has been finished (its result persisted).
  bool isLevelComplete(int level) {
    switch (level) {
      case 1:
        return level1 != null;
      case 2:
        return level2 != null;
      case 3:
        return level3 != null;
      case 4:
        return level4 != null;
      case 5:
        return level5 != null;
      default:
        return false;
    }
  }

  /// Whether that level's report/PDF can be downloaded right now — every
  /// level's report is free once that level is complete (Career DNA has no
  /// paywall). `paidLevels` is kept only as harmless vestigial state from
  /// when this used to gate on payment.
  bool isLevelReportUnlocked(int level) => true;

  CareerDnaProfile copyWith({
    CareerDnaLevel1Result? level1,
    CareerDnaLevel2Result? level2,
    CareerDnaLevel3Result? level3,
    CareerDnaLevel4Result? level4,
    CareerDnaLevel5Result? level5,
    List<int>? paidLevels,
  }) {
    return CareerDnaProfile(
      level1: level1 ?? this.level1,
      level2: level2 ?? this.level2,
      level3: level3 ?? this.level3,
      level4: level4 ?? this.level4,
      level5: level5 ?? this.level5,
      paidLevels: paidLevels ?? this.paidLevels,
    );
  }

  Map<String, dynamic> toJson() => {
        'level1': level1?.toJson(),
        'level2': level2?.toJson(),
        'level3': level3?.toJson(),
        'level4': level4?.toJson(),
        'level5': level5?.toJson(),
        'paidLevels': paidLevels,
      };

  factory CareerDnaProfile.fromJson(Map<String, dynamic> json) => CareerDnaProfile(
        level1: json['level1'] != null ? CareerDnaLevel1Result.fromJson(json['level1'] as Map<String, dynamic>) : null,
        level2: json['level2'] != null ? CareerDnaLevel2Result.fromJson(json['level2'] as Map<String, dynamic>) : null,
        level3: json['level3'] != null ? CareerDnaLevel3Result.fromJson(json['level3'] as Map<String, dynamic>) : null,
        level4: json['level4'] != null ? CareerDnaLevel4Result.fromJson(json['level4'] as Map<String, dynamic>) : null,
        level5: json['level5'] != null ? CareerDnaLevel5Result.fromJson(json['level5'] as Map<String, dynamic>) : null,
        paidLevels: json['paidLevels'] != null ? (json['paidLevels'] as List).cast<int>() : const [],
      );
}

/// Pure readiness/locking helpers, mirroring profile_readiness.dart's own
/// `extension ProfileReadiness on User` exactly — "locked" is purely
/// derived, never persisted, and checked with a plain in-widget conditional
/// (see career_dna_landing_screen.dart) rather than a router guard.
extension CareerDnaAccess on User {
  CareerDnaProfile get careerDnaOrEmpty => careerDna ?? const CareerDnaProfile();

  bool isCareerDnaLevelUnlocked(int level) {
    if (level <= 1) return true;
    final p = careerDnaOrEmpty;
    switch (level) {
      case 2:
        return p.level1 != null;
      case 3:
        return p.level2 != null;
      case 4:
        return p.level3 != null;
      case 5:
        return p.level4 != null;
      default:
        return false;
    }
  }

  bool get careerDnaAllLevelsComplete => careerDnaOrEmpty.allLevelsComplete;
}
