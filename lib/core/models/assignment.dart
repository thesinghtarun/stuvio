import 'package:isar/isar.dart';

part 'assignment.g.dart';

enum AssignmentPriority {
  low,
  medium,
  high,
}

@collection
class Assignment {
  Id id = Isar.autoIncrement;

  @Index()
  late int subjectId;

  @Index()
  late String title;

  String description = "";

  late DateTime dueDate;

  @enumerated
  AssignmentPriority priority = AssignmentPriority.medium;

  bool submitted = false;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();
}