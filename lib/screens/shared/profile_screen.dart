import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/profile_readiness.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/initials.dart';
import '../../utils/no_orphan.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../utils/support_hint_prefs_key.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/badges.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/responsive_body.dart';
import 'video_profile_screen.dart';
import '../../widgets/adaptive_sheet.dart';

const _segmentLabels = {Segment.school: 'School Student', Segment.ug: 'Undergraduate', Segment.pg: 'Postgraduate', Segment.working: 'Working'};

// Mirrors micro_profile_screen.dart's own `_segmentOptions` (the college/
// working choice a fresh college signup already makes) — reused here so
// "Switch to College" offers exactly the same 3 destinations, not a new,
// possibly-inconsistent set.
const _switchSegmentOptions = [(Segment.ug, 'Undergraduate'), (Segment.pg, 'Postgraduate'), (Segment.working, 'Working')];

class _ProfileRow {
  final IconData icon;
  final String label;
  final String? route;

  /// Optional override for what tapping the row does — used by rows that
  /// open a bottom sheet (e.g. "Switch to College") instead of navigating
  /// to a route. Takes precedence over `route` when both are set (not the
  /// case for any row today).
  final VoidCallback? onTap;
  const _ProfileRow({required this.icon, required this.label, this.route, this.onTap});
}

/// "Saved" is college-only — school users never bookmark opportunities.
List<_ProfileRow> _rowsFor(bool isSchool) => [
  if (!isSchool) const _ProfileRow(icon: Ionicons.bookmark_outline, label: 'Saved', route: '/saved'),
  const _ProfileRow(icon: Ionicons.calendar_outline, label: 'Bookings', route: '/tabs/sessions'),
  // College-only, same as Saved — school users have no Applications tab
  // to have swipe-deleted anything from in the first place.
  if (!isSchool) const _ProfileRow(icon: Ionicons.trash_outline, label: 'Recently Deleted', route: '/applications/recently-deleted'),
  // Re-enabled — see router.dart's /support route comment. Without
  // this, neither segment had any Help/Support entry point at all.
  const _ProfileRow(icon: Ionicons.help_circle_outline, label: 'Support & Help', route: '/support'),
];

