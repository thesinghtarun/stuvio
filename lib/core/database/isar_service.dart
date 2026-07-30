import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:studyvault/core/utils/app_logger.dart';

import '../models/user.dart';
import '../models/workspace.dart';
import '../models/subject.dart';
import '../models/note.dart';
import '../models/assignment.dart';
import '../models/inbox_item.dart';

class IsarService {
  IsarService._();

  static final IsarService instance = IsarService._();

  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    isar = await Isar.open(
      [
        UserSchema,
        WorkspaceSchema,
        SubjectSchema,
        NoteSchema,
        AssignmentSchema,
        InboxItemSchema,
      ],
      directory: dir.path,
      inspector: true,
    );
    AppLogger.db('Isar DB Initialized', 'Path: ${dir.path}');
  }
}