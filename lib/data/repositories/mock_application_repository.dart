import '../../mockData/mock_applications.dart' as mock;
import '../../models/application.dart';
import 'application_repository.dart';

/// Pure delegation to the existing mock_applications.dart functions — zero
/// behavior change (including the userId scoping mock_applications.dart
/// already does via setApplicationsUser, still called by AppState), just
/// moved behind the repository seam.
class MockApplicationRepository implements ApplicationRepository {
  @override
  Future<List<Application>> listApplications() async => mock.listApplications();

  @override
  Application? getApplicationById(String id) => mock.getApplicationById(id);

  @override
  bool isOpportunityApplied(String opportunityId) => mock.isOpportunityApplied(opportunityId);

  @override
  Application? getApplicationForOpportunity(String opportunityId) {
    final matches = mock.listApplications().where((a) => a.opportunityId == opportunityId);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<({Application application, bool isNew})?> createApplication(
    String opportunityId, {
    String? note,
    Map<String, String>? screeningAnswers,
  }) async {
    return mock.createApplication(opportunityId, note: note, screeningAnswers: screeningAnswers);
  }

  @override
  Future<void> removeApplication(String id) async => mock.removeApplication(id);

  @override
  Future<void> restoreApplication(String id) async => mock.restoreApplication(id);

  @override
  Future<List<Application>> listRecentlyDeleted() async => mock.listRecentlyDeleted();

  @override
  Future<void> permanentlyDelete(String id) async => mock.permanentlyDelete(id);
}
