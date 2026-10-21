import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories.dart';
import '../nav.dart';
import '../models/opportunity.dart';
import '../models/opportunity_match.dart';
import '../models/profile_readiness.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../utils/no_orphan.dart';
import '../widgets/app_chip.dart';
import '../widgets/pill_button.dart';
import '../widgets/adaptive_sheet.dart';

/// Single source of truth for "what happens when someone taps Apply" — the
/// job card footer button and the opportunity detail page's Apply bar both
/// call this, so the two surfaces can never drift into different flows.
///
/// [onApplied] lets the caller refresh its own view (e.g. flip a card to
/// show the "Applied" badge) once the application actually goes through.
Future<void> startApplyFlow(
  BuildContext context,
  Opportunity opportunity, {
  VoidCallback? onApplied,
}) async {
  if (context.read<Repositories>().applications.isOpportunityApplied(opportunity.id)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You've already applied — check Applications for updates.")),
    );
    return;
  }

  // Strictly negative, not <= 0 — day 0 is "closing today" (per
  // deadlineLabel), still a valid day to apply; only a deadline that has
  // fully elapsed should block.
  final daysLeft = opportunity.daysUntilDeadline;
  if (daysLeft != null && daysLeft < 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("This opportunity's deadline has passed.")),
    );
    return;
  }

  final user = context.read<AppState>().user;
  if (user == null || !user.canApply) {
    _showApplyGateSheet(context, user, opportunity);
    return;
  }

  _showScreeningSheet(context, opportunity, onApplied);
}

/// Resumes an apply flow that was interrupted for the resume-gate step —
/// called once the resume screen finishes saving with a pending
/// `applyFor` id. Previously the two call sites (resume_screen.dart,
/// resume_builder_quiz_screen.dart) each called createApplication directly
/// with no note/screening answers, so an application submitted via this
/// path was structurally different from one submitted directly (no
/// screening step at all). Routes through the exact same screening sheet
/// the direct-apply path uses instead, so every application goes through
/// one consistent flow regardless of which path got the user there.
void continueApplyAfterResume(BuildContext context, String opportunityId, {VoidCallback? onApplied}) {
  final repositories = context.read<Repositories>();
  final opportunity = repositories.opportunities.getOpportunityById(opportunityId);
  if (opportunity == null) {
    // A stale/unresolvable id (e.g. a bookmarked deep link) previously
    // made this a silent no-op — the resume screen's "Done" button would
    // visibly do nothing at all.
    context.go('/tabs');
    return;
  }
  // This path used to skip the already-applied and deadline guards that
  // startApplyFlow enforces — so finishing a resume for a job you'd
  // already applied to (or whose deadline lapsed while you were building
  // it) would drop you straight into the screening sheet again.
  final existing = repositories.applications.getApplicationForOpportunity(opportunityId);
  if (existing != null) {
    context.go('/application/${existing.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You've already applied — here's your application.")),
    );
    return;
  }
  final daysLeft = opportunity.daysUntilDeadline;
  if (daysLeft != null && daysLeft < 0) {
    context.go('/tabs');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("This opportunity's deadline has passed.")),
    );
    return;
  }
  _showScreeningSheet(context, opportunity, onApplied);
}

void _showApplyGateSheet(BuildContext context, User? user, Opportunity opportunity) {
  final missing = user == null
      ? const <String>['Resume']
      : user.missingForApply.map((i) => i.title).toList();
  final primaryRoute = user == null
      ? '/college/resume'
      : (user.missingForApply.isNotEmpty ? user.missingForApply.first.route : '/college/resume');
  final steps = missing.isEmpty ? 2 : missing.length;
  final headline = steps == 1 ? '1 step left to apply' : '$steps steps left to apply';

  showAdaptiveSheet(
    context: context,
    backgroundColor: AppColors.white,
    // Scrollable + keyboard-aware — a 3+ item missing list with the
    // keyboard up used to overflow this fixed-height sheet.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxxl + MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xs,
              decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: Text(headline, textAlign: TextAlign.left, style: AppTextStyles.h2.copyWith(color: AppColors.ink)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              noOrphan("A couple quick things before you apply."),
              textAlign: TextAlign.left,
              style: AppTextStyles.body.copyWith(color: AppColors.gray500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: missing
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          const Icon(Ionicons.alert_circle_outline, size: 20, color: AppColors.gray500),
                          const SizedBox(width: AppSpacing.md),
                          Text(m, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: PillButton(
              // For the Resume gate the main action is building one with the
              // Resume Helper (most students do not have a resume yet); uploading
              // an existing PDF is the quieter link below.
              label: primaryRoute.contains('resume') ? 'Generate AI resume in 10 mins' : 'Finish profile',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                // Resume is the only gate step that leads straight back into
                // applying — thread the opportunity through so finishing the
                // resume submits this application automatically instead of
                // dropping the user on a generic screen to start over.
                final target = primaryRoute.contains('resume') ? resumeBuildLocation(applyFor: opportunity.id) : primaryRoute;
                context.push(target);
              },
            ),
          ),
          // Only when the gate step is actually Resume — "Finish profile" has
          // no equivalent. A one-tap alternative for students who already have
          // a resume file.
          if (primaryRoute.contains('resume'))
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/college/resume?applyFor=${opportunity.id}');
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text(
                    'Already have one? Upload resume',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 14, fontWeight: AppFontWeight.medium),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          // Plain muted text, not another button — with "Upload resume" and
          // "Don't have one? Build it here" both in blue right above it, a
          // third blue pill here read as an equally-weighted third option
          // instead of the dismiss action it actually is.
          GestureDetector(
            onTap: () {
              // Remember what they were applying to — without this, coming
              // back to the resume screen later through a different entry
              // point (Profile, a direct link) gave zero indication there
              // was an apply in progress; the intent was just lost.
              context.read<AppState>().setPendingApplyOpportunity(opportunity.id);
              Navigator.of(sheetContext).pop();
            },
            child: Text(
              'Not now',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.gray400, fontSize: 12, fontWeight: AppFontWeight.medium),
            ),
          ),
        ],
        ),
      ),
    ),
  );
}

