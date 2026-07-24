import 'package:isar/isar.dart';

part 'subject.g.dart';

@collection
class Subject {
  Id id = Isar.autoIncrement;

  @Index()
  late int workspaceId;

  @Index()
  late String name;

  int color = 0xFF6750A4;

  int icon = 0xe865;

  bool archived = false;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();
}