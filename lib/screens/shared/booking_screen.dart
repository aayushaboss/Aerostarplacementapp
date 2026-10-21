import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_bookings.dart';
import '../../models/booking.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_page.dart';
import '../../widgets/page_header_bar.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/responsive_body.dart';

const _placementTypes = ['Mock Interview', 'Career Chat'];

class _DayOption {
  final String key;
  final String day;
  final String date;
  final String month;
  const _DayOption({required this.key, required this.day, required this.date, required this.month});
}

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

List<_DayOption> _nextDays(int count) {
  final now = DateTime.now();
  return List.generate(count, (i) {
    final d = now.add(Duration(days: i + 1));
    return _DayOption(
      key: d.toIso8601String().substring(0, 10),
      day: _weekdayNames[d.weekday - 1],
      date: '${d.day}',
      month: _monthNames[d.month - 1],
    );
  });
}

/// Mirrors frontend/app/booking.tsx (Booking). Shared between School
/// (counseling) and College (placement) flows via `kind`.
class BookingScreen extends StatefulWidget {
  final String kind;
  final String? bookingId;
  final String? initialDate;
  final String? initialTime;
  final String? initialMode;
  final String? initialSessionType;

  const BookingScreen({
    super.key,
    required this.kind,
    this.bookingId,
    this.initialDate,
    this.initialTime,
    this.initialMode,
    this.initialSessionType,
  });

  bool get isEdit => bookingId != null;
  bool get isPlacement => kind == 'placement';

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late final List<_DayOption> _days;
  late String _sessionType;
  late String _mode;
  late String _date;
  String _time = '';
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _days = _nextDays(10);
    _sessionType = widget.initialSessionType ?? (widget.isPlacement ? _placementTypes[0] : '');
    _mode = widget.initialMode ?? 'online';
    _date = widget.initialDate ?? _days.first.key;
    _time = widget.initialTime ?? '';

    final user = context.read<AppState>().user;
    _nameController.text = user?.name ?? '';
    final identifier = user?.identifier ?? '';
    final isEmail = identifier.contains('@');
    // Prefer the phone number collected in the resume builder — it's an
    // actual phone field, unlike the login identifier below, which is only
    // a phone number when that's what the account happened to sign in
    // with (and blank whenever it's an email login instead).
    final resumePhone = user?.resume?.phone?.trim();
    _phoneController.text = (resumePhone != null && resumePhone.isNotEmpty) ? resumePhone : (isEmail ? '' : identifier);
    _emailController.text = isEmail ? identifier : '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // _date must actually be one of the currently-visible upcoming days —
  // a reschedule's initialDate can predate that list entirely (the
  // original session already passed), and without this check _valid
  // would accept that stale date as-is, letting "Update Booking" silently
  // re-confirm a lapsed date/time with no active pick required.
  bool get _valid => _nameController.text.trim().isNotEmpty && _time.isNotEmpty && _date.isNotEmpty && _days.any((d) => d.key == _date);

