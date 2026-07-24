import 'package:isar/isar.dart';
import 'package:studyvault/core/database/isar_service.dart';
import 'package:studyvault/core/models/user.dart';
import 'package:studyvault/core/utils/app_logger.dart';

class UserRepository {
  UserRepository._();

  static final UserRepository instance = UserRepository._();

  final isar = IsarService.instance.isar;

  Future<User?> getUser() async {
    final users = await isar.users.where().findAll();
    final user = users.isEmpty ? null : users.first;
    AppLogger.db('UserRepository.getUser', 'Found User: ${user?.name ?? "None (null)"}');
    return user;
  }

  Future<void> createUser(String name) async {
    final user = User()..name = name;

    await isar.writeTxn(() async {
      await isar.users.put(user);
    });
    AppLogger.db('UserRepository.createUser', 'Created User: $name (ID: ${user.id})');
  }

  Future<void> updateUser(User user) async {
    user.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.users.put(user);
    });
    AppLogger.db('UserRepository.updateUser', 'Updated User ID: ${user.id}, Name: ${user.name}');
  }

  Future<void> updateCurrentWorkspace(int workspaceId) async {
    final user = await getUser();

    if (user == null) return;

    user.currentWorkspaceId = workspaceId;
    user.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.users.put(user);
    });
    AppLogger.db('UserRepository.updateCurrentWorkspace', 'Set active workspace to ID: $workspaceId for User: ${user.name}');
  }
}