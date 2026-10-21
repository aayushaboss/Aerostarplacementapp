import '../../models/opportunity.dart';
import '../api_client.dart';
import 'opportunity_repository.dart';

/// Not wired to anything real yet — see BACKEND_API_CONTRACT.md.
class HttpOpportunityRepository implements OpportunityRepository {
  final ApiClient client;
  const HttpOpportunityRepository(this.client);

  @override
  Future<List<Opportunity>> listOpportunities({
    String? type,
    String? workMode,
    String? query,
    List<String>? categories,
    String? location,
    String? employmentType,
    List<String>? locations,
  }) =>
      throw UnimplementedError('GET /opportunities — see BACKEND_API_CONTRACT.md');

  @override
  Opportunity? getOpportunityById(String id) =>
      throw UnimplementedError('GET /opportunities/{id} — needs a local cache once wired, see opportunity_repository.dart');

  @override
  List<String> searchSuggestionTerms() =>
      throw UnimplementedError('GET /opportunities/search-terms — see BACKEND_API_CONTRACT.md');
}
