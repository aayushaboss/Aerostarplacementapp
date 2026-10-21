// Prototype mock data — delete when real API is wired.
//
// The course catalogue is the "Courses" sheet of the "Job Lists for Pitchvilla
// Hiring App" spreadsheet (131 courses in 17 departments). It is loaded from
// assets/data/courses.json by catalog_loader.dart before the app starts; this
// file keeps the synchronous accessors the screens have always used.
import '../models/course.dart';
import '../utils/search_match.dart';
import '../models/opportunity.dart';

List<Course> _courses = const [];
Map<String, Course> _byId = const {};
List<String> _categories = const [];

/// All courses, in spreadsheet order. Empty until [installCourses] runs.
List<Course> get mockCourses => _courses;

/// Called by catalog_loader.dart once the spreadsheet data is parsed.
void installCourses(List<Course> items) {
  _courses = List.unmodifiable(items);
  _byId = {for (final c in items) c.id: c};
  // Departments in the order the sheet lists them.
  final seen = <String>{};
  _categories = List.unmodifiable([for (final c in items) if (seen.add(c.category)) c.category]);
}

/// The 17 course departments, in sheet order. Used throughout the app (Filter
/// screen, category picker, and the default carousel stack).
List<String> get courseCategories => _categories;

/// Duration buckets shown in the Filter screen's Duration row, based on the
/// sheet's numeric "Duration (Months)". Kept in sync with
/// [_matchesDurationBucket] below.
const courseDurationBuckets = ['Up to 2 months', '2–3 months', '3+ months'];

bool _matchesDurationBucket(Course c, String bucket) {
  final m = c.months;
  switch (bucket) {
    case 'Up to 2 months':
      return m > 0 && m <= 2;
    case '2–3 months':
      return m > 2 && m <= 3;
    case '3+ months':
      return m > 3;
    default:
      return false;
  }
}

List<Course> filterCourses([String? category]) {
  if (category == null || category.toLowerCase() == 'all') return mockCourses;
  return mockCourses.where((c) => c.category.toLowerCase() == category.toLowerCase()).toList();
}

/// Suggestion pool for the Courses search box: every course title and department.
List<String> courseSearchSuggestionTerms() {
  final terms = <String>{};
  for (final c in mockCourses) {
    terms.add(c.title);
    terms.add(c.category);
  }
  return terms.toList()..sort();
}

/// Multi-facet filter for the Courses tab's Filter screen — department and
/// duration-bucket are each optional and AND-combined (an empty list for a
/// facet means "don't filter on this facet"). [query] lets a text search
/// combine with the same facets; it matches title and department.
List<Course> filterCoursesAdvanced({
  List<String> categories = const [],
  List<String> durationBuckets = const [],
  String? query,
}) {
  final tokens = searchTokens(query);
  return mockCourses.where((c) {
    if (categories.isNotEmpty && !categories.contains(c.category)) return false;
    if (durationBuckets.isNotEmpty && !durationBuckets.any((b) => _matchesDurationBucket(c, b))) return false;
    if (tokens.isNotEmpty && !matchesAllTokens(tokens, [c.title, c.category])) return false;
    return true;
  }).toList();
}

Course? getCourseById(String id) => _byId[id];

/// Placeholder outline — the sheet has no syllabus. One generic step per
/// module (the course's [Course.modules] count), mentioning the skill.
const _outline = [
  'Introduction to {s}',
  'Core concepts and vocabulary',
  'Tools and platforms',
  'Planning and strategy',
  'Hands-on exercise 1',
  'Case study',
  'Working with data',
  'Applying AI tools',
  'Workflow and automation',
  'Hands-on exercise 2',
  'Best practices and common mistakes',
  'Measuring results',
  'Team collaboration',
  'Real-world scenario',
  'Hands-on exercise 3',
  'Capstone planning',
  'Capstone project',
  'Review and feedback',
  'Interview preparation',
  'Assessment and certificate',
];

List<SyllabusModule> courseSyllabus(Course course) {
  final count = course.modules > 0 ? course.modules : 6;
  return List.generate(count, (i) {
    // The last module is always the assessment, whatever the length.
    final template = i == count - 1 ? _outline.last : _outline[i % (_outline.length - 1)];
    return SyllabusModule(index: i + 1, title: template.replaceAll('{s}', course.title));
  });
}

List<Course> recommendedCourses([List<String> clusters = const []]) {
  final recs = mockCourses.where((c) => clusters.contains(c.cluster)).toList();
  // Fallback also takes 6 (not 4) so a user with no cluster match (or none
  // yet) still sees enough courses for the carousel's "View all" tile.
  final list = recs.isNotEmpty ? recs : mockCourses.take(6).toList();
  return list.take(6).toList();
}

List<Course> prepCoursesFor(List<String> ids) {
  return ids.map(getCourseById).whereType<Course>().toList();
}

/// Every prep course tied to a set of opportunities, deduped and falling
/// back to the general catalog so the result is never empty — shared by
/// the applications tracker's "prep for this interview" sheet and the
/// college Home feed's end-of-scroll "Courses to boost your profile" carousel.
List<Course> prepCoursesForOpportunities(Iterable<Opportunity> opportunities, {int take = 4}) {
  final ids = <String>[];
  for (final opp in opportunities) {
    for (final courseId in opp.prepCourses) {
      if (!ids.contains(courseId)) ids.add(courseId);
    }
  }
  final courses = prepCoursesFor(ids);
  if (courses.length >= take) return courses.take(take).toList();
  // Top up with the general catalog (deduped) rather than stopping short.
  final result = [...courses];
  for (final c in mockCourses) {
    if (result.length >= take) break;
    if (!result.any((r) => r.id == c.id)) result.add(c);
  }
  return result;
}