  Widget _dayTile(_DayOption d) {
    final selected = _date == d.key;
    return GestureDetector(
      onTap: () => setState(() => _date = d.key),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : AppColors.offWhite,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: selected ? AppColors.blue : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Text(d.day, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
            Text(d.date, style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 20, fontWeight: selected ? AppFontWeight.semibold : AppFontWeight.medium)),
            Text(d.month, style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12, fontWeight: AppFontWeight.medium)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (!_valid) return;
    setState(() => _loading = true);
    try {
      // TODO: replace with real API call
      Booking? booking;
      if (widget.isEdit) {
        booking = updateBooking(
          widget.bookingId!,
          mode: _mode,
          sessionType: widget.isPlacement ? _sessionType : null,
          date: _date,
          time: _time,
        );
      } else {
        booking = createBooking(
          kind: widget.isPlacement ? 'placement' : 'counseling',
          mode: _mode,
          sessionType: widget.isPlacement ? _sessionType : null,
          date: _date,
          time: _time,
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
        );
      }
      // A null result means the slot is already taken (createBooking/
      // updateBooking's own conflict check) — previously this branch
      // didn't exist at all (a plain `booking ??= createBooking(...)`
      // fallback), so a failed reschedule would silently create a whole
      // new duplicate booking instead of reporting the conflict.
      if (booking == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That slot is no longer available — pick another.')),
        );
        return;
      }
      context.read<AppState>().bumpDataVersion();
      if (!mounted) return;
      final route = Uri(path: '/booking-confirmed', queryParameters: {
        'kind': booking.kind,
        'date': booking.date,
        'time': booking.time,
        'mode': booking.mode,
        'counselor': booking.counselor,
        'sessionType': booking.sessionType ?? '',
        'venueName': booking.venueName ?? '',
        'venueAddress': booking.venueAddress ?? '',
      }).toString();
      context.go(route);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);
    final user = context.watch<AppState>().user;
    final offlineVenue = _mode == 'offline' ? mockOfflineVenues[widget.kind] : null;
    final userCity = user?.city?.trim() ?? '';
    final cityMismatch = offlineVenue != null && userCity.isNotEmpty && userCity.toLowerCase() != offlineVenue.city.toLowerCase();

    final formChildren = <Widget>[
                  if (widget.isPlacement) ...[
                    _Section(
                      title: 'Session type',
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _placementTypes
                            .map(
                              (t) => AppChip(
                                label: t,
                                selected: _sessionType == t,
                                onPressed: () => setState(() => _sessionType = t),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  _Section(
                    title: 'Mode',
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Row(
                        children: ['online', 'offline'].map((m) {
                          final active = _mode == m;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _mode = m),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: active ? AppColors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  boxShadow: active ? AppShadows.soft : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      m == 'online' ? Ionicons.videocam_outline : Ionicons.location_outline,
                                      size: 16,
                                      color: active ? AppColors.blue : AppColors.gray500,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      m == 'online' ? 'Online' : 'Offline',
                                      style: AppTextStyles.bodyLg.copyWith(
                                        color: active ? AppColors.blue : AppColors.gray500,
                                        fontSize: 16,
                                        fontWeight: AppFontWeight.medium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (offlineVenue != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Ionicons.location, size: 16, color: AppColors.blue),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(offlineVenue.name, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                                  child: Text(offlineVenue.address, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (cityMismatch) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warningA15,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Ionicons.alert_circle_outline, size: 18, color: AppColors.warning),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'This session is in ${offlineVenue.city} — your profile says $userCity. You can still book, or switch to an online session instead.',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.ink, fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.lg),
                              child: GestureDetector(
                                onTap: () => setState(() => _mode = 'online'),
                                child: Text(
                                  'Switch to online instead',
                                  style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.semibold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _Section(
                    title: 'Pick a date',
                    child: isTablet
                        ? Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final d in _days) _dayTile(d)])
                        : SizedBox(
                      // Tall enough for the three lines of text plus padding and border (84 overflowed by 15px).
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _days.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final d = _days[i];
                          final selected = _date == d.key;
                          return GestureDetector(
                            onTap: () => setState(() => _date = d.key),
                            child: Container(
                              width: 62,
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.blue : AppColors.offWhite,
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                                border: Border.all(color: selected ? AppColors.blue : Colors.transparent, width: 2),
                              ),
                              child: Column(
                                children: [
                                  Text(d.day, style: AppTextStyles.caption.copyWith(color: selected ? AppColors.whiteA70 : AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                                  Text(d.date, style: AppTextStyles.h3.copyWith(color: selected ? AppColors.white : AppColors.ink, fontSize: 20, fontWeight: AppFontWeight.medium)),
                                  Text(d.month, style: AppTextStyles.caption.copyWith(color: selected ? AppColors.whiteA70 : AppColors.gray400, fontSize: 12, fontWeight: AppFontWeight.medium)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _Section(
                    title: 'Pick a time',
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: mockBookingSlots.map((s) {
                        // Was `i == 2` — a hardcoded index that disabled the
                        // same slot on every single day regardless of what
                        // was actually booked, so every other slot on every
                        // other day always read as free even when it
                        // wasn't. excludeBookingId so editing an existing
                        // booking doesn't see its own current slot as taken.
                        final disabled = isSlotTaken(_date, s, excludeBookingId: widget.bookingId);
                        final selected = _time == s;
                        return GestureDetector(
                          onTap: disabled ? null : () => setState(() => _time = s),
                          child: Container(
                            // Capped, not just divided by 3 — on a tablet
                            // that math alone would stretch each pill to
                            // fill the whole (much wider) screen.
                            width: math.min((MediaQuery.of(context).size.width - AppSpacing.xl * 2 - AppSpacing.sm * 2) / 3, 110),
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.blue : AppColors.offWhite,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: selected ? AppColors.blue : Colors.transparent, width: 2),
                            ),
                            child: Opacity(
                              opacity: disabled ? 0.5 : 1.0,
                              child: Text(
                                s,
                                style: AppTextStyles.label.copyWith(
                                  color: selected ? AppColors.white : (disabled ? AppColors.gray400 : AppColors.ink),
                                  fontSize: 12,
                                  fontWeight: selected ? AppFontWeight.semibold : AppFontWeight.medium,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _Section(
                    title: 'Your details',
                    child: Column(
                      children: [
                        PillInput(controller: _nameController, placeholder: 'Full name', icon: Ionicons.person_outline, onChanged: (_) => setState(() {})),
                        const SizedBox(height: AppSpacing.md),
                        PillInput(controller: _phoneController, placeholder: 'Phone number', keyboardType: TextInputType.phone, icon: Ionicons.call_outline, onChanged: (_) => setState(() {})),
                        const SizedBox(height: AppSpacing.md),
                        PillInput(controller: _emailController, placeholder: 'Email (optional)', keyboardType: TextInputType.emailAddress, icon: Ionicons.mail_outline, onChanged: (_) => setState(() {})),
                      ],
                    ),
                  ),
    ];

    if (isTablet) {
      final expanded = AppBreakpoints.isExpanded(context);
      final selectedDay = _days.where((d) => d.key == _date).isEmpty ? null : _days.firstWhere((d) => d.key == _date);
      Widget summaryRow(String label, String value) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md - 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 88, child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium))),
                Expanded(child: Text(value, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium))),
              ],
            ),
          );
      final confirm = PillButton(label: widget.isEdit ? 'Update Booking' : 'Confirm Booking', onPressed: _confirm, loading: _loading, disabled: !_valid);
      final summary = Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your session', style: AppTextStyles.h3.copyWith(color: AppColors.ink)),
            const SizedBox(height: AppSpacing.md),
            if (widget.isPlacement) summaryRow('Type', _sessionType),
            summaryRow('Mode', _mode == 'online' ? 'Online' : 'Offline'),
            summaryRow('Date', selectedDay == null ? 'Pick a date' : '${selectedDay.day}, ${selectedDay.month} ${selectedDay.date}'),
            summaryRow('Time', _time.isEmpty ? 'Pick a time' : _time),
            const SizedBox(height: AppSpacing.sm),
            confirm,
          ],
        ),
      );
      return AppPage(
        backLabel: 'Back',
        title: widget.isEdit ? 'Reschedule Session' : (widget.isPlacement ? 'Book a Placement Session' : 'Book Counseling'),
        maxWidth: expanded ? null : 680,
        scroll: !expanded,
        body: expanded
            ? TwoPane(main: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: formChildren), side: summary, sideWidth: 340)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...formChildren, const SizedBox(height: AppSpacing.xl), confirm]),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Column(
          children: [
            PageHeaderBar(
              title: widget.isEdit
                  ? 'Reschedule Session'
                  : widget.isPlacement
                      ? 'Book a Placement Session'
                      : 'Book Counseling',
              onBack: () => context.canPop() ? context.pop() : context.go('/tabs'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: formChildren,
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
              decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                  child: PillButton(
                    label: widget.isEdit ? 'Update Booking' : 'Confirm Booking',
                    onPressed: _confirm,
                    loading: _loading,
                    disabled: !_valid,
                  ),
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}
