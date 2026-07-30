import 'package:isar/isar.dart';
import 'package:studyvault/core/database/isar_service.dart';
import 'package:studyvault/core/models/inbox_item.dart';
import 'package:studyvault/core/utils/app_logger.dart';

class InboxRepository {
  InboxRepository._();

  static final InboxRepository instance = InboxRepository._();

  Isar get isar => IsarService.instance.isar;

  /// Fetch all inbox items sorted by creation time descending.
  Future<List<InboxItem>> getAllInboxItems() async {
    try {
      final items = await isar.inboxItems.where().sortByCreatedAtDesc().findAll();
      AppLogger.db('InboxRepository.getAllInboxItems', 'Fetched ${items.length} item(s)');
      return items;
    } catch (e, st) {
      AppLogger.error('InboxRepository.getAllInboxItems', e, st);
      return [];
    }
  }

  /// Get total count of inbox items.
  Future<int> getInboxCount() async {
    try {
      return await isar.inboxItems.count();
    } catch (e, st) {
      AppLogger.error('InboxRepository.getInboxCount', e, st);
      return 0;
    }
  }

  /// Add a new item to inbox.
  Future<InboxItem?> addInboxItem({
    required String title,
    required String filePath,
    required int fileSize,
    required String fileType,
  }) async {
    try {
      final item = InboxItem()
        ..title = title
        ..filePath = filePath
        ..fileSize = fileSize
        ..fileType = fileType
        ..createdAt = DateTime.now();

      await isar.writeTxn(() async {
        item.id = await isar.inboxItems.put(item);
      });

      AppLogger.action(
        'INBOX_ADD',
        'Added inbox item ID ${item.id}: "$title" ($fileType, $fileSize bytes)',
      );
      return item;
    } catch (e, st) {
      AppLogger.error('InboxRepository.addInboxItem', e, st);
      return null;
    }
  }

  /// Delete an inbox item by ID.
  Future<bool> deleteInboxItem(int id) async {
    try {
      bool deleted = false;
      await isar.writeTxn(() async {
        deleted = await isar.inboxItems.delete(id);
      });
      AppLogger.action('INBOX_DELETE', 'Deleted inbox item ID $id: $deleted');
      return deleted;
    } catch (e, st) {
      AppLogger.error('InboxRepository.deleteInboxItem', e, st);
      return false;
    }
  }
}
