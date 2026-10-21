import '../../models/opportunity.dart';

/// [listOpportunities] is async (real API shape: filters become query
/// params) since it's only ever called from a `_load()`-style method that
/// already tolerates a wait. [getOpportunityById] stays synchronous — it's
/// called inline per-row across several carousel/list builders, and making
/// those async would need a much larger per-row caching/FutureBuilder
/// change than this pass covers. A real HttpOpportunityRepository will need
/// to keep a local cache of the last-fetched list to answer this without a
/// network call per row.
abstract class OpportunityRepository {
  Future<List<Opportunity>> listOpportunities({
    String? type,
    String? workMode,
    String? query,
    List<String>? categories,
    String? location,
    String? employmentType,
    List<String>? locations,
  });

  Opportunity? getOpportunityById(String id);

  List<String> searchSuggestionTerms();
}
