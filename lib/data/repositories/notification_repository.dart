import '../../models/notification_item.dart';

abstract class NotificationRepository {
  Future<List<NotificationItem>> listNotifications({required bool isSchool});
}
