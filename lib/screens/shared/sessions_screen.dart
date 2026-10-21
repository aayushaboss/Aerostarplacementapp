import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_bookings.dart';
import '../../models/booking.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/adaptive_sheet.dart';

const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Mirrors frontend/src/screens/Sessions.tsx (Sessions).
/// Standalone for now — will be embedded under the bottom tab bar in Step 4.
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<Booking> _bookings = [];
  final _scrollController = ScrollController();
  int _lastSeenDataVersion = -1;

  @override
  void initState() {
    super.initState();
    // Branch index 2 (Sessions) — see router.dart's StatefulShellRoute. One
    // shared screen for both segments, so no segment check needed here.
    ScrollToTopRegistry.register(2, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    _load();
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(2);
    _scrollController.dispose();
    super.dispose();
  }

  void _load() {
    // TODO: replace with real API call
    setState(() => _bookings = listBookings());
  }

  Future<void> _onRefresh() async => _load();

  void _book(bool isSchool) {
    final route = '/booking?kind=${isSchool ? 'counseling' : 'placement'}';
    context.push(route);
  }

  void _reschedule(Booking b) {
    final route = Uri(path: '/booking', queryParameters: {
      'kind': b.kind,
      'bookingId': b.id,
      'date': b.date,
      'time': b.time,
      'mode': b.mode,
      'sessionType': b.sessionType ?? '',
    }).toString();
    context.push(route);
  }

  void _askCancel(Booking b) {
    bool canceling = false;
    showAdaptiveSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isDismissible: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.errorA10, shape: BoxShape.circle),
                child: const Icon(Ionicons.alert, size: 28, color: AppColors.error),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text('Cancel this session?', style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 20, fontWeight: AppFontWeight.semibold)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'You can always book a new session later.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: 'Yes, cancel session',
                    loading: canceling,
                    onPressed: () async {
                      setSheetState(() => canceling = true);
                      // TODO: replace with real API call
                      deleteBooking(b.id);
                      // Kept-alive Home (school_home_screen.dart) only
                      // recomputes its own "upcoming session" card from
                      // listBookings() on its own next build — bump so it
                      // notices this change instead of showing a stale
                      // now-cancelled session.
                      context.read<AppState>().bumpDataVersion();
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                      _load();
                      // Soft delete, not a hard removal — previously there
                      // was no way back from a mistaken cancel at all,
                      // unlike Applications' own undo-snackbar pattern for
                      // the same kind of "oops" moment.
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: const Text('Session cancelled'),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: AppColors.yellow,
                              onPressed: () {
                                undoDeleteBooking(b.id);
                                context.read<AppState>().bumpDataVersion();
                                _load();
                              },
                            ),
                            duration: const Duration(seconds: 4),
                            // Flutter defaults `persist` to true whenever an
                            // `action` is set, which silently makes the
                            // `duration` above a no-op (the auto-dismiss
                            // timer fires but does nothing) — this is a
                            // genuine toast, not a stay-until-dismissed
                            // notification, so it should actually time out.
                            persist: false,
                          ),
                        );
                    },
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(sheetContext).pop(),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
                  child: Text('Keep session', textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, fontWeight: AppFontWeight.medium)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _prettyDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${_weekdayShort[d.weekday - 1]}, ${_monthShort[d.month - 1]} ${d.day}';
    } catch (_) {
      return date;
    }
  }

  // Extracted from the old inline .map() builder so desktop can pair these
  // 2-per-row (see _pairedBookingRows) without duplicating the card markup.
  Widget _bookingCard(BuildContext context, Booking b) {
    DateTime? d;
    try {
      d = DateTime.parse(b.date);
    } catch (_) {}
    final wide = AppBreakpoints.isWide(context);
    return Container(
      margin: wide ? EdgeInsets.zero : const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: wide ? null : AppShadows.card,
        border: wide ? Border.all(color: AppColors.border) : null,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(d != null ? '${d.day}' : '-', style: AppTextStyles.h3.copyWith(color: AppColors.white, fontSize: 20, fontWeight: AppFontWeight.medium)),
                    Text(d != null ? _monthShort[d.month - 1] : '', style: AppTextStyles.label.copyWith(color: AppColors.yellow, fontSize: 12, fontWeight: AppFontWeight.medium)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      b.kind == 'placement' ? (b.sessionType ?? 'Placement session') : 'Counseling session',
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text('${_prettyDate(b.date)} • ${b.time}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(b.mode == 'online' ? Ionicons.videocam_outline : Ionicons.location_outline, size: 12, color: AppColors.blue),
                          const SizedBox(width: AppSpacing.xs),
                          Text('${b.mode == 'online' ? 'Online' : 'Offline'} • ${b.counselor}', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                        ],
                      ),
                    ),
                    if (b.mode == 'offline' && (b.venueAddress?.trim().isNotEmpty ?? false))
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          b.venueAddress!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              // Previously a hardcoded "confirmed" icon regardless of the
              // booking's own status field, which is never actually read —
              // every booking always looked the same even though the model
              // supports other states.
              Icon(
                b.status == 'Confirmed' ? Ionicons.checkmark_circle : Ionicons.time_outline,
                size: 18,
                color: b.status == 'Confirmed' ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md),
            padding: const EdgeInsets.only(top: AppSpacing.md),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 1))),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _reschedule(b),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Ionicons.calendar_outline, size: 15, color: AppColors.blue),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Reschedule', style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _askCancel(b),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.error, width: 1.5)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Ionicons.close_circle_outline, size: 15, color: AppColors.error),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.error, fontSize: 12, fontWeight: AppFontWeight.medium)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2-column desktop tier — same top-aligned Expanded pairing used
  // elsewhere this round (profile_screen.dart's _pairedRows,
  // school_home_screen.dart's _gridRows), sized for this screen's own
  // card shape.
  List<Widget> _pairedBookingRows(BuildContext context, List<Booking> bookings) {
    final rows = <Widget>[];
    for (var i = 0; i < bookings.length; i += 2) {
      final second = i + 1 < bookings.length ? bookings[i + 1] : null;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _bookingCard(context, bookings[i])),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: second != null ? _bookingCard(context, second) : const SizedBox()),
        ],
      ));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSchool = appState.user?.segment == Segment.school;
    // A booking created/cancelled/rescheduled elsewhere (e.g. Home's CTA,
    // kept alive in the background by StatefulShellRoute.indexedStack)
    // otherwise wouldn't be reflected here until a manual pull-to-refresh
    // — bumpDataVersion's notifyListeners triggers this rebuild; scheduled
    // post-frame since _load() calls setState and this is still mid-build.
    if (appState.dataVersion != _lastSeenDataVersion) {
      _lastSeenDataVersion = appState.dataVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    final topInset = MediaQuery.of(context).padding.top;
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      final cols = AppBreakpoints.isExpanded(context) ? 3 : 2;
      return AppPage(
        backLabel: isSchool ? null : 'Profile',
        backFallback: '/tabs/profile',
        title: 'Bookings',
        subtitle: 'Counseling & placement support',
        controller: _scrollController,
        body: _bookings.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: EmptyState(
                      icon: Ionicons.calendar_outline,
                      title: 'No sessions yet',
                      subtitle: 'Book a ${isSchool ? 'counseling' : 'placement'} session to get expert 1:1 guidance.',
                      buttonLabel: isSchool ? 'Book counseling' : 'Book placement session',
                      onButtonTap: () => _book(isSchool),
                    ),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppGrid(columns: cols, children: [for (final b in _bookings) _bookingCard(context, b)]),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(width: 280, child: PillButton(label: isSchool ? 'Book counseling' : 'Book placement session', icon: Ionicons.add, onPressed: () => _book(isSchool))),
                ],
              ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      // 1200, matching every other desktop tab — a narrower cap here made
      // the horizontal gutter next to the sidebar visibly inconsistent
      // between tabs.
      body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            // isTablet adds AppSpacing.xl on top — sits directly under
            // TopNavBar's 64px bar with nothing else providing clearance.
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm + (isTablet ? AppSpacing.xl : 0), AppSpacing.xl, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // College-only — college has no bottom-tab item for
                // Sessions at all (only reachable via Profile's "Bookings"
                // row), so it needs an explicit way back with no tab
                // highlighted to show where it came from. School gets this
                // screen as its own real "Sessions" tab (see
                // tabs_scaffold.dart) — a chevron back to Profile there
                // previously implied a nesting that doesn't exist, skipped
                // the tab bar's own haptic/snackbar-clear on switch, and
                // was simply redundant with the tab bar itself.
                if (!isSchool)
                  GestureDetector(
                    onTap: () => context.go('/tabs/profile'),
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Icon(Ionicons.chevron_back, size: 26, color: AppColors.ink),
                    ),
                  ),
                Text('Bookings', textAlign: TextAlign.left, style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                  child: Text(
                    noOrphan('Counseling & placement support'),
                    textAlign: TextAlign.left,
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.blue,
              onRefresh: _onRefresh,
              child: _bookings.isEmpty
                  ? ListView(
                      controller: _scrollController,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl).copyWith(top: AppSpacing.xxxl),
                          child: EmptyState(
                            // No button here — the screen's own standing
                            // "Book Placement Session" bar at the bottom is
                            // always present regardless of whether there
                            // are any bookings yet, so a second CTA inside
                            // the empty state duplicated it. One CTA only.
                            icon: Ionicons.calendar_outline,
                            title: 'No sessions yet',
                            subtitle: 'Book a ${isSchool ? 'counseling' : 'placement'} session to get expert 1:1 guidance.',
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxxl + AppSpacing.xl),
                      children: isTablet ? _pairedBookingRows(context, _bookings) : [for (final b in _bookings) _bookingCard(context, b)],
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
            decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
            child: PillButton(
              // A leading icon, not a hand-written "+" glyph in the label
              // string — every other PillButton in the app that needs a
              // leading mark uses the icon: param, which aligns/scales
              // properly; a literal "+" character doesn't.
              label: isSchool ? 'Book Counseling' : 'Book Placement Session',
              icon: Ionicons.add,
              onPressed: () => _book(isSchool),
            ),
          ),
        ],
      )),
    );
  }
}
