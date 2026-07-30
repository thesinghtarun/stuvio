import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/provider/inbox_provider.dart';

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
    AppLogger.info(
      'ShareHandlerService',
      'Splash active: $active | splashDone: $_splashDone',
    );

    if (_splashDone) {
      _processInboxQueue();
    }
  }

  void init(GlobalKey<NavigatorState> navigatorKey) {
    if (_isInitialized) return;
    _isInitialized = true;
    _navigatorKey = navigatorKey;
    debugPrint('🚀 [SHARE_SERVICE] Initializing ShareHandlerService...');

    try {
      // 1. Listen for runtime shares while app is in foreground/background
      _intentDataStreamSubscription = FlutterSharingIntent.instance
          .getMediaStream()
          .listen(
            (List<SharedFile> value) {
              debugPrint(
                '🚀 [SHARE_SERVICE] getMediaStream fired! Raw count: ${value.length}',
              );
              for (var f in value) {
                debugPrint(
                  '   -> SharedFile path: ${f.value}, type: ${f.type}',
                );
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
      FlutterSharingIntent.instance
          .getInitialSharing()
          .then((List<SharedFile> value) {
            debugPrint(
              '🚀 [SHARE_SERVICE] getInitialSharing fired! Raw count: ${value.length}',
            );
            for (var f in value) {
              debugPrint(
                '   -> Cold SharedFile path: ${f.value}, type: ${f.type}',
              );
            }
            final validPaths = _extractPaths(value);
            if (validPaths.isNotEmpty) {
              _onNewFilesReceived(validPaths);
            }
          })
          .catchError((err) {
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
    debugPrint(
      '🚀 [SHARE_SERVICE] _onNewFilesReceived: ${paths.length} file(s)',
    );
    for (final p in paths) {
      if (!_pendingFilePaths.contains(p)) {
        _pendingFilePaths.add(p);
      }
    }
    _processInboxQueue();
  }

  void _processInboxQueue() async {
    debugPrint(
      '🚀 [SHARE_SERVICE] _processInboxQueue: pending=${_pendingFilePaths.length}, splashDone=$_splashDone',
    );
    if (_pendingFilePaths.isEmpty) return;

    if (!_splashDone) {
      debugPrint('🚀 [SHARE_SERVICE] Waiting for splash screen to complete...');
      return;
    }

    final pathsToProcess = List<String>.from(_pendingFilePaths);
    _pendingFilePaths.clear();

    int savedCount = 0;
    final ctx = _navigatorKey?.currentContext;

    InboxProvider? inboxProvider;
    if (ctx != null && ctx.mounted) {
      try {
        inboxProvider = ctx.read<InboxProvider>();
      } catch (_) {}
    }

    for (final path in pathsToProcess) {
      if (inboxProvider != null) {
        final item = await inboxProvider.addFileToInbox(path);
        if (item != null) savedCount++;
      } else {
        // Fallback using direct method
        final provider = InboxProvider();
        final repoItem = await provider.addFileToInbox(path);
        if (repoItem != null) savedCount++;
      }
    }

    if (savedCount > 0) {
      Fluttertoast.showToast(
        msg: "Saved $savedCount file(s) to Inbox",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      if (ctx != null && ctx.mounted) {
        try {
          ctx.read<InboxProvider>().fetchInboxItems();
        } catch (_) {}
      }
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}
