/// Mirrors frontend/src/mockData/mockResume.ts `ParsedResume`.
class ResumeEducation {
  final String degree;
  final String institution;

  /// Formatted range, e.g. '2020 - 2024' or '2020 - Present' — same
  /// free-text-string approach as [WorkExperience.duration], so the two
  /// models stay symmetric.
  final String duration;

  /// CGPA or percentage, e.g. '8.5 CGPA' or '85%'. Optional.
  final String? gpa;

  const ResumeEducation({
    required this.degree,
    required this.institution,
    required this.duration,
    this.gpa,
  });

  Map<String, dynamic> toJson() => {'degree': degree, 'institution': institution, 'duration': duration, 'gpa': gpa};

  factory ResumeEducation.fromJson(Map<String, dynamic> json) => ResumeEducation(
        degree: json['degree'] as String? ?? '',
        institution: json['institution'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
        gpa: json['gpa'] as String?,
      );
}

/// One prior job — company, role, how long, and what they actually did
/// there. A user can have several of these, most recent first.
///
/// The `employmentType`/experience/`joiningDate`/`currentAnnualSalary`/
/// `skillsUsed` fields mirror Naukri's own "Employment" form — nullable
/// since older saved entries (and every entry but the first, which is all
/// that form edits) won't have them.
class WorkExperience {
  final String company;
  final String role;
  final String duration;
  final String description;
  final String? employmentType;
  final String? totalExperienceYears;
  final String? totalExperienceMonths;
  final String? joiningDate;
  final String? currentAnnualSalary;
  final List<String>? skillsUsed;

  const WorkExperience({
    required this.company,
    required this.role,
    required this.duration,
    this.description = '',
    this.employmentType,
    this.totalExperienceYears,
    this.totalExperienceMonths,
    this.joiningDate,
    this.currentAnnualSalary,
    this.skillsUsed,
  });

  Map<String, dynamic> toJson() => {
        'company': company,
        'role': role,
        'duration': duration,
        'description': description,
        'employmentType': employmentType,
        'totalExperienceYears': totalExperienceYears,
        'totalExperienceMonths': totalExperienceMonths,
        'joiningDate': joiningDate,
        'currentAnnualSalary': currentAnnualSalary,
        'skillsUsed': skillsUsed,
      };

  factory WorkExperience.fromJson(Map<String, dynamic> json) => WorkExperience(
        company: json['company'] as String? ?? '',
        role: json['role'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
        description: json['description'] as String? ?? '',
        employmentType: json['employmentType'] as String?,
        totalExperienceYears: json['totalExperienceYears'] as String?,
        totalExperienceMonths: json['totalExperienceMonths'] as String?,
        joiningDate: json['joiningDate'] as String?,
        currentAnnualSalary: json['currentAnnualSalary'] as String?,
        skillsUsed: (json['skillsUsed'] as List?)?.cast<String>(),
      );
}

/// One certification or completed course — name, how long it took (or
/// 'Ongoing'), and an optional way to prove it (a verification link, or a
/// locally-picked image of the certificate). Same free-text `duration`
/// convention as [WorkExperience.duration]/[ResumeEducation.duration].
class ResumeCertification {
  final String name;
  final String duration;
  final String? link;
  final String? imagePath;

