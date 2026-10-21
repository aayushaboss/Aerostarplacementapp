import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:aerostar_edge/mockData/mock_applications.dart';
import 'package:aerostar_edge/mockData/mock_courses.dart';
import 'package:aerostar_edge/mockData/mock_opportunities.dart';
import 'package:aerostar_edge/mockData/mock_profile_options.dart' show mockAllRoles, mockCities, validRoles;

import '../helpers/load_catalog.dart';

void main() {
  setUpAll(loadCatalogFromDisk);

  List<Map<String, dynamic>> raw(String name) =>
      (jsonDecode(File('assets/data/$name').readAsStringSync()) as List).cast<Map<String, dynamic>>();

  group('jobs', () {
    test('all 1,000 spreadsheet jobs are loaded, with unique ids and 100 startups', () {
      expect(mockOpportunities.length, 1000);
      expect(mockOpportunities.map((o) => o.id).toSet().length, 1000);
      expect(mockOpportunities.first.id, 'JOB0001');
      expect(mockOpportunities.last.id, 'JOB1000');
      expect(mockOpportunities.map((o) => o.startupId).toSet().length, 100);
    });

    test('every spreadsheet column is on the model, unchanged', () {
      final rows = raw('jobs.json');
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        final o = mockOpportunities[i];
        expect(o.id, r['id']);
        expect(o.startupId, r['startupId']);
        expect(o.company, r['company']);
        expect(o.location, r['city']);
        expect(o.sector, r['sector']);
        expect(o.experience, r['experience']);
        expect(o.department, r['department']);
        expect(o.category, r['department']);
        expect(o.title, r['position']);
        expect(o.about, r['description']);
        expect(o.salaryRange, r['salaryRange']);
        expect(o.internStipend, r['internStipend']);
        expect(o.demoOpening, r['demoOpening'] == 'Yes');
      }
    });

    test('"Full Time" becomes the app\'s "Full-time"; internships carry a stipend, jobs do not', () {
      final fullTime = mockOpportunities.where((o) => o.type == 'Full-time');
      final interns = mockOpportunities.where((o) => o.type == 'Internship');
      expect(fullTime.length, 800);
      expect(interns.length, 200);
      expect(interns.every((o) => o.internStipend != null && o.stipend == o.internStipend), isTrue);
      expect(fullTime.every((o) => o.internStipend == null && o.stipend == o.salaryRange), isTrue);
      expect(fullTime.every((o) => o.employmentType == 'Full-time'), isTrue);
      expect(filterOpportunities(type: 'Full-time').length, 800);
      expect(filterOpportunities(type: 'Internship').length, 200);
    });

    test('placeholder fields are always filled and every prep course exists', () {
      for (final o in mockOpportunities) {
        expect(o.deadline, isNotEmpty, reason: o.id);
        expect(o.requirements, isNotEmpty, reason: o.id);
        expect(o.applicantCount, greaterThan(0), reason: o.id);
        expect(o.prepCourses, isNotEmpty, reason: '${o.id} (${o.department}) has no prep course');
        for (final id in o.prepCourses) {
          expect(getCourseById(id), isNotNull, reason: '${o.id} -> $id');
        }
      }
    });

    test('lookup, search and city filter work on the 1,000 jobs', () {
      expect(getOpportunityById('JOB0001')?.company, 'Zerodha');
      expect(getOpportunityById('opp-frontend-intern'), isNull);
      expect(filterOpportunities(query: 'zerodha').length, 10);
      expect(filterOpportunities(location: 'Gurugram').length, 170);
      expect(filterOpportunities(categories: ['Marketing']).length, 300);
      expect(filterOpportunities(locations: ['Delhi NCR']).length, 10);
      expect(mockCities, contains('Delhi NCR'));
    });

    test('roles are the 7 job departments; old saved roles map onto them', () {
      expect(mockAllRoles.toSet(), mockOpportunities.map((o) => o.category).toSet());
      expect(validRoles(['Software', 'Marketing', 'Data']), ['Operations', 'Marketing']);
      expect(validRoles(['Design', 'HR']), ['Graphic Designing', 'Human Resource']);
      expect(validRoles(['Unknown role']), isEmpty);
    });
  });

  group('courses', () {
    test('all 131 spreadsheet courses are loaded, with 17 departments', () {
      expect(mockCourses.length, 131);
      expect(mockCourses.map((c) => c.id).toSet().length, 131);
      expect(courseCategories.length, 17);
      final rows = raw('courses.json');
      for (var i = 0; i < rows.length; i++) {
        final c = mockCourses[i];
        expect(c.category, rows[i]['department']);
        expect(c.title, rows[i]['skillName']);
        expect(c.duration, rows[i]['courseDuration']);
        expect(c.months, (rows[i]['durationMonths'] as num).toDouble());
      }
    });

    test('duration buckets use the numeric months and cover every course once', () {
      final counts = [for (final b in courseDurationBuckets) filterCoursesAdvanced(durationBuckets: [b]).length];
      expect(counts.reduce((a, b) => a + b), 131);
      expect(filterCoursesAdvanced(durationBuckets: ['3+ months']).every((c) => c.months > 3), isTrue);
      expect(filterCoursesAdvanced(durationBuckets: ['Up to 2 months']).every((c) => c.months <= 2), isTrue);
    });

    test('every course has a syllabus and every department can be listed', () {
      for (final c in mockCourses) {
        expect(courseSyllabus(c).length, c.modules, reason: c.title);
        expect(c.summary, isNotEmpty);
      }
      expect(courseCategories.expand((d) => filterCourses(d)).length, 131);
      expect(filterCoursesAdvanced(query: 'AI-Powered').single.title, 'AI-Powered Marketing Strategy');
    });
  });

  group('demo user data', () {
    test('the showcase user keeps 4 applications, pointing at real jobs with matching text', () {
      setApplicationsUser(demoShowcaseUserId);
      final apps = listApplications();
      expect(apps.length, 4);
      for (final a in apps) {
        final job = getOpportunityById(a.opportunityId);
        expect(job, isNotNull);
        expect(a.opportunity.company, job!.company);
        expect(a.opportunity.title, job.title);
      }
      final offer = apps.firstWhere((a) => a.status == 'Offer');
      expect(offer.messages.last.text, contains(offer.opportunity.company));
    });
  });
}
