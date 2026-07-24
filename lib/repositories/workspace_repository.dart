import 'package:isar/isar.dart';
import 'package:studyvault/core/database/isar_service.dart';
import 'package:studyvault/core/models/workspace.dart';
import 'package:studyvault/core/models/subject.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/utils/app_logger.dart';

class WorkspaceRepository {
  WorkspaceRepository._();

  static final WorkspaceRepository instance = WorkspaceRepository._();

  Isar get isar => IsarService.instance.isar;

  /// Get all workspaces for a user
  Future<List<Workspace>> getWorkspacesForUser(int userId) async {
    final list = await isar.workspaces.filter().userIdEqualTo(userId).findAll();
    AppLogger.db('WorkspaceRepository.getWorkspacesForUser', 'Fetched ${list.length} workspace(s) for User ID: $userId');
    return list;
  }

  /// Get a single workspace by ID
  Future<Workspace?> getWorkspaceById(int id) async {
    final workspace = await isar.workspaces.get(id);
    AppLogger.db('WorkspaceRepository.getWorkspaceById', 'Found workspace ID $id: ${workspace?.name ?? "null"}');
    return workspace;
  }

  /// Create a new workspace
  Future<Workspace> createWorkspace({
    required int userId,
    required String name,
    WorkspaceType type = WorkspaceType.custom,
    int icon = 0xe318,
    int color = 0xFF6750A4,
    bool isPinned = false,
  }) async {
    final workspace = Workspace()
      ..userId = userId
      ..name = name.trim()
      ..type = type
      ..icon = icon
      ..color = color
      ..isPinned = isPinned
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      final id = await isar.workspaces.put(workspace);
      workspace.id = id;
    });
    AppLogger.db('WorkspaceRepository.createWorkspace', 'Created Workspace: ${workspace.name} (ID: ${workspace.id}) for User ID: $userId');

    return workspace;
  }

  /// Update an existing workspace
  Future<void> updateWorkspace(Workspace workspace) async {
    workspace.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.workspaces.put(workspace);
    });
    AppLogger.db('WorkspaceRepository.updateWorkspace', 'Updated Workspace ID: ${workspace.id}, Name: ${workspace.name}');
  }

  /// Delete workspace and all its child subjects, notes, and assignments
  Future<void> deleteWorkspace(int workspaceId) async {
    await isar.writeTxn(() async {
      final subjects = await isar.subjects.filter().workspaceIdEqualTo(workspaceId).findAll();
      for (final subject in subjects) {
        await isar.notes.filter().subjectIdEqualTo(subject.id).deleteAll();
        await isar.assignments.filter().subjectIdEqualTo(subject.id).deleteAll();
      }
      await isar.subjects.filter().workspaceIdEqualTo(workspaceId).deleteAll();
      await isar.workspaces.delete(workspaceId);
    });
    AppLogger.db('WorkspaceRepository.deleteWorkspace', 'Deleted Workspace ID: $workspaceId and all associated subjects/notes/assignments');
  }

  /// Toggle pinned status of workspace
  Future<void> togglePinWorkspace(int workspaceId) async {
    final workspace = await getWorkspaceById(workspaceId);
    if (workspace != null) {
      workspace.isPinned = !workspace.isPinned;
      await updateWorkspace(workspace);
      AppLogger.db('WorkspaceRepository.togglePinWorkspace', 'Toggled pin for Workspace ID: $workspaceId -> Pinned: ${workspace.isPinned}');
    }
  }
}
