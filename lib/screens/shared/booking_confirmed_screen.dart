import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../mockData/mock_bookings.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/adaptive_sheet.dart';

const _weekdayFullNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _monthFullNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// Mirrors frontend/app/booking-confirmed.tsx (BookingConfirmed).
class BookingConfirmedScreen extends StatefulWidget {
  final String kind;
  final String date;
  final String time;
  final String mode;
  final String counselor;
  final String sessionType;
  final String venueName;
  final String venueAddress;

  const BookingConfirmedScreen({
    super.key,
    required this.kind,
    required this.date,
    required this.time,
    required this.mode,
    required this.counselor,
    required this.sessionType,
    this.venueName = '',
    this.venueAddress = '',
  });

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _checkScale = CurvedAnimation(parent: _checkController, curve: Curves.elasticOut);
    _checkController.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final appState = context.read<AppState>();
    // TODO: replace with real API call (local mock)
    await appState.updateProfile((current) => current.copyWith(onboardingComplete: true));
    if (!mounted) return;
    context.go('/tabs');
  }

  String get _eventTitle => widget.kind == 'placement' ? (widget.sessionType.isNotEmpty ? widget.sessionType : 'Placement session') : 'Counseling session';

  String get _eventLocation {
    if (widget.mode == 'offline' && widget.venueAddress.isNotEmpty) return widget.venueAddress;
    return 'Online';
  }

  /// Assumed — no real duration is captured anywhere in the booking flow
  /// (mockBookingSlots are just start times), so 30 minutes is a
  /// reasonable default for a counseling/placement chat rather than
  /// leaving the event with no end time at all.
  static const _eventDuration = Duration(minutes: 30);

  String _icsDateTimeUtc(DateTime dt) {
    final u = dt.toUtc();
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${u.year}${p2(u.month)}${p2(u.day)}T${p2(u.hour)}${p2(u.minute)}${p2(u.second)}Z';
  }

  Future<void> _openGoogleCalendar() async {
    final start = parseBookingDateTime(widget.date, widget.time);
    if (start == null) return;
    final end = start.add(_eventDuration);
    // No OAuth needed — Google's URL-based "add event" template just opens
    // a pre-filled compose screen in the user's own Google Calendar.
    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': _eventTitle,
      'dates': '${_icsDateTimeUtc(start)}/${_icsDateTimeUtc(end)}',
      'details': 'Aerostar Edge session with ${widget.counselor}',
      'location': _eventLocation,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showCalendarSheet() {
    showAdaptiveSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
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
                padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
                child: Text('Add to Calendar', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.bold)),
              ),
              // Apple Calendar / "Download .ics file" options used to live
              // here too, both handing a generated .ics off to a browser
              // download (dart:html) with no native equivalent. Native
              // file-sharing packages tried as a replacement (share_plus)
              // hit their own broken Android build — not worth blocking
              // the whole app on a secondary feature for. Google Calendar
              // needs no such thing (it's just a URL), so it's the one
              // option left.
              _CalendarOptionTile(
                iconWidget: SvgPicture.asset('assets/icons/google.svg', width: 19, height: 19),
                // Google's own brand blue, not an app design-system color —
                // deliberately not an AppColors token since it has to match
                // Google's mark, not our palette.
                iconColor: const Color(0xFF4285F4),
                label: 'Google Calendar',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openGoogleCalendar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _prettyDate {
    try {
      final d = DateTime.parse(widget.date);
      return '${_weekdayFullNames[d.weekday - 1]}, ${_monthFullNames[d.month - 1]} ${d.day}';
    } catch (_) {
      return widget.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = AppBreakpoints.isWide(context);
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isPlacement = widget.kind == 'placement';
    final isTablet = AppBreakpoints.isWide(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (wide ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light),
      child: Scaffold(
        backgroundColor: (wide ? AppColors.white : AppColors.blue),
        body: ResponsiveBody(maxWidth: isTablet ? 560 : AppBreakpoints.maxContentWidth, child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _checkScale,
                          child: Container(
                            width: 96,
                            height: 96,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: (wide ? AppColors.brand : AppColors.yellow), shape: BoxShape.circle, boxShadow: (wide ? AppShadows.brand : AppShadows.yellow)),
                            child: Icon(Ionicons.checkmark, size: wide ? 52 : 56, color: wide ? AppColors.ink : AppColors.blue),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xl),
                          child: Text(
                            "You're all set!",
                            style: AppTextStyles.h1.copyWith(color: (wide ? AppColors.ink : AppColors.white), fontSize: 30, fontWeight: AppFontWeight.semibold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            noOrphan('Your ${isPlacement ? 'placement session' : 'counseling session'} is confirmed.'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyLg.copyWith(color: (wide ? AppColors.gray500 : AppColors.whiteA70), fontSize: 16),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: AppSpacing.xxl),
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(color: wide ? AppColors.offWhite : AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: wide ? null : AppShadows.card),
                          child: Column(
                            children: [
                              if (widget.counselor.isNotEmpty)
                                _Row(icon: Ionicons.person_circle_outline, label: 'With', value: widget.counselor),
                              if (widget.sessionType.isNotEmpty)
                                _Row(icon: Ionicons.list_outline, label: 'Session', value: widget.sessionType),
                              _Row(icon: Ionicons.calendar_outline, label: 'Date', value: _prettyDate),
                              _Row(icon: Ionicons.time_outline, label: 'Time', value: widget.time),
                              _Row(
                                icon: widget.mode == 'online' ? Ionicons.videocam_outline : Ionicons.location_outline,
                                label: 'Mode',
                                value: widget.mode == 'online' ? 'Online' : 'Offline',
                              ),
                            ],
                          ),
                        ),
                        if (widget.mode == 'offline' && widget.venueAddress.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: AppSpacing.md),
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: (wide ? AppColors.offWhite : AppColors.white),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                                  child: Icon(Ionicons.location, size: 18, color: (wide ? AppColors.gray500 : AppColors.blue)),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (widget.venueName.isNotEmpty)
                                        Text(widget.venueName, textAlign: TextAlign.left, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                                      Padding(
                                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                                        child: Text(widget.venueAddress, textAlign: TextAlign.left, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12, height: 1.4)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, bottomInset + AppSpacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 480 : double.infinity),
                    child: Column(
                      children: [
                        PillButton(label: 'Add to Calendar', variant: PillVariant.secondary, icon: Ionicons.calendar_outline, onPressed: _showCalendarSheet),
                        const SizedBox(height: AppSpacing.md),
                        PillButton(label: 'Done', onPressed: _done),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final wide = AppBreakpoints.isWide(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: (wide ? AppColors.gray500 : AppColors.blue)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, fontWeight: AppFontWeight.regular)),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium),
          ),
        ],
      ),
    );
  }
}

class _CalendarOptionTile extends StatelessWidget {
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  // Google Calendar is the only option left (see _showCalendarSheet's own
  // note) — needs its real multi-color "G" logo, not a single-color
  // IconData glyph, so this widget stays iconWidget-only rather than also
  // carrying an unused IconData fallback for a hypothetical second row.
  final Widget iconWidget;

  const _CalendarOptionTile({required this.iconColor, required this.label, required this.onTap, required this.iconWidget});

  @override
  Widget build(BuildContext context) {
    final wide = AppBreakpoints.isWide(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: iconWidget,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
            ),
            const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
