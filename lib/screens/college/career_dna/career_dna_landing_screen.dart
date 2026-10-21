import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
import '../../../models/career_dna.dart';
import '../../../models/user.dart';
import '../../../state/app_state.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/shadows.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/no_orphan.dart';
import '../../../utils/scroll_to_top_registry.dart';
import '../../../widgets/app_page.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/responsive_body.dart';
import '../../../widgets/adaptive_sheet.dart';

// Alternating horizontal position per node (center/right/center-left/left/
// center-right) — the zigzag is what reads as "a path to walk," per the
// Duolingo-style reference, without needing a literal drawn connector line.
const _pathXAlign = [0.0, 0.55, -0.2, -0.55, 0.2];

/// Landing / level-map screen — the tab root for the 6th branch
/// (`/tabs/career-dna`). A Duolingo-style path: a header banner naming only
/// the ONE level currently being worked on (not a repeated list of every
/// level's own title), then a vertical zigzag of 5 circular nodes standing
/// in for the old flat list of level cards.
class CareerDnaLandingScreen extends StatefulWidget {
  const CareerDnaLandingScreen({super.key});

  @override
  State<CareerDnaLandingScreen> createState() => _CareerDnaLandingScreenState();
}

class _CareerDnaLandingScreenState extends State<CareerDnaLandingScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Branch index 5 (Career Quiz) — see router.dart's StatefulShellRoute.
    ScrollToTopRegistry.register(5, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(5);
    _scrollController.dispose();
    super.dispose();
  }

  void _openLevel(BuildContext context, int level, bool unlocked, bool completed) {
    if (!unlocked) {
      HapticFeedback.selectionClick();
      return;
    }
    HapticFeedback.selectionClick();
    // A completed level's node opens straight to its report — routing
    // through the intro screen again would only ever offer "Start Level N"
    // there, reading as an invitation to retake it rather than review what
    // was already earned. (A genuine retake is still one tap away from the
    // report screen itself.) Level 5 is the one exception — its result is
    // a cross-test synthesis, not a per-level report, so it has its own
    // dedicated final-report screen instead of the generic /report route.
    if (completed && level == 5) {
      context.push('/college/career-dna/final-report');
      return;
    }
    context.push(completed ? '/college/career-dna/level/$level/report' : '/college/career-dna/level/$level/intro');
  }

  bool _isLevelComplete(CareerDnaProfile p, int level) {
    switch (level) {
      case 1:
        return p.level1 != null;
      case 2:
        return p.level2 != null;
      case 3:
        return p.level3 != null;
      case 4:
        return p.level4 != null;
      case 5:
        return p.level5 != null;
      default:
        return false;
    }
  }

  // ---------------------------------------------------------------------------------------------
  // Tablet and desktop layout. The phone layout in build() below is unchanged.
  // ---------------------------------------------------------------------------------------------

  Widget _infoCard() {
    return TintCard(
      radius: AppRadius.md,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Ionicons.ribbon_outline, size: 18, color: AppColors.blue)),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Free 10-min career test', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('Stand out to recruiters with an international-standard assessment, added to your resume.', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pathColumn(BuildContext context, User? user, CareerDnaProfile profile, CareerDnaLevelMeta? currentMeta, {required double inset}) {
    return Column(
      children: [
        for (final meta in careerDnaLevelMeta)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl + AppSpacing.md),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: _PathNode(
                meta: meta,
                xAlign: _pathXAlign[(meta.level - 1) % _pathXAlign.length],
                unlocked: user?.isCareerDnaLevelUnlocked(meta.level) ?? (meta.level == 1),
                completed: _isLevelComplete(profile, meta.level),
                isCurrent: currentMeta?.level == meta.level,
                onTap: () => _openLevel(context, meta.level, user?.isCareerDnaLevelUnlocked(meta.level) ?? (meta.level == 1), _isLevelComplete(profile, meta.level)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _seeResultsCard() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/college/career-dna/final-report'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.card),
          child: Row(
            children: [
              const Icon(Ionicons.star, size: 22, color: AppColors.yellow),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('See your full results', style: AppTextStyles.bodyLg.copyWith(color: AppColors.white, fontWeight: AppFontWeight.semibold)),
                    Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text('Every level, combined into one result.', style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70))),
                  ],
                ),
              ),
              const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.whiteA70),
            ],
          ),
        ),
      ),
    );
  }

  /// "Up next" with the level's description, its length and a Start button.
  Widget _upNextCard(CareerDnaLevelMeta meta, User? user, CareerDnaProfile profile) {
    final unlocked = user?.isCareerDnaLevelUnlocked(meta.level) ?? (meta.level == 1);
    return SurfaceCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('UP NEXT', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium, letterSpacing: 0.8)),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text('Level ${meta.level} · ${meta.title}', style: AppTextStyles.h2.copyWith(color: AppColors.ink))),
          Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(meta.whatThisMeasures, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13, height: 1.5))),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Row(
              children: [
                const Icon(Ionicons.time_outline, size: 14, color: AppColors.gray500),
                const SizedBox(width: AppSpacing.xs),
                Text(meta.estTime, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                const SizedBox(width: AppSpacing.md),
                const Icon(Ionicons.help_circle_outline, size: 14, color: AppColors.gray500),
                const SizedBox(width: AppSpacing.xs),
                Text('${meta.questionCount} questions', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg - 4),
            child: PillButton(label: 'Start Level ${meta.level}', disabled: !unlocked, onPressed: () => _openLevel(context, meta.level, unlocked, _isLevelComplete(profile, meta.level))),
          ),
        ],
      ),
    );
  }

  Widget _levelList(User? user, CareerDnaProfile profile, CareerDnaLevelMeta? currentMeta) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.soft),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final meta in careerDnaLevelMeta)
            Builder(builder: (context) {
              final unlocked = user?.isCareerDnaLevelUnlocked(meta.level) ?? (meta.level == 1);
              final done = _isLevelComplete(profile, meta.level);
              final action = done ? 'Report' : (currentMeta?.level == meta.level ? 'Start' : '');
              return MouseRegion(
                cursor: unlocked ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openLevel(context, meta.level, unlocked, done),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md - 2),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: meta.level == careerDnaLevelMeta.length ? Colors.transparent : AppColors.border))),
                    child: Opacity(
                      opacity: unlocked ? 1 : 0.5,
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: done ? AppColors.success : (unlocked ? AppColors.blue : AppColors.gray100), shape: BoxShape.circle),
                            child: Icon(done ? Ionicons.checkmark : (unlocked ? Ionicons.star : Ionicons.lock_closed), size: 14, color: done ? AppColors.white : (unlocked ? AppColors.white : AppColors.gray400)),
                          ),
                          const SizedBox(width: AppSpacing.md - 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Level ${meta.level}', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 13, fontWeight: AppFontWeight.semibold)),
                                Text(meta.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(action, style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.semibold)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context, User? user, CareerDnaProfile profile, CareerDnaLevelMeta? currentMeta, bool allComplete) {
    final expanded = AppBreakpoints.isExpanded(context);
    final gutter = AppBreakpoints.gutter(context);
    final cap = AppBreakpoints.maxContentFor(context);
    final subtitle = currentMeta != null ? 'Level ${currentMeta.level} · ${currentMeta.title}' : 'All 5 levels complete!';

    Widget header() => Container(
          width: double.infinity,
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cap),
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, AppSpacing.xl, gutter, AppSpacing.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Career Quiz', style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontSize: 26)),
                      Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(subtitle, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, fontWeight: AppFontWeight.medium))),
                      Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text('Approved by 100+ Psychologists, Researchers, PhDs and Business Leaders.', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

    return Material(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cap),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, AppSpacing.xl, gutter, AppSpacing.xxl),
                    child: expanded
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: _pathColumn(context, user, profile, currentMeta, inset: 80))),
                              const SizedBox(width: AppSpacing.xl + AppSpacing.sm),
                              SizedBox(
                                width: 340,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _infoCard(),
                                    const SizedBox(height: AppSpacing.md),
                                    if (allComplete) _seeResultsCard() else if (currentMeta != null) _upNextCard(currentMeta, user, profile),
                                    const SizedBox(height: AppSpacing.md),
                                    _levelList(user, profile, currentMeta),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _infoCard(),
                              const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
                              _pathColumn(context, user, profile, currentMeta, inset: AppSpacing.xxxl),
                              if (allComplete) _seeResultsCard(),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;

    // This whole feature is college-only. The tab is already hidden for a
    // school account (tabs_scaffold.dart), but nothing else stops a stale
    // deep link from reaching this route directly — bounce back to Home
    // rather than rendering a screen built for a segment that has no
    // Career DNA data at all.
    if (user?.segment == Segment.school) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/tabs');
      });
      return const SizedBox.shrink();
    }

    final profile = user?.careerDnaOrEmpty ?? const CareerDnaProfile();
    final topInset = MediaQuery.of(context).padding.top;
    final allComplete = profile.allLevelsComplete;
    // The one level the header banner names — the first not-yet-completed
    // one (which, by sequential unlocking, is always the unlocked one to
    // work on next). Mirrors Duolingo's own "just the current unit" header,
    // rather than repeating every level's full title on screen at once.
    final currentMeta = allComplete ? null : careerDnaLevelMeta.firstWhere((m) => !_isLevelComplete(profile, m.level));
    // A modest widen only, not the 1200/900 other tabs got — this screen's
    // content is one linear zigzag path (see _pathXAlign above), not
    // independent listings, so there's nothing to tab or grid here; this
    // just stops it sitting razor-thin in a sea of white space at desktop.
    final isTablet = AppBreakpoints.isWide(context);
    if (isTablet) return _buildWide(context, user, profile, currentMeta, allComplete);

    return Scaffold(
      backgroundColor: AppColors.white,
      // A single ListView, not a fixed header + separately-scrolling
      // Expanded below it — per direct feedback reversing an earlier
      // "keep the header pinned" decision, which left too little room for
      // the path once TopNavBar also started taking space above it at
      // desktop. The header is still deliberately NOT wrapped in
      // ResponsiveBody (same full-bleed pattern as profile_screen.dart's
      // header) so it spans true full width regardless of window size; the
      // path content right below it gets its own ResponsiveBody cap
      // instead, same as before.
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            // Only the background bleeds full-bleed — the text inside stays
            // aligned to the exact same horizontal padding as the content
            // below it (same ResponsiveBody maxWidth), so it doesn't read
            // as pinned to the true screen edge while everything else sits
            // inset in a narrower centered column.
            child: ResponsiveBody(
              maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth,
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
                // Full width, so on a tablet the heading lines up with the content below it. Without
                // this the column shrinks to its widest line and ResponsiveBody centres it.
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The heading always reads "Career Quiz", regardless of
                    // which level is current — per direct feedback that
                    // swapping the heading itself to the current level's own
                    // title read as confusing copy. The line beneath names
                    // the current level instead. (No separate eyebrow label
                    // above this any more — it used to duplicate the same
                    // "Career Quiz" text twice in a row.)
                    Text('Career Quiz', style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 26, fontWeight: AppFontWeight.semibold)),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        noOrphan(currentMeta != null ? 'Level ${currentMeta.level} · ${currentMeta.title}' : 'All 5 levels complete!'),
                        style: AppTextStyles.bodyLg.copyWith(color: AppColors.whiteA70, fontSize: 14),
                      ),
                    ),
                    // Small trust line — deliberately lighter/smaller than
                    // the subtitle above (size alone does the differentiation
                    // here, both share whiteA70) so it reads as secondary
                    // credibility copy, not competing with the level name.
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        noOrphan('Approved by 100+ Psychologists, Researchers, PhDs and Business Leaders.'),
                        style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
          ResponsiveBody(
            maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth,
            child: Padding(
              // Generous vertical rhythm between nodes (xxxl, not the old
              // list's tight md gaps) is what makes this read as "spacious"
              // rather than a dense list — the zigzag alignment does the rest.
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // What taking the quiz actually does for the student — the
                  // free test's result rides along with their resume for
                  // recruiters to see. Same message as the Home promo card.
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.blueA10,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Ionicons.ribbon_outline, size: 18, color: AppColors.blue),
                        ),
                        const SizedBox(width: AppSpacing.md - 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Free 10-min career test',
                                style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 14, fontWeight: AppFontWeight.semibold),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  noOrphan('Stand out to recruiters with an international-standard assessment, added to your resume.'),
                                  style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final meta in careerDnaLevelMeta)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                      child: _PathNode(
                        meta: meta,
                        xAlign: _pathXAlign[(meta.level - 1) % _pathXAlign.length],
                        unlocked: user?.isCareerDnaLevelUnlocked(meta.level) ?? (meta.level == 1),
                        completed: _isLevelComplete(profile, meta.level),
                        isCurrent: currentMeta?.level == meta.level,
                        onTap: () => _openLevel(
                          context,
                          meta.level,
                          user?.isCareerDnaLevelUnlocked(meta.level) ?? (meta.level == 1),
                          _isLevelComplete(profile, meta.level),
                        ),
                      ),
                    ),
                  if (allComplete)
                    GestureDetector(
                      onTap: () => context.push('/college/career-dna/final-report'),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
                        child: Row(
                          children: [
                            const Icon(Ionicons.star, size: 22, color: AppColors.yellow),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('See your full results', style: AppTextStyles.bodyLg.copyWith(color: AppColors.white, fontWeight: AppFontWeight.semibold)),
                                  Padding(
                                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                                    child: Text('Every level, combined into one result.', style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.whiteA70),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ],
        ),
    );
  }
}

