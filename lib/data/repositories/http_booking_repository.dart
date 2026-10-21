import '../../models/booking.dart';
import '../api_client.dart';
import 'booking_repository.dart';

/// Not wired to anything real yet — see BACKEND_API_CONTRACT.md.
class HttpBookingRepository implements BookingRepository {
  final ApiClient client;
  const HttpBookingRepository(this.client);

  @override
  Future<List<Booking>> listBookings() => throw UnimplementedError('GET /bookings — see BACKEND_API_CONTRACT.md');

  @override
  bool isSlotTaken(String date, String time, {String? excludeBookingId}) =>
      throw UnimplementedError('GET /bookings/slots — needs a local cache once wired');

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
  }) =>
      throw UnimplementedError('POST /bookings — see BACKEND_API_CONTRACT.md');

  @override
  Future<Booking?> updateBooking(String id, {String? mode, String? sessionType, String? date, String? time}) =>
      throw UnimplementedError('PATCH /bookings/{id} — see BACKEND_API_CONTRACT.md');

  @override
  Future<bool> deleteBooking(String id) => throw UnimplementedError('DELETE /bookings/{id} — see BACKEND_API_CONTRACT.md');

  @override
  Future<void> undoDeleteBooking(String id) => throw UnimplementedError('POST /bookings/{id}/restore — see BACKEND_API_CONTRACT.md');
}