void _showScreeningSheet(BuildContext context, Opportunity opportunity, VoidCallback? onApplied) {
  showAdaptiveSheet(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => _ScreeningSheet(opportunity: opportunity, onApplied: onApplied),
  );
}

void _showSuccessSheet(BuildContext context) {
  showAdaptiveSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => const _ApplySuccessContent(),
  );
}

/// Applying to a job is arguably the app's single most important
/// conversion moment, and used to get a completely static icon — while
/// finishing a Career DNA quiz *level*, a much lower-stakes onboarding
/// step, got a full elastic-scale celebration
/// (career_dna_success_screen.dart). Reuses that exact mechanism here so
/// the app's biggest moment isn't treated as less special than its
/// smallest one.
class _ApplySuccessContent extends StatefulWidget {
  const _ApplySuccessContent();

  @override
  State<_ApplySuccessContent> createState() => _ApplySuccessContentState();
}

class _ApplySuccessContentState extends State<_ApplySuccessContent> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
    _contentOpacity = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    _controller.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetContext = context;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _checkScale,
            child: Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
              child: const Icon(Ionicons.checkmark, size: 40, color: AppColors.blue),
            ),
          ),
          FadeTransition(
            opacity: _contentOpacity,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Text('Application submitted!', style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 22, fontWeight: AppFontWeight.semibold)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    noOrphan("Track every update in the Applications tab."),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: PillButton(
                    label: 'View my applications',
                    onPressed: () {
                      // Resolve the router from sheetContext *before* popping,
                      // not the outer `context` — this function is called with
                      // the *screening* sheet's own context, which is already
                      // popped and defunct by the time this success sheet opens,
                      // so go_router can't resolve a route through it at all.
                      // sheetContext belongs to this sheet's own still-live
                      // subtree; resolving the router first (rather than calling
                      // sheetContext.go after popping) sidesteps any question of
                      // whether sheetContext is still valid post-pop.
                      final router = GoRouter.of(sheetContext);
                      Navigator.of(sheetContext).pop();
                      // Route through the Applications tab itself, not straight
                      // to this one application — a user testing this couldn't
                      // find where updates would show up later, because the old
                      // flow skipped past the tab entirely.
                      router.go('/tabs/browse');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pre-apply screening sheet — Naukri's "just a couple minutes" pattern:
/// a couple of company-voice questions with tappable quick-answer badges
/// (search-suggest style, reusing [AppChip]) plus a free-text fallback so
/// nobody's ever blocked by an option that doesn't fit, then an optional
/// note to the recruiter.
class _ScreeningSheet extends StatefulWidget {
  final Opportunity opportunity;
  final VoidCallback? onApplied;
  const _ScreeningSheet({required this.opportunity, this.onApplied});

  @override
  State<_ScreeningSheet> createState() => _ScreeningSheetState();
}

class _ScreeningSheetState extends State<_ScreeningSheet> {
  late final List<TextEditingController> _answerControllers;
  late final TextEditingController _noteController;
  // Explicit per-question "which chip did they actually tap" state — not
  // derived from string-equality against the typed text, which used to
  // highlight a chip whenever a manually-typed answer happened to match an
  // option's wording, and un-highlight a genuinely tapped chip the instant
  // it was edited by one character.
  late final List<String?> _selectedChip;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _answerControllers = List.generate(widget.opportunity.screeningQuestions.length, (_) => TextEditingController());
    _selectedChip = List.filled(widget.opportunity.screeningQuestions.length, null);
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in _answerControllers) {
      c.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    final answers = <String, String>{};
    for (var i = 0; i < widget.opportunity.screeningQuestions.length; i++) {
      final value = _answerControllers[i].text.trim();
      if (value.isNotEmpty) answers[widget.opportunity.screeningQuestions[i]] = value;
    }
    final note = _noteController.text.trim();
    final repositories = context.read<Repositories>();
    final result = await repositories.applications.createApplication(
      widget.opportunity.id,
      note: note.isEmpty ? null : note,
      screeningAnswers: answers.isEmpty ? null : answers,
    );
    // Genuinely async now (the repository call above awaits) — unlike
    // before, the sheet could have been dismissed while that was in
    // flight, so every context use below needs this guard.
    if (!mounted) return;

    if (result == null) {
      // The opportunity vanished between the gate and here — nothing was
      // created. Don't fire onApplied or show the "submitted!" sheet.
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This one's no longer taking applications — sorry about that.")),
      );
      return;
    }

    final appState = context.read<AppState>();
    // Clear a pending "you were applying to X" reminder once that exact
    // apply goes through — read before any context.mounted check below.
    if (appState.pendingApplyOpportunityId == widget.opportunity.id) {
      appState.setPendingApplyOpportunity(null);
    }
    // The single cross-screen signal: every context.watch<AppState>()
    // screen rebuilds and every dataVersion-gated screen re-loads, so an
    // applied job flips to "Applied ✓" (and shows on the Applications tab)
    // everywhere at once, not just on the screen that triggered the apply.
    appState.bumpDataVersion();
    widget.onApplied?.call();

    final parentContext = context;
    if (!parentContext.mounted) return;
    Navigator.of(parentContext).pop();

    if (!result.isNew) {
      // Dedupe hit (double-tap, or re-applying via the resume-gate path) —
      // no new application, so skip the full celebration.
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text("You've already applied — check Applications.")),
      );
      return;
    }
    HapticFeedback.heavyImpact();
    _showSuccessSheet(parentContext);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.opportunity;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (sheetContext, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: AppSpacing.xxl,
                  height: AppSpacing.xs,
                  decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Text('Just a minute before you apply', style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 20)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  // Most opportunities in the mock catalog set no screening
                  // questions at all — the "would like to know a bit more"
                  // framing only makes sense when questions actually follow
                  // it below; otherwise it read as a broken promise.
                  noOrphan(
                    o.screeningQuestions.isNotEmpty
                        ? '${o.company} would like to know a bit more.'
                        : 'Add a quick note before you apply (optional).',
                  ),
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                ),
              ),
              for (var i = 0; i < o.screeningQuestions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.screeningQuestions[i], style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium, fontSize: 16)),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: (i < o.screeningQuestionOptions.length ? o.screeningQuestionOptions[i] : const <String>[])
                              .map((opt) => AppChip(
                                    label: opt,
                                    selected: _selectedChip[i] == opt,
                                    onPressed: () => setState(() {
                                      _selectedChip[i] = opt;
                                      _answerControllers[i].text = opt;
                                    }),
                                  ))
                              .toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: TextField(
                          controller: _answerControllers[i],
                          // A manual edit means whatever was tapped (if
                          // anything) no longer reflects what's actually in
                          // the field — clear the explicit selection so no
                          // chip stays lit for text the user has since
                          // changed.
                          onChanged: (_) => setState(() => _selectedChip[i] = null),
                          maxLength: 200,
                          style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14),
                          // No counterText override — hiding the built-in
                          // counter meant keystrokes silently stopped
                          // registering at the cap with no visible reason.
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Or type your own answer',
                            hintStyle: AppTextStyles.body.copyWith(color: AppColors.gray400, fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.blue, width: 2)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Text('Note to recruiter (optional)', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium, fontSize: 16)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 3,
                    maxLength: 300,
                    style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'e.g. Available to start immediately',
                      hintStyle: AppTextStyles.body.copyWith(color: AppColors.gray400, fontSize: 14),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: PillButton(label: 'Send Application', onPressed: _send, loading: _sending),
              ),
              // Same de-emphasized dismiss link as the gate sheet one step
              // earlier — without it, this sheet was the one step in the
              // apply flow with no way to back out short of dragging it
              // closed or tapping the scrim.
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: GestureDetector(
                  onTap: _sending ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Not now',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.gray400, fontSize: 12, fontWeight: AppFontWeight.medium),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
