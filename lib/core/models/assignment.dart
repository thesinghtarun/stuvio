import 'package:isar/isar.dart';

part 'assignment.g.dart';

enum AssignmentPriority {
  low,
  medium,
  high,
}

enum AssignmentStatus {
  pending,
  ongoing,
  completed,
}

@collection
class Assignment {
  Id id = Isar.autoIncrement;

  @Index()
  late int subjectId;

  @Index()
  int? noteId;

  @Index()
  late String title;

  String description = "";

  late DateTime dueDate;

  @enumerated
  AssignmentPriority priority = AssignmentPriority.medium;

  @enumerated
  AssignmentStatus status = AssignmentStatus.pending;

  bool submitted = false;

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();
}