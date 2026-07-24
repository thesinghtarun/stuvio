import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/repositories/note_repository.dart';
import 'package:studyvault/repositories/subject_repository.dart';
import 'package:studyvault/repositories/user_repository.dart';
import 'package:studyvault/repositories/workspace_repository.dart';
import 'package:studyvault/screens/widgets/save_shared_pdf_dialog.dart';

class ShareHandlerService {
  ShareHandlerService._();

  static final ShareHandlerService instance = ShareHandlerService._();

  StreamSubscription? _intentDataStreamSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;

  final List<String> _pendingFilePaths = [];
  bool _splashDone = false;
  bool _isInitialized = false;

  /// Called by SplashScreen when main screen navigation is complete
  void setSplashActive(bool active) {
    debugPrint('🚀 [SHARE_SERVICE] setSplashActive called with active=$active');
    _splashDone = !active;
    AppLogger.info('ShareHandlerService', 'Splash active: $active | splashDone: $_splashDone');

    if (_splashDone) {
      _tryPresentDialogOrQueue();
    }
  }

  void init(GlobalKey<NavigatorState> navigatorKey) {
    if (_isInitialized) return;
    _isInitialized = true;
    _navigatorKey = navigatorKey;
    debugPrint('🚀 [SHARE_SERVICE] Initializing ShareHandlerService...');

    try {
      // 1. Listen for runtime shares while app is in foreground/background
      _intentDataStreamSubscription = FlutterSharingIntent.instance.getMediaStream().listen(
        (List<SharedFile> value) {
          debugPrint('🚀 [SHARE_SERVICE] getMediaStream fired! Raw count: ${value.length}');
          for (var f in value) {
            debugPrint('   -> SharedFile path: ${f.value}, type: ${f.type}');
          }
          final validPaths = _extractPaths(value);
          if (validPaths.isNotEmpty) {
            _onNewFilesReceived(validPaths);
          }
        },
        onError: (err) {
          debugPrint('❌ [SHARE_SERVICE] Error in getMediaStream: $err');
          AppLogger.error('ShareHandlerService.getMediaStream', err);
        },
      );

      // 2. Get initial shared files on cold launch
      FlutterSharingIntent.instance.getInitialSharing().then((List<SharedFile> value) {
        debugPrint('🚀 [SHARE_SERVICE] getInitialSharing fired! Raw count: ${value.length}');
        for (var f in value) {
          debugPrint('   -> Cold SharedFile path: ${f.value}, type: ${f.type}');
        }
        final validPaths = _extractPaths(value);
        if (validPaths.isNotEmpty) {
          _onNewFilesReceived(validPaths);
        }
      }).catchError((err) {
        debugPrint('❌ [SHARE_SERVICE] Error in getInitialSharing: $err');
        AppLogger.error('ShareHandlerService.getInitialSharing', err);
      });
    } catch (e, st) {
      debugPrint('❌ [SHARE_SERVICE] Exception in init: $e');
      AppLogger.error('ShareHandlerService.init', e, st);
    }
  }

  List<String> _extractPaths(List<SharedFile> files) {
    return files
        .map((f) => f.value)
        .where((p) => p != null && p.isNotEmpty)
        .cast<String>()
        .toList();
  }

  void _onNewFilesReceived(List<String> paths) {
    debugPrint('🚀 [SHARE_SERVICE] _onNewFilesReceived: ${paths.length} file(s)');
    // Add new paths avoiding duplicates
    for (final p in paths) {
      if (!_pendingFilePaths.contains(p)) {
        _pendingFilePaths.add(p);
      }
    }
    _tryPresentDialogOrQueue();
  }

  void _tryPresentDialogOrQueue() {
    debugPrint('🚀 [SHARE_SERVICE] _tryPresentDialogOrQueue: pending=${_pendingFilePaths.length}, splashDone=$_splashDone');
    if (_pendingFilePaths.isEmpty) return;

    if (!_splashDone) {
      debugPrint('🚀 [SHARE_SERVICE] Waiting for splash screen to complete...');
      return;
    }

    final ctx = _navigatorKey?.currentContext;
    if (ctx != null && ctx.mounted) {
      final pathsToProcess = List<String>.from(_pendingFilePaths);
      _pendingFilePaths.clear();

      if (pathsToProcess.length == 1) {
        debugPrint('🚀 [SHARE_SERVICE] Presenting dialog for single file: ${pathsToProcess.first}');
        SaveSharedPdfDialog.show(ctx, pathsToProcess.first);
      } else {
        debugPrint('🚀 [SHARE_SERVICE] Batch saving ${pathsToProcess.length} files...');
        _saveMultipleFilesInstantly(pathsToProcess);
      }
    } else {
      debugPrint('🚀 [SHARE_SERVICE] Navigator context is null/unmounted. Retrying in 500ms...');
      Future.delayed(const Duration(milliseconds: 500), () {
        _tryPresentDialogOrQueue();
      });
    }
  }

  Future<void> _saveMultipleFilesInstantly(List<String> filePaths) async {
    debugPrint('🚀 [SHARE_SERVICE] _saveMultipleFilesInstantly for ${filePaths.length} files');
    try {
      final user = await UserRepository.instance.getUser();
      if (user == null) {
        Fluttertoast.showToast(msg: "Please complete setup first");
        return;
      }

      final workspaces = await WorkspaceRepository.instance.getWorkspacesForUser(user.id);
      if (workspaces.isEmpty) {
        Fluttertoast.showToast(msg: "Please create a workspace first");
        return;
      }

      final activeWorkspace = user.currentWorkspaceId != null
          ? workspaces.firstWhere((w) => w.id == user.currentWorkspaceId, orElse: () => workspaces.first)
          : workspaces.first;

      final subjects = await SubjectRepository.instance.getSubjectsForWorkspace(activeWorkspace.id);
      if (subjects.isEmpty) {
        Fluttertoast.showToast(msg: "Please create a subject first");
        return;
      }

      final targetSubject = subjects.first;
      final appDir = await getApplicationDocumentsDirectory();
      final materialsDir = Directory('${appDir.path}/materials');
      if (!await materialsDir.exists()) {
        await materialsDir.create(recursive: true);
      }

      int savedCount = 0;
      for (final filePath in filePaths) {
        final sourceFile = File(filePath);
        if (await sourceFile.exists()) {
          final rawFileName = filePath.split(Platform.pathSeparator).last.split('/').last.replaceAll('.pdf', '');
          final sanitizedFileName = '${DateTime.now().millisecondsSinceEpoch}_${rawFileName.replaceAll(RegExp(r'[^\w.-]'), '_')}.pdf';
          final destPath = '${materialsDir.path}/$sanitizedFileName';
          final fileSize = await sourceFile.length();
          await sourceFile.copy(destPath);

          await NoteRepository.instance.createNote(
            subjectId: targetSubject.id,
            title: rawFileName,
            type: NoteType.pdf,
            filePath: destPath,
            fileSize: fileSize,
          );
          savedCount++;
        }
      }

      debugPrint('🚀 [SHARE_SERVICE] Batch saved $savedCount files to subject: ${targetSubject.name}');
      Fluttertoast.showToast(
        msg: "Saved $savedCount file(s) in ${targetSubject.name}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e, st) {
      debugPrint('❌ [SHARE_SERVICE] Error saving multiple files: $e');
      AppLogger.error('ShareHandlerService._saveMultipleFilesInstantly', e, st);
      Fluttertoast.showToast(msg: "Failed to save files");
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}
