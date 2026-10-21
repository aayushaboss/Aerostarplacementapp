import 'package:flutter_test/flutter_test.dart';
import 'package:aerostar_edge/mockData/mock_courses.dart';
import 'package:aerostar_edge/mockData/mock_opportunities.dart';
import 'package:aerostar_edge/utils/search_match.dart';

import '../helpers/load_catalog.dart';

void main() {
  setUpAll(loadCatalogFromDisk);

  group('searchTokens', () {
    test('splits into words and drops filler words', () {
      expect(searchTokens('Marketing Intern, Mumbai'), ['marketing', 'intern', 'mumbai']);
      expect(searchTokens('jobs in Mumbai'), ['mumbai']);
      expect(searchTokens('  '), isEmpty);
      expect(searchTokens(null), isEmpty);
    });

    test('a query of only filler words still searches for what was typed', () {
      expect(searchTokens('jobs'), ['jobs']);
    });
  });

  group('job search', () {
    test('a single word still works', () {
      expect(filterOpportunities(query: 'marketing'), isNotEmpty);
    });

    test('several words match in any order, across title, type and city', () {
      final results = filterOpportunities(query: 'marketing intern mumbai');
      expect(results, isNotEmpty);
      for (final o in results) {
        expect(o.location.toLowerCase(), contains('mumbai'));
        expect(o.title.toLowerCase() + o.category.toLowerCase(), contains('marketing'));
        expect(o.type.toLowerCase(), contains('intern'));
      }
      expect(filterOpportunities(query: 'mumbai intern marketing').length, results.length);
    });

    test('company and role words combine', () {
      final results = filterOpportunities(query: 'zerodha marketing');
      expect(results, isNotEmpty);
      expect(results.every((o) => o.company.toLowerCase().contains('zerodha')), isTrue);
    });

    test('"full time" and "fulltime" both find Full Time jobs and nothing else', () {
      final spaced = filterOpportunities(query: 'full time marketing');
      final joined = filterOpportunities(query: 'fulltime marketing');
      expect(spaced, isNotEmpty);
      expect(spaced.length, joined.length);
      expect(spaced.every((o) => o.type.toLowerCase().replaceAll(RegExp(r'[ -]'), '') == 'fulltime'), isTrue);
    });

    test('plural words match ("internships")', () {
      expect(filterOpportunities(query: 'marketing internships').length, filterOpportunities(query: 'marketing intern').length);
    });

    test('words that match nothing together give no results', () {
      expect(filterOpportunities(query: 'marketing xyzzyqq'), isEmpty);
    });

    test('a word in the title ranks above one only found elsewhere', () {
      final byTitle = mockOpportunities.firstWhere((o) => o.title.toLowerCase().contains('marketing'));
      final elsewhere = mockOpportunities.firstWhere((o) => !o.title.toLowerCase().contains('marketing') && o.category.toLowerCase().contains('marketing'));
      expect(searchRelevance(byTitle, 'marketing'), greaterThan(searchRelevance(elsewhere, 'marketing')));
    });
  });

  group('course search', () {
    test('several words match in any order', () {
      final results = filterCoursesAdvanced(query: 'marketing ai');
      expect(results, isNotEmpty);
      for (final c in results) {
        final text = '${c.title} ${c.category}'.toLowerCase();
        expect(text, contains('marketing'));
        expect(text, contains('ai'));
      }
    });

    test('unrelated words give no results', () {
      expect(filterCoursesAdvanced(query: 'marketing xyzzyqq'), isEmpty);
    });
  });
}
