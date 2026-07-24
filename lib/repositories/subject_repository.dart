import 'package:isar/isar.dart';
import 'package:studyvault/core/database/isar_service.dart';
import 'package:studyvault/core/models/subject.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/utils/app_logger.dart';

class SubjectRepository {
  SubjectRepository._();

  static final SubjectRepository instance = SubjectRepository._();

  Isar get isar => IsarService.instance.isar;

  /// Fetch all subjects belonging to a specific workspace
  Future<List<Subject>> getSubjectsForWorkspace(
    int workspaceId, {
    bool includeArchived = false,
  }) async {
    final List<Subject> list;
    if (includeArchived) {
      list = await isar.subjects
          .filter()
          .workspaceIdEqualTo(workspaceId)
          .findAll();
    } else {
      list = await isar.subjects
          .filter()
          .workspaceIdEqualTo(workspaceId)
          .and()
          .archivedEqualTo(false)
          .findAll();
    }
    AppLogger.db('SubjectRepository.getSubjectsForWorkspace', 'Fetched ${list.length} subject(s) for Workspace ID: $workspaceId');
    return list;
  }

  /// Get subject by ID
  Future<Subject?> getSubjectById(int id) async {
    final subject = await isar.subjects.get(id);
    AppLogger.db('SubjectRepository.getSubjectById', 'Found Subject ID $id: ${subject?.name ?? "null"}');
    return subject;
  }

  /// Create a new subject under a workspace
  Future<Subject> createSubject({
    required int workspaceId,
    required String name,
    int color = 0xFF6750A4,
    int icon = 0xe865,
  }) async {
    final subject = Subject()
      ..workspaceId = workspaceId
      ..name = name.trim()
      ..color = color
      ..icon = icon
      ..archived = false
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      final id = await isar.subjects.put(subject);
      subject.id = id;
    });
    AppLogger.db('SubjectRepository.createSubject', 'Created Subject: ${subject.name} (ID: ${subject.id}) under Workspace ID: $workspaceId');

    return subject;
  }

  /// Update subject
  Future<void> updateSubject(Subject subject) async {
    subject.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.subjects.put(subject);
    });
    AppLogger.db('SubjectRepository.updateSubject', 'Updated Subject ID: ${subject.id}, Name: ${subject.name}');
  }

  /// Archive or unarchive subject
  Future<void> toggleArchiveSubject(int subjectId) async {
    final subject = await getSubjectById(subjectId);
    if (subject != null) {
      subject.archived = !subject.archived;
      await updateSubject(subject);
      AppLogger.db('SubjectRepository.toggleArchiveSubject', 'Toggled archive for Subject ID: $subjectId -> Archived: ${subject.archived}');
    }
  }

  /// Delete a subject and its notes + assignments
  Future<void> deleteSubject(int subjectId) async {
    await isar.writeTxn(() async {
      await isar.notes.filter().subjectIdEqualTo(subjectId).deleteAll();
      await isar.assignments.filter().subjectIdEqualTo(subjectId).deleteAll();
      await isar.subjects.delete(subjectId);
    });
    AppLogger.db('SubjectRepository.deleteSubject', 'Deleted Subject ID: $subjectId and associated notes/assignments');
  }
}
