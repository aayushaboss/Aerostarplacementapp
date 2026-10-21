/// Mirrors frontend/src/mockData/mockOpportunities.ts `Opportunity`.
class Opportunity {
  final String id;
  final String title;
  final String company;
  final String type;
  final String location;
  final String workMode;
  final String stipend;
  final String duration;
  final String category;

  /// `Full-time`/`Part-time` — only ever meaningful when [type] is
  /// `'Full-time'`; every Internship leaves this null. Lets the Home
  /// filter's Employment Type facet actually narrow results, unlike
  /// [type] alone (Internship vs Full-time), which is a separate facet.
  final String? employmentType;
  final String image;
  final String about;
  final List<String> requirements;
  final List<String> prepCourses;

  /// ISO date (yyyy-MM-dd) the application window closes. Drives the
  /// urgency indicator on cards — prototype-only, replace with a real
  /// deadline from the API later.
  final String deadline;

  /// How many people have applied so far — shown on the detail page
  /// (Naukri-style social proof). Mocked; a real API would return this.
  final int applicantCount;

  /// Quick pre-apply screening questions, company-voice ("Are you willing
  /// to relocate?"). Paired index-for-index with [screeningQuestionOptions]
  /// — each question carries its own tappable quick-answer badges rather
  /// than one generic Yes/No set reused everywhere.
  final List<String> screeningQuestions;
  final List<List<String>> screeningQuestionOptions;

  // ---- Straight from the job spreadsheet (empty/null when a job has none) ----

  /// Startup ID, e.g. "ST001". One startup has several jobs.
  final String startupId;

  /// Industry/sector of the startup, e.g. "FinTech", "D2C / FoodTech".
  final String sector;

  /// Experience asked for, e.g. "0 Years", "0–1 Year", "3–5 Years".
  final String experience;

  /// Department as written in the sheet (same value as [category]).
  final String department;

  /// Salary range text exactly as given, e.g. "₹3.5–₹6.8 LPA". Internships
  /// carry an "LPA equivalent" here as well as a monthly [internStipend].
  final String salaryRange;

  /// Monthly stipend text, e.g. "₹17,000–₹25,000/month". Only internships have it.
  final String? internStipend;

  /// "Demo Opening" column: true when the opening is flagged as a demo.
  final bool demoOpening;

  const Opportunity({
    required this.id,
    required this.title,
    required this.company,
    required this.type,
    required this.location,
    required this.workMode,
    required this.stipend,
    required this.duration,
    required this.category,
    this.employmentType,
    required this.image,
    required this.about,
    required this.requirements,
    required this.prepCourses,
    required this.deadline,
    this.applicantCount = 0,
    this.screeningQuestions = const [],
    this.screeningQuestionOptions = const [],
    this.startupId = '',
    this.sector = '',
    this.experience = '',
    this.department = '',
    this.salaryRange = '',
    this.internStipend,
    this.demoOpening = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'company': company,
        'type': type,
        'location': location,
        'workMode': workMode,
        'stipend': stipend,
        'duration': duration,
        'category': category,
        'employmentType': employmentType,
        'image': image,
        'about': about,
        'requirements': requirements,
        'prepCourses': prepCourses,
        'deadline': deadline,
        'applicantCount': applicantCount,
        'screeningQuestions': screeningQuestions,
        'screeningQuestionOptions': screeningQuestionOptions,
        'startupId': startupId,
        'sector': sector,
        'experience': experience,
        'department': department,
        'salaryRange': salaryRange,
        'internStipend': internStipend,
        'demoOpening': demoOpening,
      };

  factory Opportunity.fromJson(Map<String, dynamic> json) => Opportunity(
        id: json['id'] as String,
        title: json['title'] as String,
        company: json['company'] as String,
        type: json['type'] as String,
        location: json['location'] as String,
        workMode: json['workMode'] as String,
        stipend: json['stipend'] as String,
        duration: json['duration'] as String,
        category: json['category'] as String,
        employmentType: json['employmentType'] as String?,
        image: json['image'] as String,
        about: json['about'] as String,
        requirements: (json['requirements'] as List).cast<String>(),
        prepCourses: (json['prepCourses'] as List).cast<String>(),
        deadline: json['deadline'] as String,
        applicantCount: json['applicantCount'] as int? ?? 0,
        screeningQuestions: (json['screeningQuestions'] as List?)?.cast<String>() ?? const [],
        screeningQuestionOptions: (json['screeningQuestionOptions'] as List?)
                ?.map((o) => (o as List).cast<String>())
                .toList() ??
            const [],
        startupId: json['startupId'] as String? ?? '',
        sector: json['sector'] as String? ?? '',
        experience: json['experience'] as String? ?? '',
        department: json['department'] as String? ?? '',
        salaryRange: json['salaryRange'] as String? ?? '',
        internStipend: json['internStipend'] as String?,
        demoOpening: json['demoOpening'] as bool? ?? false,
      );
}