class _PathNode extends StatelessWidget {
  final CareerDnaLevelMeta meta;
  final double xAlign;
  final bool unlocked;
  final bool completed;
  final bool isCurrent;
  final VoidCallback onTap;

  const _PathNode({
    required this.meta,
    required this.xAlign,
    required this.unlocked,
    required this.completed,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !unlocked;
    final size = isCurrent ? 68.0 : 56.0;

    Widget circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: completed ? AppColors.success : (locked ? AppColors.gray100 : AppColors.blue),
        shape: BoxShape.circle,
        boxShadow: locked ? null : AppShadows.card,
      ),
      child: Icon(
        completed ? Ionicons.checkmark : (locked ? Ionicons.lock_closed : Ionicons.star),
        size: isCurrent ? 30 : 24,
        color: locked ? AppColors.gray400 : AppColors.white,
      ),
    );

    // Current level's node gets a lighter ring around it (target-style,
    // matching the reference) so it visually reads as "you are here"
    // without needing a separate label every time.
    if (isCurrent) {
      circle = Container(
        width: size + 14,
        height: size + 14,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
        child: circle,
      );
    }

    return Align(
      alignment: Alignment(xAlign, 0),
      // The level's tap lives on the circle and on the labels, NOT around the whole
      // column: the (i) tooltip icon sits in that column, and when the node's tap
      // wrapped it, a tap on the icon opened the level instead of showing the tooltip.
      child: Opacity(
          opacity: locked ? 0.5 : 1.0,
          child: Column(
            children: [
              if (isCurrent)
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Text('START', style: AppTextStyles.label.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.bold, letterSpacing: 0.6)),
                  ),
                ),
              GestureDetector(onTap: onTap, child: circle),
              // Shows the level's title beneath its number on every node
              // (not just the current one) — per direct feedback that
              // tapping a completed level jumped straight to its report
              // with no way to first see which level that was. A fixed
              // width keeps this from overflowing the screen edge at the
              // zigzag's more off-center x positions.
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: SizedBox(
                  width: 128,
                  child: Column(
                    children: [
                      // Tap-to-reveal info icon, same trigger/idiom already
                      // used for the match-% explanation elsewhere in this
                      // app (Tooltip + triggerMode.tap, not the default
                      // long-press) — lets a student preview what a test is
                      // about before opening it, for every node regardless
                      // of lock state. Nested inside the node's own outer
                      // GestureDetector; Flutter's gesture arena lets this
                      // inner tap win, so it never also opens the level.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: onTap,
                            child: Text(
                              'Level ${meta.level}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12, fontWeight: AppFontWeight.semibold),
                            ),
                          ),
                          // Tap the (i) for what the level measures. It opens a small card
                          // that stays until closed (a Tooltip faded away before it could be
                          // read, and was hard to trigger on an unlocked level). The padding
                          // makes the tap target about 36x28 instead of the 14px icon.
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showLevelInfo(context, meta),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                              child: Icon(Ionicons.information_circle_outline, size: 14, color: AppColors.gray500),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: onTap,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            meta.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, height: 1.25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

/// "What this level measures", as a card that stays until the student closes it.
void _showLevelInfo(BuildContext context, CareerDnaLevelMeta meta) {
  showAdaptiveSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(sheetContext).padding.bottom + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xs,
              decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text(
              'Level ${meta.level} · ${meta.title}',
              style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
            child: Text(
              noOrphan(meta.whatThisMeasures),
              style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, height: 1.5),
            ),
          ),
          PillButton(label: 'Got it', onPressed: () => Navigator.of(sheetContext).pop()),
        ],
      ),
    ),
  );
}
