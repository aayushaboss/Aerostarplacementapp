import 'api_client.dart';
import 'data_config.dart';
import 'repositories/application_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/course_repository.dart';
import 'repositories/http_application_repository.dart';
import 'repositories/http_auth_repository.dart';
import 'repositories/http_booking_repository.dart';
import 'repositories/http_course_repository.dart';
import 'repositories/http_notification_repository.dart';
import 'repositories/http_opportunity_repository.dart';
import 'repositories/http_upload_repository.dart';
import 'repositories/mock_application_repository.dart';
import 'repositories/mock_auth_repository.dart';
import 'repositories/mock_booking_repository.dart';
import 'repositories/mock_course_repository.dart';
import 'repositories/mock_notification_repository.dart';
import 'repositories/mock_opportunity_repository.dart';
import 'repositories/mock_upload_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/opportunity_repository.dart';
import 'repositories/upload_repository.dart';

/// Every domain's repository, one bundle handed out via `Provider<Repositories>`
/// in main.dart. Screens read a specific repository off this
/// (`context.read<Repositories>().applications`), never the mockData
/// modules directly — see BACKEND_API_CONTRACT.md for what a real backend
/// needs to expose before [DataConfig.mode] can be flipped to http.
class Repositories {
  final AuthRepository auth;
  final OpportunityRepository opportunities;
  final ApplicationRepository applications;
  final CourseRepository courses;
  final NotificationRepository notifications;
  final BookingRepository bookings;
  final UploadRepository uploads;

  const Repositories({
    required this.auth,
    required this.opportunities,
    required this.applications,
    required this.courses,
    required this.notifications,
    required this.bookings,
    required this.uploads,
  });

  factory Repositories.mock() => Repositories(
        auth: MockAuthRepository(),
        opportunities: MockOpportunityRepository(),
        applications: MockApplicationRepository(),
        courses: MockCourseRepository(),
        notifications: MockNotificationRepository(),
        bookings: MockBookingRepository(),
        uploads: MockUploadRepository(),
      );

  factory Repositories.http(ApiClient client) => Repositories(
        auth: HttpAuthRepository(client),
        opportunities: HttpOpportunityRepository(client),
        applications: HttpApplicationRepository(client),
        courses: HttpCourseRepository(client),
        notifications: HttpNotificationRepository(client),
        bookings: HttpBookingRepository(client),
        uploads: HttpUploadRepository(client),
      );
}

/// Picks mock vs. http per [DataConfig.mode] — the one place that decision
/// is made.
Repositories buildRepositories() {
  switch (DataConfig.mode) {
    case DataMode.mock:
      return Repositories.mock();
    case DataMode.http:
      return Repositories.http(ApiClient());
  }
}
