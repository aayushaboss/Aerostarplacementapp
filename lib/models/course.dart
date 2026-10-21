/// Mirrors frontend/src/mockData/mockCourses.ts `Course` + `SyllabusModule`.
class Course {
  final String id;
  final String title;
  final String category;
  final String cluster;
  final String duration;
  final int modules;
  final String image;
  final String summary;

  /// Duration in months from the course spreadsheet (e.g. 3.5 for "3–4
  /// Months"). Drives the duration filter; [duration] stays the text as given.
  final double months;

  const Course({
    required this.id,
    required this.title,
    required this.category,
    required this.cluster,
    required this.duration,
    required this.modules,
    required this.image,
    required this.summary,
    this.months = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'cluster': cluster,
        'duration': duration,
        'modules': modules,
        'image': image,
        'summary': summary,
        'months': months,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        cluster: json['cluster'] as String,
        duration: json['duration'] as String,
        modules: json['modules'] as int,
        image: json['image'] as String,
        summary: json['summary'] as String,
        months: (json['months'] as num?)?.toDouble() ?? 0,
      );
}

class SyllabusModule {
  final int index;
  final String title;

  const SyllabusModule({required this.index, required this.title});

  Map<String, dynamic> toJson() => {'index': index, 'title': title};

  factory SyllabusModule.fromJson(Map<String, dynamic> json) =>
      SyllabusModule(index: json['index'] as int, title: json['title'] as String);
}
