import '../../models/application.dart';
import '../api_client.dart';
import 'application_repository.dart';

/// Not wired to anything real yet — see BACKEND_API_CONTRACT.md.
class HttpApplicationRepository implements ApplicationRepository {
  final ApiClient client;
  const HttpApplicationRepository(this.client);

  @override
  Future<List<Application>> listApplications() => throw UnimplementedError('GET /applications — see BACKEND_API_CONTRACT.md');

  @override
  Application? getApplicationById(String id) =>
      throw UnimplementedError('GET /applications/{id} — needs a local cache once wired');

  @override
  bool isOpportunityApplied(String opportunityId) =>
      throw UnimplementedError('needs a local cache once wired, see application_repository.dart');

  @override
  Application? getApplicationForOpportunity(String opportunityId) =>
      throw UnimplementedError('needs a local cache once wired, see application_repository.dart');

  @override
  Future<({Application application, bool isNew})?> createApplication(
    String opportunityId, {
    String? note,
    Map<String, String>? screeningAnswers,
  }) =>
      throw UnimplementedError('POST /applications — see BACKEND_API_CONTRACT.md');

  @override
  Future<void> removeApplication(String id) => throw UnimplementedError('DELETE /applications/{id} — see BACKEND_API_CONTRACT.md');

  @override
  Future<void> restoreApplication(String id) =>
      throw UnimplementedError('POST /applications/{id}/restore — see BACKEND_API_CONTRACT.md');

  @override
  Future<List<Application>> listRecentlyDeleted() =>
      throw UnimplementedError('GET /applications/deleted — see BACKEND_API_CONTRACT.md');

  @override
  Future<void> permanentlyDelete(String id) =>
      throw UnimplementedError('DELETE /applications/{id}/permanent — see BACKEND_API_CONTRACT.md');
}
