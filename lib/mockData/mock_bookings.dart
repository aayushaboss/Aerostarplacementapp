// Prototype mock data — delete when real API is wired. In-memory session store.
// Mirrors frontend/src/mockData/mockBookings.ts.
import '../models/booking.dart';

const List<String> mockBookingSlots = [
  '10:00 AM',
  '11:30 AM',
  '01:00 PM',
  '02:30 PM',
  '04:00 PM',
  '05:30 PM',
];

class OfflineVenue {
  final String name;
  final String address;
  final String city;
  const OfflineVenue({required this.name, required this.address, required this.city});
}

/// Fixed office per booking kind — this prototype has one physical office,
/// not a multi-location backend, so a small constant is the right amount
/// of "data model" for it. Both kinds share the same building for now.
const mockOfflineVenues = {
  'placement': OfflineVenue(name: 'Aerostar Careers Office', address: '3rd Floor, Baner Road, Pune', city: 'Pune'),
  'counseling': OfflineVenue(name: 'Aerostar Careers Office', address: '3rd Floor, Baner Road, Pune', city: 'Pune'),
};

// Deliberately empty — this used to seed a fake "Mock Interview" booking so
// Sessions / Home's Upcoming Session card were never empty on first load,
// but that meant every fresh account landed on a session it never actually
// booked. The real empty state (Home's "Talk to a placement expert" CTA,
// Sessions' own empty state) is the correct default; booking one for real
// via booking_screen.dart is what should populate this list.
List<Booking> _bookings = [];

/// Parses a booking's `date` ("yyyy-MM-dd") + `time` ("01:00 PM") into a
/// real DateTime — the single place this parsing happens, so sorting,
/// conflict checks, and "is this in the past" checks all agree on the
/// same interpretation. Returns null on anything unparseable rather than
/// throwing, so a malformed entry just sorts as if unparsed instead of
/// crashing the whole list.
DateTime? parseBookingDateTime(String date, String time) {
  try {
    final d = DateTime.parse(date);
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false).firstMatch(time.trim());
    if (match == null) return d;
    var hour = int.parse(match.group(1)!) % 12;
    if (match.group(3)!.toUpperCase() == 'PM') hour += 12;
    return DateTime(d.year, d.month, d.day, hour, int.parse(match.group(2)!));
  } catch (_) {
    return null;
  }
}

/// Excludes soft-deleted entries and sorts by actual session date/time
/// ascending — previously returned raw creation order, so a booking made
/// later for an *earlier* date could bump a genuinely sooner session out
/// of "upcoming" on Home/Sessions.
List<Booking> listBookings() {
  final active = _bookings.where((b) => b.deletedAt == null).toList();
  active.sort((a, b) {
    final da = parseBookingDateTime(a.date, a.time);
    final db = parseBookingDateTime(b.date, b.time);
    if (da == null || db == null) return 0;
    return da.compareTo(db);
  });
  return active;
}

/// True if some other active booking already holds this exact date+time —
/// previously the only "unavailable" slot was a hardcoded index (always
/// disabling the same slot on every day, regardless of what was actually
/// booked), so any other slot on any day could be double-booked freely.
bool isSlotTaken(String date, String time, {String? excludeBookingId}) {
  return _bookings.any((b) => b.deletedAt == null && b.id != excludeBookingId && b.date == date && b.time == time);
}

/// Null return means the slot was taken by the time this actually ran
/// (checked here too, not just in the UI's disabled-slot rendering, so a
/// resubmission — e.g. browser-back then Confirm again — can't silently
/// create a duplicate for the same date+time).
Booking? createBooking({
  required String kind,
  required String mode,
  String? sessionType,
  required String date,
  required String time,
  required String name,
  String? phone,
  String? email,
}) {
  if (isSlotTaken(date, time)) return null;
  final venue = mode == 'offline' ? mockOfflineVenues[kind] : null;
  final booking = Booking(
    id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
    userId: 'demo',
    kind: kind,
    mode: mode,
    sessionType: sessionType,
    date: date,
    time: time,
    name: name,
    phone: phone,
    email: email,
    counselor: 'Ms. Ananya Rao',
    status: 'Confirmed',
    createdAt: DateTime.now().toIso8601String(),
    venueName: venue?.name,
    venueAddress: venue?.address,
    venueCity: venue?.city,
  );
  _bookings = [booking, ..._bookings];
  return booking;
}

/// Null return means either the booking doesn't exist, or (when date/time
/// is actually changing) the new slot is already taken — same conflict
/// check as [createBooking], so a reschedule can't collide with another
/// booking either.
Booking? updateBooking(
  String id, {
  String? mode,
  String? sessionType,
  String? date,
  String? time,
}) {
  final idx = _bookings.indexWhere((b) => b.id == id);
  if (idx < 0) return null;
  final current = _bookings[idx];
  final newDate = date ?? current.date;
  final newTime = time ?? current.time;
  if ((date != null || time != null) && isSlotTaken(newDate, newTime, excludeBookingId: id)) return null;
  var updated = current.copyWith(
    mode: mode,
    sessionType: sessionType,
    date: date,
    time: time,
  );
  // mode is the only field above that changes whether a venue applies —
  // recompute it explicitly rather than letting copyWith's ?? fallback
  // leave a stale venue attached after switching offline -> online.
  if (mode != null) {
    final venue = mode == 'offline' ? mockOfflineVenues[updated.kind] : null;
    updated = updated.withVenue(name: venue?.name, address: venue?.address, city: venue?.city);
  }
  _bookings[idx] = updated;
  return updated;
}

/// Soft delete, mirroring removeApplication/restoreApplication exactly —
/// a cancelled session used to vanish permanently with no recovery.
bool deleteBooking(String id) {
  final idx = _bookings.indexWhere((b) => b.id == id && b.deletedAt == null);
  if (idx < 0) return false;
  _bookings[idx] = _bookings[idx].withDeletedAt(DateTime.now().toIso8601String());
  return true;
}

void undoDeleteBooking(String id) {
  final idx = _bookings.indexWhere((b) => b.id == id);
  if (idx < 0) return;
  _bookings[idx] = _bookings[idx].withDeletedAt(null);
}
