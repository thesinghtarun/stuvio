import 'package:isar/isar.dart';

part 'inbox_item.g.dart';

@collection
class InboxItem {
  Id id = Isar.autoIncrement;

  @Index()
  late String title;

  @Index()
  late String filePath;

  int fileSize = 0;

  late String fileType; // 'pdf', 'image', 'doc', 'other'

  @Index()
  DateTime createdAt = DateTime.now();
}
