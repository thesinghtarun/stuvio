import 'package:isar/isar.dart';

part 'note.g.dart';

enum NoteType { note, assignment, pyq, lab }

@collection
class Note {
  Id id = Isar.autoIncrement;

  // =========================
  // Relationships
  // =========================

  @Index()
  late int subjectId;

  // =========================
  // Basic Info
  // =========================

  @Index()
  late String title;

  @enumerated
  NoteType type = NoteType.note;

  String? content;

  // =========================
  // File Info
  // =========================

  @Index()
  late String filePath;

  @Index()
  int fileSize = 0;

  int pages = 0;

  // =========================
  // User State
  // =========================

  @Index()
  bool favorite = false;

  @Index()
  bool pinned = false;

  // =========================
  // Timestamps
  // =========================

  @Index()
  DateTime createdAt = DateTime.now();

  @Index()
  DateTime updatedAt = DateTime.now();

  @Index()
  DateTime? lastOpened;
}
