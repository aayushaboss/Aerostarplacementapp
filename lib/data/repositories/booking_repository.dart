import '../../models/booking.dart';

abstract class BookingRepository {
  Future<List<Booking>> listBookings();
  bool isSlotTaken(String date, String time, {String? excludeBookingId});

  /// Null return means the slot was taken.
  Future<Booking?> createBooking({
    required String kind,
    required String mode,
    String? sessionType,
    required String date,
    required String time,
    required String name,
    String? phone,
    String? email,
  });

  /// Null return means the booking doesn't exist, or the new slot conflicts.
  Future<Booking?> updateBooking(String id, {String? mode, String? sessionType, String? date, String? time});

  Future<bool> deleteBooking(String id);
  Future<void> undoDeleteBooking(String id);
}
