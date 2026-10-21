import '../../models/application.dart';

/// Bulk reads and mutations are async (real API shape); [getApplicationById]
/// and [isOpportunityApplied] stay synchronous since they're called inline
/// across several card/row builders — see OpportunityRepository's doc
/// comment for the same tradeoff.
abstract class ApplicationRepository {
  Future<List<Application>> listApplications();

  Application? getApplicationById(String id);

  bool isOpportunityApplied(String opportunityId);

  /// Null if the signed-in user has no live (non-deleted) application for
  /// this opportunity. Sync, same tradeoff as [isOpportunityApplied].
  Application? getApplicationForOpportunity(String opportunityId);

  /// Returns null if the opportunity can't be resolved; `(isNew: false)` if
  /// the user already has a live application for it (no duplicate created);
  /// `(isNew: true)` on a genuine new application.
  Future<({Application application, bool isNew})?> createApplication(
    String opportunityId, {
    String? note,
    Map<String, String>? screeningAnswers,
  });

  Future<void> removeApplication(String id);
  Future<void> restoreApplication(String id);
  Future<List<Application>> listRecentlyDeleted();
  Future<void> permanentlyDelete(String id);
}
