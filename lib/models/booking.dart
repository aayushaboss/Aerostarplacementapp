/// Mirrors frontend/src/mockData/mockBookings.ts `Booking`.
class Booking {
  final String id;
  final String userId;
  final String kind;
  final String mode;
  final String? sessionType;
  final String date;
  final String time;
  final String name;
  final String? phone;
  final String? email;
  final String counselor;
  final String status;
  final String createdAt;

  /// Offline-venue snapshot — only set when [mode] is 'offline', captured
  /// at booking time from `mockOfflineVenues` (same "captured once, not
  /// looked up live" pattern already used for [counselor]). Null for
  /// online bookings.
  final String? venueName;
  final String? venueAddress;
  final String? venueCity;

  /// Soft-delete marker, mirroring Application.deletedAt exactly — a
  /// cancelled session used to be a hard removal with no recovery path,
  /// unlike Applications' own undo-snackbar-backed soft delete.
  final String? deletedAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.kind,
    required this.mode,
    this.sessionType,
    required this.date,
    required this.time,
    required this.name,
    this.phone,
    this.email,
    required this.counselor,
    required this.status,
    required this.createdAt,
    this.venueName,
    this.venueAddress,
    this.venueCity,
    this.deletedAt,
  });

  Booking copyWith({
    String? mode,
    String? sessionType,
    String? date,
    String? time,
  }) {
    return Booking(
      id: id,
      userId: userId,
      kind: kind,
      mode: mode ?? this.mode,
      sessionType: sessionType ?? this.sessionType,
      date: date ?? this.date,
      time: time ?? this.time,
      name: name,
      phone: phone,
      email: email,
      counselor: counselor,
      status: status,
      createdAt: createdAt,
      venueName: venueName,
      venueAddress: venueAddress,
      venueCity: venueCity,
      deletedAt: deletedAt,
    );
  }

  /// Unconditionally overwrites deletedAt, including clearing it back to
  /// null on restore — mirrors Application.withDeletedAt exactly.
  Booking withDeletedAt(String? deletedAt) {
    return Booking(
      id: id,
      userId: userId,
      kind: kind,
      mode: mode,
      sessionType: sessionType,
      date: date,
      time: time,
      name: name,
      phone: phone,
      email: email,
      counselor: counselor,
      status: status,
      createdAt: createdAt,
      venueName: venueName,
      venueAddress: venueAddress,
      venueCity: venueCity,
      deletedAt: deletedAt,
    );
  }

  /// Unconditionally overwrites the venue fields (including clearing them
  /// back to null) — unlike [copyWith]'s `param ?? this.field` idiom, which
  /// can never *unset* a field, this is needed when a reschedule flips the
  /// mode from offline back to online and the old venue must actually go
  /// away, not just stay stuck at its last value.
  Booking withVenue({String? name, String? address, String? city}) {
    return Booking(
      id: id,
      userId: userId,
      kind: kind,
      mode: mode,
      sessionType: sessionType,
      date: date,
      time: time,
      name: this.name,
      phone: phone,
      email: email,
      counselor: counselor,
      status: status,
      createdAt: createdAt,
      venueName: name,
      venueAddress: address,
      venueCity: city,
      deletedAt: deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'kind': kind,
        'mode': mode,
        'sessionType': sessionType,
        'date': date,
        'time': time,
        'name': name,
        'phone': phone,
        'email': email,
        'counselor': counselor,
        'status': status,
        'createdAt': createdAt,
        'venueName': venueName,
        'venueAddress': venueAddress,
        'venueCity': venueCity,
        'deletedAt': deletedAt,
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        userId: json['userId'] as String,
        kind: json['kind'] as String,
        mode: json['mode'] as String,
        sessionType: json['sessionType'] as String?,
        date: json['date'] as String,
        time: json['time'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        counselor: json['counselor'] as String,
        status: json['status'] as String,
        createdAt: json['createdAt'] as String,
        venueName: json['venueName'] as String?,
        venueAddress: json['venueAddress'] as String?,
        venueCity: json['venueCity'] as String?,
        deletedAt: json['deletedAt'] as String?,
      );
}
