import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/course.dart';
import '../models/opportunity.dart';
import 'mock_courses.dart' show installCourses;
import 'mock_opportunities.dart' show installOpportunities;

// The job and course catalogue comes from the "Job Lists for Pitchvilla Hiring
// App" spreadsheet, converted to JSON by tool/xlsx_to_json.ps1. Every column is
// kept on the model. Fields the sheet does not have (deadline, applicant count,
// requirements, screening questions, course modules/summary/syllabus ...) are
// filled with deterministic placeholders below, so the demo looks the same on
// every run.

/// Loads assets/data/jobs.json and courses.json once, before `runApp`.
Future<void> loadCatalog() async {
  final jobs = jsonDecode(await rootBundle.loadString('assets/data/jobs.json')) as List;
  final courses = jsonDecode(await rootBundle.loadString('assets/data/courses.json')) as List;
  installCatalog(jobs.cast<Map<String, dynamic>>(), courses.cast<Map<String, dynamic>>());
}

/// Builds the models from the raw sheet rows and installs them. Courses go
/// first because each job links to the courses of its department.
void installCatalog(List<Map<String, dynamic>> jobRows, List<Map<String, dynamic>> courseRows) {
  final courses = <Course>[];
  final usedIds = <String>{};
  for (final row in courseRows) {
    courses.add(courseFromSheet(row, usedIds));
  }
  installCourses(courses);

  final opportunities = <Opportunity>[];
  for (var i = 0; i < jobRows.length; i++) {
    opportunities.add(opportunityFromSheet(jobRows[i], i, courses));
  }
  installOpportunities(opportunities);
}

// ---------------------------------------------------------------- courses

/// Job departments mapped to the course departments that prepare for them.
const _prepDepartments = <String, List<String>>{
  'Marketing': ['Marketing', 'Digital Marketing'],
  'Sales & Business Development': ['Sales & Business Development', 'Customer Success'],
  'Social Media Marketing': ['Social Media Marketing', 'Digital Marketing'],
  'Human Resource': ['Human Resources'],
  'Operations': ['Operations', 'Supply Chain & Logistics'],
  'Graphic Designing': ['Graphic Designing'],
  'Finance & Accounting': ['Finance & Accounting', 'Business Analytics'],
};

/// The school aptitude flow recommends courses by one of five clusters. The
/// sheet only has departments, so each department is bucketed into a cluster.
const _clusterByDepartment = <String, String>{
  'Marketing': 'Design & Creative',
  'Digital Marketing': 'Design & Creative',
  'Social Media Marketing': 'Design & Creative',
  'Graphic Designing': 'Design & Creative',
  'AI for Business': 'Technology & Computer Science',
  'Product Management': 'Technology & Computer Science',
  'Business Analytics': 'Technology & Computer Science',
  'E-Commerce': 'Technology & Computer Science',
  'Human Resources': 'Humanities & Law',
  'Customer Success': 'Humanities & Law',
  'Sales & Business Development': 'Humanities & Law',
};

String _slug(String s) => s.toLowerCase().replaceAll('&', 'and').replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

Course courseFromSheet(Map<String, dynamic> row, Set<String> usedIds) {
  final department = (row['department'] as String).trim();
  final skill = (row['skillName'] as String).trim();
  final durationText = (row['courseDuration'] as String).trim();
  final months = (row['durationMonths'] as num).toDouble();

  var id = 'course-${_slug(skill)}';
  var n = 2;
  while (!usedIds.add(id)) {
    id = 'course-${_slug(skill)}-${n++}';
  }
  return Course(
    id: id,
    title: skill,
    category: department,
    cluster: _clusterByDepartment[department] ?? 'Commerce & Finance',
    duration: durationText,
    // Placeholder: about four modules a month.
    modules: (months * 4).round().clamp(4, 24),
    image: '',
    summary: 'Learn $skill in ${durationText.toLowerCase()}, built for $department roles at fast-growing startups.',
    months: months,
  );
}

// ------------------------------------------------------------------- jobs

const _requirementsByDepartment = <String, List<String>>{
  'Marketing': ['Strong written communication', 'Understanding of digital channels', 'Analytical mindset', 'Creativity and curiosity'],
  'Sales & Business Development': ['Persuasive communication', 'Comfortable working to targets', 'CRM / Excel basics', 'Resilience'],
  'Social Media Marketing': ['Content creation sense', 'Familiar with Instagram, LinkedIn and YouTube', 'Basic analytics', 'Eye for trends'],
  'Human Resource': ['Interpersonal skills', 'Sourcing and screening basics', 'Confidentiality', 'Organised documentation'],
  'Operations': ['Process orientation', 'Excel / Sheets', 'Problem solving', 'Cross-team coordination'],
  'Graphic Designing': ['Figma / Photoshop / Illustrator', 'Typography and layout', 'Portfolio of work', 'Attention to detail'],
  'Finance & Accounting': ['Accounting fundamentals', 'Excel proficiency', 'Accuracy and attention to detail', 'Reporting basics'],
};

String _deadlineIn(int days) => DateTime.now().add(Duration(days: days)).toIso8601String().substring(0, 10);

Opportunity opportunityFromSheet(Map<String, dynamic> row, int index, List<Course> courses) {
  String s(String key) => ((row[key] as String?) ?? '').trim();

  final isInternship = s('type').toLowerCase().startsWith('intern');
  // The sheet writes "Full Time"; the app has always spelled it "Full-time".
  final type = isInternship ? 'Internship' : 'Full-time';
  final department = s('department');
  final stipendText = (row['internStipend'] as String?)?.trim();
  final internStipend = (stipendText == null || stipendText.isEmpty) ? null : stipendText;
  final experience = s('experience');

  // Links to the real courses of this job's department; rotated by the job's
  // position so different jobs surface different courses.
  final wanted = _prepDepartments[department] ?? const <String>[];
  final pool = courses.where((c) => wanted.contains(c.category)).toList();
  final prep = <String>[
    for (var k = 0; k < 3 && pool.isNotEmpty; k++) pool[(index + k) % pool.length].id,
  ];

  final city = s('city');
  return Opportunity(
    id: s('id'),
    title: s('position'),
    company: s('company'),
    type: type,
    location: city,
    // The sheet has no work-mode column; everything is a city-based role.
    workMode: 'Onsite',
    // One line of pay for cards: the stipend for internships, otherwise the range.
    stipend: internStipend ?? s('salaryRange'),
    // Placeholder: internships run 3, 4 or 6 months; jobs are permanent.
    duration: isInternship ? const ['3 months', '4 months', '6 months'][index % 3] : 'Permanent',
    category: department,
    employmentType: isInternship ? null : 'Full-time',
    image: '',
    about: s('description'),
    requirements: ['Experience: $experience', ...(_requirementsByDepartment[department] ?? const <String>[])],
    prepCourses: prep,
    deadline: _deadlineIn(4 + (index % 12)),
    applicantCount: 18 + (index * 11) % 160,
    screeningQuestions: isInternship ? const ['When can you start?'] : const ['What is your notice period?'],
    screeningQuestionOptions: isInternship
        ? const [
            ['Immediately', 'In 2 weeks', 'In a month'],
          ]
        : const [
            ['Immediately', '15 days', '30 days', '60+ days'],
          ],
    startupId: s('startupId'),
    sector: s('sector'),
    experience: experience,
    department: department,
    salaryRange: s('salaryRange'),
    internStipend: internStipend,
    demoOpening: s('demoOpening').toLowerCase() == 'yes',
  );
}