/// Mirrors frontend/src/screens/ProfileScreen.tsx (ProfileScreen).
/// Hosted as the "Profile" tab in TabsScaffold. Naukri-style: information
/// sectioned into per-category cards instead of one long settings form, so
/// nothing reads as overwhelming and each card shows what's actually filled
/// in rather than just a label.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _scrollController = ScrollController();
  // Defaults true (hint hidden) so nothing flashes on screen before the
  // real saved value loads — same "seen once" idiom as the Applications
  // swipe hint, gating a single targeted badge on "Support & Help" (which
  // had zero prior exposure to any user before Round U re-enabled it), not
  // a general tour system.
  bool _supportHintSeen = true;
  // Desktop-only — collapsed by default so Basic details' card height
  // (name/city/college/goal/role tags, easily the longest content of the
  // 4 paired cards) matches its row partner instead of visibly dwarfing it.
  // Mobile/tablet never paginate cards into rows, so this is never read
  // there and the content always shows in full, same as before this round.
  bool _basicDetailsExpanded = false;

  @override
  void initState() {
    super.initState();
    // Branch index 4 (Profile) — see router.dart's StatefulShellRoute.
    ScrollToTopRegistry.register(4, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    _loadSupportHint();
  }

  Future<void> _loadSupportHint() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _supportHintSeen = prefs.getBool(supportHintSeenPrefsKey) ?? false);
  }

  Future<void> _markSupportHintSeen() async {
    if (_supportHintSeen) return;
    setState(() => _supportHintSeen = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(supportHintSeenPrefsKey, true);
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(4);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    // Same confirm-dialog shell as the "Delete forever?" dialog in
    // recently_deleted_applications_screen.dart, but blue, not red, for
    // the "Log out" action — logging out is reversible (sign back in any
    // time), unlike a permanent delete, so it doesn't need the same
    // severity signal.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text(
          'Log out?',
          style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.semibold),
        ),
        content: Text(
          "You'll need to sign in again to get back to your account.",
          style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Log out',
              style: AppTextStyles.body.copyWith(color: AppColors.blue, fontWeight: AppFontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final appState = context.read<AppState>();
    await appState.logout();
    if (!context.mounted) return;
    context.go('/onboarding');
  }


  void _editBasics(BuildContext context) => context.push('/profile-edit?returnTo=%2Ftabs%2Fprofile');
  // /college/resume, not /college/resume/build directly — that screen is
  // the one that actually offers both options (upload a PDF, or "Don't
  // have a PDF? Build it here"). Jumping straight to /build skipped the
  // choice entirely and always looked like build-only.
  void _editResume(BuildContext context) => context.push('/college/resume');

  /// The one path an already-onboarded School user has into the college
  /// flow — e.g. finished school onboarding, then genuinely started
  /// college this month and wants to browse internships/jobs, which School
  /// has no tab/screen for at all today.
  ///
  /// Deliberately reuses the exact "Goals → Home" tail a fresh College
  /// signup already completes (flip `segment` + `onboardingComplete:
  /// false`, land on `/college/goals`) instead of either re-routing
  /// through `/onboarding/profile` (which would mean touching the
  /// `_authEntryRoutes`/redirect logic already responsible for two subtle
  /// bugs earlier this session) or building a whole new form screen —
  /// `goals_screen.dart`/`resume_builder_quiz_screen.dart` have no segment
  /// guard of their own, so this is safe. School-only fields
  /// (`currentClass`, `board`, `aptitudeResults`, ...) are left as
  /// harmless unread carryover, same treatment this app already gives
  /// UG↔PG course/college values on a segment change during onboarding.
  void _showSwitchToCollegeSheet(BuildContext context) {
    Segment? chosen;
    showAdaptiveSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl + MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                child: const Icon(Ionicons.school, size: 28, color: AppColors.blue),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text('Switch to College', style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 20, fontWeight: AppFontWeight.semibold)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  "Unlock internships, job applications, and the resume builder. Your aptitude results and booked sessions stay saved — fill in your college details from Profile whenever you're ready.",
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, height: 1.4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _switchSegmentOptions
                      .map((s) => AppChip(
                            label: s.$2,
                            selected: chosen == s.$1,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setSheetState(() => chosen = s.$1);
                            },
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: 'Continue',
                    disabled: chosen == null,
                    onPressed: chosen == null
                        ? null
                        : () {
                            final segment = chosen!;
                            context.read<AppState>().updateProfile((current) => current.copyWith(segment: segment, onboardingComplete: false));
                            Navigator.of(sheetContext).pop();
                            context.go('/college/goals');
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final isSchool = user?.segment == Segment.school;
    final rows = [
      ..._rowsFor(isSchool),
      // School-only — the one way an already-onboarded School user (e.g.
      // just started college this month) can reach the college flow at
      // all. See _showSwitchToCollegeSheet's own doc comment for the full
      // design rationale.
      if (isSchool) _ProfileRow(icon: Ionicons.school_outline, label: 'Switch to College', onTap: () => _showSwitchToCollegeSheet(context)),
    ];
    final topInset = MediaQuery.of(context).padding.top;
    final resume = user?.resume;
    final hasResume = user?.hasResume ?? false;
    final hasPhoto = user?.hasPhoto ?? false;
    // Single source of truth for every card's done/not-done badge below —
    // same profileChecklist the Home feed's completion dial and _BoostTip
    // both read, so this screen can't silently disagree with them.
    final checklist = {for (final i in user?.profileChecklist ?? const []) i.id: i.done};
    final isTablet = AppBreakpoints.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      // A single ListView, not a fixed header + separately-scrolling
      // Expanded below it — a pinned header ate into how much of the page
      // showed per fold, especially with TopNavBar also taking space above
      // it at desktop. The header is still deliberately NOT wrapped in
      // ResponsiveBody at the Container level — its background is a true
      // full-bleed banner (see ResponsiveBody's own doc comment, and
      // landing_screen.dart's identical pattern) — but its own text/avatar
      // content now gets the SAME ResponsiveBody(maxWidth) + padding as the
      // section cards below, so it aligns with them instead of hugging the
      // true screen edge while the cards sit inset in a narrower column.
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isTablet ? AppColors.white : AppColors.blue,
              border: isTablet ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
              borderRadius: isTablet ? null : const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: ResponsiveBody(
              maxWidth: isTablet ? AppBreakpoints.maxContentFor(context) : AppBreakpoints.maxContentWidth,
              child: Padding(
                padding: isTablet ? EdgeInsets.symmetric(horizontal: AppBreakpoints.gutter(context), vertical: AppSpacing.xl) : EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
                // Desktop: a compact horizontal strip (avatar beside the
                // text block), matching how thin Career Quiz's own header
                // reads — the original vertical, centered stack (avatar
                // above name above email above badge above progress ring)
                // was sized for a phone screen and read as a wall of blue
                // taking up most of the first fold on a wide window.
                // Mobile/tablet keep that original stacked layout unchanged.
                child: isTablet
                    ? Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                            child: user?.photoUrl != null
                                ? ClipOval(child: Image.network(user!.photoUrl!, width: 72, height: 72, fit: BoxFit.cover))
                                : Text(
                                    initialsFor(user?.name),
                                    style: AppTextStyles.h2.copyWith(color: AppColors.white, fontSize: 26, fontWeight: AppFontWeight.semibold),
                                  ),
                          ),
                          const SizedBox(width: AppSpacing.lg - 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user?.name ?? 'Student',
                                  style: AppTextStyles.h1.copyWith(color: AppColors.ink),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(user?.identifier ?? '', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                          if (!isTablet || AppBreakpoints.isExpanded(context)) ...[
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.pill)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Ionicons.ribbon, size: 13, color: AppColors.blue),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  _segmentLabels[user?.segment] ?? 'Student',
                                  style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
                                ),
                              ],
                            ),
                          ),
                          ],
                          if (!isSchool) ...[
                            const SizedBox(width: AppSpacing.md),
                            ProgressRing(
                              percent: user?.profileProgressPercent ?? 0,
                              size: 44,
                              background: AppColors.gray100,
                              valueColor: AppColors.blue,
                              textColor: AppColors.ink,
                            ),
                            if (AppBreakpoints.isExpanded(context)) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Text('${user?.profileCompletedCount ?? 0}/${user?.profileTotalCount ?? 0} sections\ncomplete', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                            ],
                          ],
                          const SizedBox(width: AppSpacing.md),
                          PillButton(label: 'Edit profile', icon: Ionicons.create_outline, variant: PillVariant.secondary, full: false, compact: true, onPressed: () => _editBasics(context)),
                        ],
                      )
                    : Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                    child: user?.photoUrl != null
                        ? ClipOval(child: Image.network(user!.photoUrl!, width: 84, height: 84, fit: BoxFit.cover))
                        : Text(
                            initialsFor(user?.name),
                            style: AppTextStyles.h1.copyWith(color: AppColors.blue, fontSize: 30, fontWeight: AppFontWeight.semibold),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      user?.name ?? 'Student',
                      style: AppTextStyles.h2.copyWith(color: AppColors.white, fontSize: 22, fontWeight: AppFontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(user?.identifier ?? '', style: AppTextStyles.body.copyWith(color: AppColors.whiteA70, fontSize: 14)),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.md),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Ionicons.ribbon, size: 13, color: AppColors.blue),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _segmentLabels[user?.segment] ?? 'Student',
                          style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
                        ),
                      ],
                    ),
                  ),
                  // School users' Profile tab only ever has the one Basic
                  // details section (see profile_readiness.dart's segment
                  // branch on profileChecklist), so a completion dial here
                  // would just be a permanent, meaningless 100-or-0 — skip it
                  // rather than show a ring that can't say anything useful.
                  if (!isSchool)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ProgressRing(
                            percent: user?.profileProgressPercent ?? 0,
                            size: 36,
                            background: AppColors.whiteA20,
                            valueColor: AppColors.yellow,
                            textColor: AppColors.white,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${user?.profileCompletedCount ?? 0}/${user?.profileTotalCount ?? 0} sections complete',
                            style: AppTextStyles.caption.copyWith(color: AppColors.whiteA70, fontSize: 12, fontWeight: AppFontWeight.medium),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              ),
            ),
          ),
          ResponsiveBody(
            // 1224, matching every other desktop tab (Home/Applications/
            // Courses) — a screen-specific width here made the horizontal
            // gutter next to the sidebar visibly inconsistent between tabs.
            maxWidth: isTablet ? AppBreakpoints.maxContentFor(context) : AppBreakpoints.maxContentWidth,
            child: Padding(
              padding: isTablet ? EdgeInsets.symmetric(horizontal: AppBreakpoints.gutter(context), vertical: AppSpacing.xl) : const EdgeInsets.all(AppSpacing.xl),
              child: Builder(builder: (context) {
                // Extracted to a list so desktop can lay these 4 out as a
                // 2-column block grid (standard "Card/Block Layout" web
                // pattern) instead of one long single-file column floating
                // in the wide leftover space next to the sidebar — mobile/
                // tablet keep the exact original flat, stacked order.
                final sectionCards = <Widget>[
                  if (!isSchool)
                    _SectionCard(
                      title: 'Resume',
                      icon: Ionicons.document_text_outline,
                      done: checklist['resume'],
                      onTap: () => _editResume(context),
                      child: hasResume
                          ? Text(
                              _skillsSummary(resume?.skills ?? const []),
                              style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12),
                            )
                          : Text(
                              'Add your resume so recruiters can find you.',
                              style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12),
                            ),
                    ),
                  // Basic details and Goals & roles used to be two separate
                  // cards, but both ever did was open the same /profile-edit
                  // form at a different scroll position — reading as two
                  // things when it's really one edit destination. Combined
                  // into a single card. Goals no longer has its own
                  // checklist entry (see profile_readiness.dart) — its
                  // content still shows inline below, it just no longer
                  // gates this card's own checkmark.
                  _SectionCard(
                    title: 'Basic details',
                    icon: Ionicons.person_outline,
                    done: checklist['basic'],
                    onTap: () => _editBasics(context),
                    // Collapsed only at desktop, and only when not expanded —
                    // mobile/tablet always render the full version below,
                    // same as before this round. Collapsed: name + one
                    // combined line (city/college merged into one, instead
                    // of Basic details' original 3 separate lines) + up to 3
                    // role tags — this card was by far the tallest of the 4
                    // paired ones (name/city/college/goal/role tags all on
                    // their own lines), visibly dwarfing Resume/Photo/Video
                    // next to it in the same row.
                    child: (isTablet && !_basicDetailsExpanded)
                        ? _BasicDetailsCollapsed(
                            user: user,
                            isSchool: isSchool,
                            onViewMore: () => setState(() => _basicDetailsExpanded = true),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._basicDetailLines(user, isSchool).asMap().entries.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                  child: Text(
                                    noOrphan(e.value),
                                    // Medium, not semibold — the card title above
                                    // (now bold) is the heading; the name is this
                                    // card's content and shouldn't compete with
                                    // it at nearly the same weight.
                                    style: e.key == 0
                                        ? AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium)
                                        : AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12),
                                  ),
                                ),
                              ),
                              if (!isSchool) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                                  child: Text(_goalLabel(user?.goal), style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12)),
                                ),
                                if (user?.roles?.isNotEmpty ?? false)
                                  Padding(
                                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                                    child: Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: user!.roles!.map((r) => AppTag(label: r)).toList(),
                                    ),
                                  ),
                              ],
                              if (isTablet)
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _basicDetailsExpanded = false),
                                    child: Text(
                                      'View less',
                                      style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.semibold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  // College-only, same reasoning as Video profile below —
                  // school's Profile tab only ever shows Basic details.
                  if (!isSchool)
                    _SectionCard(
                      title: 'Profile photo',
                      icon: Ionicons.camera_outline,
                      done: checklist['photo'],
                      onTap: () => _editBasics(context),
                      child: Text(
                        hasPhoto ? 'Photo added' : 'Add a photo so recruiters recognize you.',
                        style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12),
                      ),
                    ),
                  // College-only — a video pitch is a recruiter-facing
                  // signal. School users aren't applying to jobs yet, so this
                  // card stays out of their profile screen entirely — it
                  // should look exactly like it did before.
                  if (!isSchool)
                    _SectionCard(
                      title: 'Video profile',
                      icon: Ionicons.videocam_outline,
                      done: checklist['video'],
                      onTap: () => showVideoProfileSheet(context),
                      child: (user?.videoIntroUrl?.trim().isNotEmpty ?? false)
                          ? Row(
                              children: [
                                const Icon(Ionicons.play_circle, size: 16, color: AppColors.blue),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Video profile added',
                                  style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
                                ),
                              ],
                            )
                          : Text(
                              noOrphan('Pitch yourself with a short video.'),
                              style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12),
                            ),
                    ),
                ];

                final expandedWide = AppBreakpoints.isExpanded(context);
                final menuCard =
                  Container(
                    decoration: AppBreakpoints.isWide(context)
                        ? BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.border))
                        : BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.soft),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ...rows.asMap().entries.map((entry) {
                          final i = entry.key;
                          final r = entry.value;
                          final showSupportHint = r.route == '/support' && !_supportHintSeen;
                          return Semantics(
                            button: r.route != null || r.onTap != null,
                            label: r.label,
                            child: GestureDetector(
                              onTap: r.onTap ??
                                  (r.route == null
                                      ? null
                                      : () {
                                          if (r.route == '/support') _markSupportHintSeen();
                                          r.route!.startsWith('/tabs') ? context.go(r.route!) : context.push(r.route!);
                                        }),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border, width: 1)) : null,
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                                          child: Icon(r.icon, size: 20, color: AppColors.blue),
                                        ),
                                        // One-time discovery badge — same dot
                                        // visual language as the header's
                                        // filter/notification badges (blue
                                        // fill, white ring), gone for good
                                        // once this row is tapped once.
                                        if (showSupportHint)
                                          Positioned(
                                            top: -1,
                                            right: -1,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: AppColors.blue,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: AppColors.white, width: 1.5),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        r.label,
                                        style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium),
                                      ),
                                    ),
                                    const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                final logoutButton =
                  GestureDetector(
                    onTap: () => _logout(context),
                    child: Container(
                      margin: const EdgeInsets.only(top: AppSpacing.xl),
                      height: 54,
                      alignment: Alignment.center,
                      // Neutral, not error-red — logging out isn't data-
                      // destructive (nothing is lost or unrecoverable), unlike
                      // "Delete forever" in Recently Deleted, which genuinely
                      // is and correctly uses this same red elsewhere. Red
                      // here overstated the severity of a routine action.
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.gray400, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Ionicons.log_out_outline, size: 20, color: AppColors.gray500),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Log out',
                            style: AppTextStyles.bodyLg.copyWith(color: AppColors.gray500, fontSize: 16, fontWeight: AppFontWeight.medium),
                          ),
                        ],
                      ),
                    ),
                  );
                final versionLine =
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Text('Aerostar Edge • v1.0.0', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                  );
                if (expandedWide) {
                  // Expanded: the section cards (2 across) on the left; the menu, Log out and the
                  // version on the right in a 320px column.
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _pairedRows(sectionCards))),
                      const SizedBox(width: AppSpacing.xl),
                      SizedBox(
                        width: 320,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [menuCard, SizedBox(height: AppSpacing.lg), logoutButton, Center(child: versionLine)]),
                      ),
                    ],
                  );
                }
                return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isTablet) ..._pairedRows(sectionCards) else ...sectionCards,
                  menuCard,
                  logoutButton,
                  versionLine,
                ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays [cards] out 2-per-row (Expanded, top-aligned so mismatched card
/// heights don't force a shorter card to stretch) — the standard "Card/
/// Block Layout" web pattern, used only at desktop widths where there's
/// real room for two columns; mobile/tablet keep the original single
/// stacked column.
List<Widget> _pairedRows(List<Widget> cards) {
  final rows = <Widget>[];
  for (var i = 0; i < cards.length; i += 2) {
    final right = i + 1 < cards.length ? cards[i + 1] : null;
    // IntrinsicHeight + stretch, not top-aligned Expanded — Resume's short
    // one-line body next to Basic details' much longer one (name/city/
    // college/goal/role tags) left a tall gap under the short card before
    // the next row started, breaking the "tidy grid" look entirely. Same
    // equal-height-row mechanism already used everywhere else this round
    // (opportunity_list_screen.dart, applications_tracker_screen.dart,
    // college_feed_screen.dart's _rowsChunked) — every card's own
    // Container has no explicit height, so it simply fills whatever tight
    // height the row's tallest card computes to.
    rows.add(IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cards[i]),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: right ?? const SizedBox()),
        ],
      ),
    ));
  }
  return rows;
}