  const ResumeCertification({
    required this.name,
    required this.duration,
    this.link,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {'name': name, 'duration': duration, 'link': link, 'imagePath': imagePath};

  factory ResumeCertification.fromJson(Map<String, dynamic> json) => ResumeCertification(
        name: json['name'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
        link: json['link'] as String?,
        imagePath: json['imagePath'] as String?,
      );
}

class ResumeProject {
  final String title;
  final String description;

  const ResumeProject({required this.title, required this.description});

  Map<String, dynamic> toJson() => {'title': title, 'description': description};

  factory ResumeProject.fromJson(Map<String, dynamic> json) => ResumeProject(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}

class ParsedResume {
  final String name;

  /// Professional title shown under the name, e.g. 'Graphics Designer'.
  /// Nullable — optional, and older saved resumes won't have it.
  final String? headline;

  /// Contact phone number. Nullable — optional, and older saved resumes
  /// won't have it (email/city already come from the account/onboarding).
  final String? phone;

  final List<ResumeEducation> education;
  final List<String> skills;
  final List<ResumeProject> projects;
  final List<String> links;

  /// Free-text bucket, e.g. 'Fresher', 'Internship experience only',
  /// '1–2 years', or an exact '15 years' when the user specified one.
  /// Nullable — older saved resumes won't have it.
  final String? experienceLevel;

  /// Focus areas, e.g. 'Web Development', 'Data Science' — degree-suggested,
  /// freely editable. Nullable/empty for older saved resumes.
  final List<String> specializations;

  /// 2–3 sentence professional summary — role/level, key strengths, what
  /// they're aiming for next. Nullable — older saved resumes and the
  /// PDF-upload path (mock-parsed, not asked) won't have it.
  final String? summary;

  /// Prior jobs, most recent first. Empty for freshers or older saved
  /// resumes predating this field.
  final List<WorkExperience> workExperience;

  /// Certifications / completed courses. Empty for older saved resumes
  /// predating this field.
  final List<ResumeCertification> certifications;

  /// A single link to an external portfolio (personal site, Behance,
  /// GitHub, etc.) — the simple alternative to itemizing projects one by
  /// one. Nullable — not every user has one.
  final String? portfolioLink;

  /// Filename of an attached portfolio PDF, if the user chose to upload
  /// one instead of (or alongside) a link. Nullable.
  final String? portfolioFileName;

  /// True while the guided builder has only autosaved a partial resume (the
  /// user left, or is still mid-way). A draft restores into the builder but
  /// never counts as a finished resume — see User.hasResume.
  final bool isDraft;

  /// Awards, achievements and activities, one line each. Empty for older
  /// saved resumes.
  final List<String> achievements;

  const ParsedResume({
    required this.name,
    this.headline,
    this.phone,
    required this.education,
    required this.skills,
    required this.projects,
    required this.links,
    this.experienceLevel,
    this.specializations = const [],
    this.summary,
    this.workExperience = const [],
    this.certifications = const [],
    this.portfolioLink,
    this.portfolioFileName,
    this.isDraft = false,
    this.achievements = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'headline': headline,
        'phone': phone,
        'education': education.map((e) => e.toJson()).toList(),
        'skills': skills,
        'projects': projects.map((p) => p.toJson()).toList(),
        'links': links,
        'experienceLevel': experienceLevel,
        'specializations': specializations,
        'summary': summary,
        'workExperience': workExperience.map((w) => w.toJson()).toList(),
        'certifications': certifications.map((c) => c.toJson()).toList(),
        'portfolioLink': portfolioLink,
        'portfolioFileName': portfolioFileName,
        'isDraft': isDraft,
        'achievements': achievements,
      };

  factory ParsedResume.fromJson(Map<String, dynamic> json) => ParsedResume(
        name: json['name'] as String? ?? '',
        headline: json['headline'] as String?,
        phone: json['phone'] as String?,
        education: ((json['education'] as List?) ?? const [])
            .map((e) => ResumeEducation.fromJson(e as Map<String, dynamic>))
            .toList(),
        skills: ((json['skills'] as List?) ?? const []).cast<String>(),
        projects: ((json['projects'] as List?) ?? const [])
            .map((p) => ResumeProject.fromJson(p as Map<String, dynamic>))
            .toList(),
        links: ((json['links'] as List?) ?? const []).cast<String>(),
        experienceLevel: json['experienceLevel'] as String?,
        specializations: ((json['specializations'] as List?) ?? const []).cast<String>(),
        summary: json['summary'] as String?,
        workExperience: ((json['workExperience'] as List?) ?? const [])
            .map((w) => WorkExperience.fromJson(w as Map<String, dynamic>))
            .toList(),
        certifications: ((json['certifications'] as List?) ?? const [])
            .map((c) => ResumeCertification.fromJson(c as Map<String, dynamic>))
            .toList(),
        portfolioLink: json['portfolioLink'] as String?,
        portfolioFileName: json['portfolioFileName'] as String?,
        isDraft: json['isDraft'] as bool? ?? false,
        achievements: ((json['achievements'] as List?) ?? const []).cast<String>(),
      );
}
