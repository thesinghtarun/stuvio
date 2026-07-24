import 'package:isar/isar.dart';
import 'package:studyvault/core/database/isar_service.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/utils/app_logger.dart';

class AssignmentRepository {
  AssignmentRepository._();

  static final AssignmentRepository instance = AssignmentRepository._();

  Isar get isar => IsarService.instance.isar;

  /// Get all assignments for a subject
  Future<List<Assignment>> getAssignmentsForSubject(
    int subjectId, {
    bool? submitted,
  }) async {
    final List<Assignment> list;
    if (submitted != null) {
      list = await isar.assignments
          .filter()
          .subjectIdEqualTo(subjectId)
          .and()
          .submittedEqualTo(submitted)
          .findAll();
    } else {
      list = await isar.assignments
          .filter()
          .subjectIdEqualTo(subjectId)
          .findAll();
    }
    AppLogger.db('AssignmentRepository.getAssignmentsForSubject', 'Fetched ${list.length} assignment(s) [Submitted: ${submitted ?? "all"}] for Subject ID: $subjectId');
    return list;
  }

  /// Get pending (unsubmitted) assignments across all given subject IDs
  Future<List<Assignment>> getPendingAssignmentsForSubjects(
    List<int> subjectIds,
  ) async {
    if (subjectIds.isEmpty) return [];
    final list = await isar.assignments
        .filter()
        .anyOf(subjectIds, (q, int subjectId) => q.subjectIdEqualTo(subjectId))
        .and()
        .submittedEqualTo(false)
        .sortByDueDate()
        .findAll();
    AppLogger.db('AssignmentRepository.getPendingAssignmentsForSubjects', 'Fetched ${list.length} pending assignment(s) across ${subjectIds.length} subject(s)');
    return list;
  }

  /// Get assignment by ID
  Future<Assignment?> getAssignmentById(int id) async {
    final assignment = await isar.assignments.get(id);
    AppLogger.db('AssignmentRepository.getAssignmentById', 'Found Assignment ID $id: ${assignment?.title ?? "null"}');
    return assignment;
  }

  /// Create a new assignment
  Future<Assignment> createAssignment({
    required int subjectId,
    required String title,
    String description = '',
    required DateTime dueDate,
    AssignmentPriority priority = AssignmentPriority.medium,
    bool submitted = false,
  }) async {
    final assignment = Assignment()
      ..subjectId = subjectId
      ..title = title.trim()
      ..description = description.trim()
      ..dueDate = dueDate
      ..priority = priority
      ..submitted = submitted
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      final id = await isar.assignments.put(assignment);
      assignment.id = id;
    });
    AppLogger.db('AssignmentRepository.createAssignment', 'Created Assignment: "${assignment.title}" (Priority: ${assignment.priority.name}, ID: ${assignment.id}) under Subject ID: $subjectId');

    return assignment;
  }

  /// Update existing assignment
  Future<void> updateAssignment(Assignment assignment) async {
    assignment.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.assignments.put(assignment);
    });
    AppLogger.db('AssignmentRepository.updateAssignment', 'Updated Assignment ID: ${assignment.id}, Title: "${assignment.title}"');
  }

  /// Toggle submitted status of an assignment
  Future<void> toggleSubmission(int assignmentId) async {
    final assignment = await getAssignmentById(assignmentId);
    if (assignment != null) {
      assignment.submitted = !assignment.submitted;
      await updateAssignment(assignment);
      AppLogger.db('AssignmentRepository.toggleSubmission', 'Toggled submission for Assignment ID $assignmentId -> Submitted: ${assignment.submitted}');
    }
  }

  /// Delete assignment
  Future<void> deleteAssignment(int assignmentId) async {
    await isar.writeTxn(() async {
      await isar.assignments.delete(assignmentId);
    });
    AppLogger.db('AssignmentRepository.deleteAssignment', 'Deleted Assignment ID: $assignmentId');
  }
}