String _skillsSummary(List<String> skills) {
  if (skills.isEmpty) return 'Resume saved.';
  final shown = skills.take(4).join(', ');
  final more = skills.length - 4;
  return more > 0 ? '$shown +$more more' : shown;
}

String _goalLabel(String? goal) {
  switch (goal) {
    case 'internship':
      return 'Looking for an internship';
    case 'job':
      return 'Looking for a full-time job';
    case 'both':
      return 'Open to internships and full-time roles';
    default:
      return "What you're looking for.";
  }
}

List<String> _basicDetailLines(User? user, bool isSchool) {
  final lines = <String>[];
  lines.add(user?.name?.trim().isNotEmpty == true ? user!.name! : 'Name not set');
  lines.add(user?.city?.trim().isNotEmpty == true ? user!.city! : 'City not set');
  if (isSchool) {
    final classBoard = [user?.currentClass, user?.board].where((s) => s != null && s.trim().isNotEmpty).join(' • ');
    lines.add(classBoard.isEmpty ? 'Class & board not set' : classBoard);
  } else {
    final collegeLine = [user?.college, user?.course, user?.semester].where((s) => s != null && s.trim().isNotEmpty).join(' • ');
    lines.add(collegeLine.isEmpty ? 'College details not set' : collegeLine);
  }
  return lines;
}

