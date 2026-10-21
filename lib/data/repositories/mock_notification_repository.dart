import '../../mockData/mock_notifications.dart';
import '../../models/notification_item.dart';
import 'notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationItem>> listNotifications({required bool isSchool}) async {
    return isSchool ? mockSchoolNotifications : mockNotifications;
  }
}
