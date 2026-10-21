import '../../mockData/mock_bookings.dart' as mock;
import '../../models/booking.dart';
import 'booking_repository.dart';

/// Pure delegation to the existing mock_bookings.dart functions — zero
/// behavior change, just moved behind the repository seam.
class MockBookingRepository implements BookingRepository {
  @override
  Future<List<Booking>> listBookings() async => mock.listBookings();

  @override
  bool isSlotTaken(String date, String time, {String? excludeBookingId}) =>
      mock.isSlotTaken(date, time, excludeBookingId: excludeBookingId);

  @override
  Future<Booking?> createBooking({
    required String kind,
    required String mode,
    String? sessionType,
    required String date,
    required String time,
    required String name,
    String? phone,
    String? email,
  }) async {
    return mock.createBooking(kind: kind, mode: mode, sessionType: sessionType, date: date, time: time, name: name, phone: phone, email: email);
  }

  @override
  Future<Booking?> updateBooking(String id, {String? mode, String? sessionType, String? date, String? time}) async {
    return mock.updateBooking(id, mode: mode, sessionType: sessionType, date: date, time: time);
  }

  @override
  Future<bool> deleteBooking(String id) async => mock.deleteBooking(id);

  @override
  Future<void> undoDeleteBooking(String id) async => mock.undoDeleteBooking(id);
}
