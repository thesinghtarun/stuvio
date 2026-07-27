import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/repositories/assignment_repository.dart';
import 'package:studyvault/repositories/subject_repository.dart';
import 'package:studyvault/repositories/user_repository.dart';
import 'package:studyvault/repositories/workspace_repository.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';

class ProfileProvider extends ChangeNotifier {
  static const _avatarPathKey = 'profile_avatar_path';

  // ─── State ────────────────────────────────────────────────────────────────
  String? _avatarPath;
  int _workspaceCount = 0;
  int _subjectCount = 0;
  int _assignmentCount = 0;
  bool _isLoading = false;
  DateTime? _memberSince;

  // ─── Getters ──────────────────────────────────────────────────────────────
  String? get avatarPath => _avatarPath;
  int get workspaceCount => _workspaceCount;
  int get subjectCount => _subjectCount;
  int get assignmentCount => _assignmentCount;
  bool get isLoading => _isLoading;
  DateTime? get memberSince => _memberSince;

  // ─── Load ─────────────────────────────────────────────────────────────────
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load avatar path from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _avatarPath = prefs.getString(_avatarPathKey);

      // Load user info
      final user = await UserRepository.instance.getUser();
      _memberSince = user?.createdAt;

      if (user == null) {
        _workspaceCount = 0;
        _subjectCount = 0;
        _assignmentCount = 0;
        AppLogger.info('ProfileProvider', 'No user found');
        return;
      }

      // Load workspaces
      final workspaces = await WorkspaceRepository.instance
          .getWorkspacesForUser(user.id);
      _workspaceCount = workspaces.length;

      // Load subjects across all workspaces
      int totalSubjects = 0;
      int totalAssignments = 0;

      for (final workspace in workspaces) {
        final subjects = await SubjectRepository.instance
            .getSubjectsForWorkspace(workspace.id);
        totalSubjects += subjects.length;

        // Count pending assignments for each subject
        if (subjects.isNotEmpty) {
          final subjectIds = subjects.map((s) => s.id).toList();
          final assignments = await AssignmentRepository.instance
              .getPendingAssignmentsForSubjects(subjectIds);
          totalAssignments += assignments.length;
        }
      }

      _subjectCount = totalSubjects;
      _assignmentCount = totalAssignments;

      AppLogger.info(
        'ProfileProvider',
        'Loaded: $_workspaceCount workspaces, $_subjectCount subjects, $_assignmentCount pending assignments',
      );
    } catch (e, st) {
      AppLogger.error('ProfileProvider.load', e, st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Avatar ───────────────────────────────────────────────────────────────
  Future<void> setAvatarPath(String path) async {
    _avatarPath = path;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarPathKey, path);
    AppLogger.action('ProfileProvider', 'Avatar path saved: $path');
  }

  Future<void> clearAvatar() async {
    _avatarPath = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarPathKey);
    AppLogger.action('ProfileProvider', 'Avatar path cleared');
  }

  // ─── Username ─────────────────────────────────────────────────────────────
  Future<void> updateUserName({
    required String newName,
    required WorkspaceCounterProvider workspaceProvider,
  }) async {
    final user = await UserRepository.instance.getUser();
    if (user == null) return;

    user.name = newName.trim();
    await UserRepository.instance.updateUser(user);
    workspaceProvider.setUserName(newName.trim());
    AppLogger.action('ProfileProvider', 'Username updated to: "$newName"');
  }
}
