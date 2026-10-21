import '../../models/notification_item.dart';
import '../api_client.dart';
import 'notification_repository.dart';

/// Not wired to anything real yet — see BACKEND_API_CONTRACT.md.
class HttpNotificationRepository implements NotificationRepository {
  final ApiClient client;
  const HttpNotificationRepository(this.client);

  @override
  Future<List<NotificationItem>> listNotifications({required bool isSchool}) =>
      throw UnimplementedError('GET /notifications — see BACKEND_API_CONTRACT.md');
}
