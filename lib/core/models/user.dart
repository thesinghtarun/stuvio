import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  /// Last opened workspace
  int? currentWorkspaceId;
  
  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();
}