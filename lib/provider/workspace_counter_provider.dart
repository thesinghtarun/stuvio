import 'package:flutter/foundation.dart';
import 'package:studyvault/core/models/workspace.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/repositories/user_repository.dart';
import 'package:studyvault/repositories/workspace_repository.dart';

class WorkspaceCounterProvider extends ChangeNotifier {
  int _counter = 0;
  String _userName = "User";
  List<Workspace> _workspaces = [];
  Workspace? _selectedWorkspace;

  int get counter => _counter;
  String get userName => _userName;
  bool get hasWorkspace => _counter > 0;
  List<Workspace> get workspaces => _workspaces;
  Workspace? get selectedWorkspace => _selectedWorkspace;

  void setUserName(String userName) {
    _userName = userName;
    AppLogger.info('WorkspaceCounterProvider', 'UserName updated: "$userName"');
    notifyListeners();
  }

  /// Load saved user & workspace state directly from Isar DB
  Future<void> load() async {
    final user = await UserRepository.instance.getUser();
    if (user != null) {
      _userName = user.name;
      _workspaces = await WorkspaceRepository.instance.getWorkspacesForUser(user.id);
      _counter = _workspaces.length;
      if (_workspaces.isNotEmpty) {
        if (user.currentWorkspaceId != null) {
          _selectedWorkspace = _workspaces.firstWhere(
            (w) => w.id == user.currentWorkspaceId,
            orElse: () => _workspaces.first,
          );
        } else {
          _selectedWorkspace = _workspaces.first;
        }
      } else {
        _selectedWorkspace = null;
      }
    } else {
      _userName = "User";
      _counter = 0;
      _workspaces = [];
      _selectedWorkspace = null;
    }
    AppLogger.info(
      'WorkspaceCounterProvider',
      'Loaded from Isar DB: counter=$_counter, userName="$_userName", activeWorkspace="${_selectedWorkspace?.name}"',
    );
    notifyListeners();
  }

  /// Select a new active workspace
  Future<void> selectWorkspace(Workspace workspace) async {
    _selectedWorkspace = workspace;
    notifyListeners();
    await UserRepository.instance.updateCurrentWorkspace(workspace.id);
    AppLogger.action('WORKSPACE_PROVIDER', 'Switched current workspace to: ${workspace.name} (ID: ${workspace.id})');
  }

  /// Refresh state from Isar DB
  Future<void> refresh() async {
    await load();
  }

  /// Increase workspace count (Legacy helper compatibility)
  Future<void> increment() async {
    await load();
    AppLogger.action('WORKSPACE_COUNTER', 'Refreshed workspace count from Isar DB: $_counter');
  }

  /// Decrease workspace count (Legacy helper compatibility)
  Future<void> decrement() async {
    await load();
    AppLogger.action('WORKSPACE_COUNTER', 'Refreshed workspace count from Isar DB: $_counter');
  }

  /// Reset workspace count (Legacy helper compatibility)
  Future<void> reset() async {
    await load();
    AppLogger.action('WORKSPACE_COUNTER', 'Reset/Refreshed workspace count from Isar DB: $_counter');
  }
}
