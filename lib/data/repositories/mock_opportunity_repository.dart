import '../../mockData/mock_opportunities.dart' as mock;
import '../../models/opportunity.dart';
import 'opportunity_repository.dart';

/// Pure delegation to the existing mock_opportunities.dart functions —
/// zero behavior change, just moved behind the repository seam.
class MockOpportunityRepository implements OpportunityRepository {
  @override
  Future<List<Opportunity>> listOpportunities({
    String? type,
    String? workMode,
    String? query,
    List<String>? categories,
    String? location,
    String? employmentType,
    List<String>? locations,
  }) async {
    return mock.filterOpportunities(
      type: type,
      workMode: workMode,
      query: query,
      categories: categories,
      location: location,
      employmentType: employmentType,
      locations: locations,
    );
  }

  @override
  Opportunity? getOpportunityById(String id) => mock.getOpportunityById(id);

  @override
  List<String> searchSuggestionTerms() => mock.searchSuggestionTerms();
}
