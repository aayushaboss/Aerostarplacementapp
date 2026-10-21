import 'package:flutter_test/flutter_test.dart';

import 'package:aerostar_edge/data/repositories/mock_application_repository.dart';
import 'package:aerostar_edge/mockData/mock_applications.dart' show setApplicationsUser;
import 'package:aerostar_edge/mockData/mock_opportunities.dart' show mockOpportunities;

import '../helpers/load_catalog.dart';

void main() {
  late MockApplicationRepository repo;

  setUpAll(loadCatalogFromDisk);

  setUp(() {
    // A fresh, unseeded user id — avoids interaction with the showcase
    // account's 4 seeded applications, and with every other test's writes
    // (mock_applications.dart's backing store is module-level/global).
    setApplicationsUser('test-user-${DateTime.now().microsecondsSinceEpoch}');
    repo = MockApplicationRepository();
  });

  test('createApplication creates a new, non-duplicate application', () async {
    final oppId = mockOpportunities.first.id;

    final first = await repo.createApplication(oppId);
    expect(first, isNotNull);
    expect(first!.isNew, isTrue);
    expect(repo.isOpportunityApplied(oppId), isTrue);

    final second = await repo.createApplication(oppId);
    expect(second, isNotNull);
    expect(second!.isNew, isFalse);
    expect(second.application.id, first.application.id);
  });

  test('createApplication returns null for an unknown opportunity id', () async {
    final result = await repo.createApplication('does-not-exist');
    expect(result, isNull);
  });

  test('removeApplication soft-deletes: hidden from listApplications, present in listRecentlyDeleted', () async {
    final oppId = mockOpportunities.first.id;
    final created = await repo.createApplication(oppId);
    final id = created!.application.id;

    await repo.removeApplication(id);

    final active = await repo.listApplications();
    expect(active.any((a) => a.id == id), isFalse);

    final deleted = await repo.listRecentlyDeleted();
    expect(deleted.any((a) => a.id == id), isTrue);
  });

  test('restoreApplication brings a soft-deleted application back', () async {
    final oppId = mockOpportunities.first.id;
    final created = await repo.createApplication(oppId);
    final id = created!.application.id;

    await repo.removeApplication(id);
    await repo.restoreApplication(id);

    final active = await repo.listApplications();
    expect(active.any((a) => a.id == id), isTrue);
  });

  test('permanentlyDelete removes it from both lists', () async {
    final oppId = mockOpportunities.first.id;
    final created = await repo.createApplication(oppId);
    final id = created!.application.id;

    await repo.removeApplication(id);
    await repo.permanentlyDelete(id);

    final deleted = await repo.listRecentlyDeleted();
    expect(deleted.any((a) => a.id == id), isFalse);
  });
}
