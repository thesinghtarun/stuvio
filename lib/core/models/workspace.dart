import 'package:isar/isar.dart';

part 'workspace.g.dart';

enum WorkspaceType {
  college,
  placement,
  personal,
  office,
  custom,
}

@collection
class Workspace {
  Id id = Isar.autoIncrement;

  @Index()
  late int userId;

  @Index()
  late String name;

  @enumerated
  WorkspaceType type = WorkspaceType.custom;

  int icon = 0xe318;

  int color = 0xFF6750A4;

  bool isPinned = false;

  String? course;

  String? specialization;

  String? semester;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();
}