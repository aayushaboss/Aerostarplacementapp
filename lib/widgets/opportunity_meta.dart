import '../models/opportunity.dart';

/// Meta line group for [OpportunityRow]: city and sector, the pay line (monthly
/// stipend for internships, otherwise the salary range) and duration. The rest
/// of the spreadsheet's fields (experience, department, startup ID, demo
/// opening, LPA equivalent) are on the job detail page.
List<String> opportunityMeta(Opportunity o) => [
      o.sector.isEmpty ? o.location : '${o.location} · ${o.sector}',
      o.stipend,
      o.duration,
    ];
