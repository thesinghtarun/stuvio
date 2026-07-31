import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/models/inbox_item.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/repositories/assignment_repository.dart';
import 'package:studyvault/repositories/inbox_repository.dart';
import 'package:studyvault/repositories/note_repository.dart';

class InboxProvider extends ChangeNotifier {
  List<InboxItem> _items = [];
  bool _isLoading = false;

  List<InboxItem> get items => _items;
  bool get isLoading => _isLoading;
  int get count => _items.length;

  VoidCallback? onInboxLoaded;

  InboxProvider() {
    fetchInboxItems();
  }

  Future<void> fetchInboxItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await InboxRepository.instance.getAllInboxItems();
    } catch (e, st) {
      AppLogger.error('InboxProvider.fetchInboxItems', e, st);
    } finally {
  _isLoading = false;
  notifyListeners();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    onInboxLoaded?.call();
  });
}
  }

  /// Add a file (from shared intent or picker) into Inbox
  Future<InboxItem?> addFileToInbox(
    String sourceFilePath, {
    String? customTitle,
  }) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        Fluttertoast.showToast(msg: 'File does not exist');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final inboxDir = Directory('${appDir.path}/inbox');
      if (!await inboxDir.exists()) {
        await inboxDir.create(recursive: true);
      }

      final rawName = sourceFilePath
          .split(Platform.pathSeparator)
          .last
          .split('/')
          .last;
      final title = customTitle ?? rawName;
      final ext = rawName.contains('.')
          ? rawName.split('.').last.toLowerCase()
          : '';

      String fileType = 'other';
      if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext)) {
        fileType = 'image';
      } else if (ext == 'pdf') {
        fileType = 'pdf';
      } else if ([
        'doc',
        'docx',
        'txt',
        'rtf',
        'odt',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
      ].contains(ext)) {
        fileType = 'doc';
      }

      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      final destPath =
          '${inboxDir.path}/${timeStamp}_${rawName.replaceAll(RegExp(r'[^\w.-]'), '_')}';

      final fileSize = await sourceFile.length();
      await sourceFile.copy(destPath);

      final item = await InboxRepository.instance.addInboxItem(
        title: title,
        filePath: destPath,
        fileSize: fileSize,
        fileType: fileType,
      );

      if (item != null) {
        _items.insert(0, item);
        notifyListeners();
      }
      return item;
    } catch (e, st) {
      AppLogger.error('InboxProvider.addFileToInbox', e, st);
      return null;
    }
  }

  /// Pick file from device storage and add to Inbox
  Future<bool> pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final item = await addFileToInbox(path);
        if (item != null) {
          Fluttertoast.showToast(msg: 'File added to Inbox');
          return true;
        }
      }
    } catch (e, st) {
      AppLogger.error('InboxProvider.pickAndUploadFile', e, st);
      Fluttertoast.showToast(msg: 'Failed to pick file: $e');
    }
    return false;
  }

  /// Convert InboxItem into Note / Assignment under a Subject & Workspace
  Future<bool> saveInboxItemToSubject({
    required InboxItem item,
    required int subjectId,
    required String title,
    required NoteType noteType,
    DateTime? dueDate,
    AssignmentPriority priority = AssignmentPriority.medium,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final materialsDir = Directory('${appDir.path}/materials');
      if (!await materialsDir.exists()) {
        await materialsDir.create(recursive: true);
      }

      final sourceFile = File(item.filePath);
      String destPath = item.filePath;

      if (await sourceFile.exists()) {
        final ext = item.filePath.split('.').last;
        final sanitizedFileName =
            '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(RegExp(r'[^\w.-]'), '_')}.$ext';
        destPath = '${materialsDir.path}/$sanitizedFileName';
        await sourceFile.copy(destPath);
        // Clean up inbox copy
        try {
          await sourceFile.delete();
        } catch (_) {}
      }

      // Create Note entry
      await NoteRepository.instance.createNote(
        subjectId: subjectId,
        title: title,
        type: noteType,
        filePath: destPath,
        fileSize: item.fileSize,
      );

      // If assignment type with due date, create Assignment entry as well
      if (noteType == NoteType.assignment) {
        await AssignmentRepository.instance.createAssignment(
          subjectId: subjectId,
          title: title,
          description: 'Attached document: $title',
          dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
          priority: priority,
        );
      }

      // Remove from Inbox DB & state
      await InboxRepository.instance.deleteInboxItem(item.id);
      _items.removeWhere((i) => i.id == item.id);
      notifyListeners();

      AppLogger.action(
        'INBOX_CONVERT_SUCCESS',
        'Converted Inbox item ID ${item.id} to ${noteType.name} under Subject $subjectId',
      );
      return true;
    } catch (e, st) {
      AppLogger.error('InboxProvider.saveInboxItemToSubject', e, st);
      Fluttertoast.showToast(msg: 'Error saving file: $e');
      return false;
    }
  }

  /// Delete item from inbox directly
  Future<void> deleteItem(int id) async {
    try {
      final item = _items.firstWhere((element) => element.id == id);
      final file = File(item.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await InboxRepository.instance.deleteInboxItem(id);
      _items.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e, st) {
      AppLogger.error('InboxProvider.deleteItem', e, st);
    }
  }
}