/// Collapsed rendering of the Basic details card — desktop only (see its
/// one call site in profile_screen's build). Just the name, capped so this
/// card's height stops dwarfing its Resume/Photo/Video row partner; "View
/// more" reveals the original full content (name, combined city/college
/// line, and role tags).
class _BasicDetailsCollapsed extends StatelessWidget {
  final User? user;
  final bool isSchool;
  final VoidCallback onViewMore;
  const _BasicDetailsCollapsed({required this.user, required this.isSchool, required this.onViewMore});

  @override
  Widget build(BuildContext context) {
    // Name + "View more" only — the combined city/college line and role
    // tags moved behind the link entirely (still shown once expanded, see
    // the non-collapsed branch below in build()). The previous collapsed
    // state (name + combined line + up to 3 tags) still rendered 4 stacked
    // elements against its 3 siblings' 1 line each — visibly taller than
    // Resume/Profile photo/Video profile in the same paired row.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          noOrphan(user?.name?.trim().isNotEmpty == true ? user!.name! : 'Name not set'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: GestureDetector(
            onTap: onViewMore,
            child: Text(
              'View more',
              style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.semibold),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget child;
  // null = don't show a badge at all (matches every existing call site
  // that doesn't pass it); non-null drives the checkmark/empty-circle
  // indicator from profileChecklist.
  final bool? done;
  const _SectionCard({required this.title, required this.icon, required this.child, this.onTap, this.done});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppBreakpoints.isWide(context)
            ? BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border))
            : BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.blue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium, fontSize: 16),
                  ),
                ),
                if (done != null) ...[
                  Icon(done! ? Ionicons.checkmark_circle : Ionicons.ellipse_outline, size: 16, color: done! ? AppColors.success : AppColors.gray400),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (onTap != null) const Icon(Ionicons.chevron_forward, size: 16, color: AppColors.gray400),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

