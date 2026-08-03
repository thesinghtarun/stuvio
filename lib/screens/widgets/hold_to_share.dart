import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/provider/share_overlay_provider.dart';
import 'package:studyvault/services/drag_share_service.dart';

class HoldToShare extends StatefulWidget {
  final Widget child;
  final Note note;

  const HoldToShare({super.key, required this.child, required this.note});

  @override
  State<HoldToShare> createState() => _HoldToShareState();
}

class _HoldToShareState extends State<HoldToShare> {
  final GlobalKey _cardKey = GlobalKey();

  bool _sharingStarted = false;
  bool _nativeDragStarted = false;

  Offset? _dragStartPosition;

  Future<void> _start(LongPressStartDetails details) async {
    print("MOVE");
    final provider = context.read<ShareOverlayProvider>();

    final renderBox = _cardKey.currentContext!.findRenderObject() as RenderBox;

    final position = renderBox.localToGlobal(Offset.zero);

    _dragStartPosition = details.globalPosition;

    _nativeDragStarted = false;

    provider.startSharing(
      note: widget.note,
      cardOrigin: position,
      cardSize: renderBox.size,
      fingerPosition: details.globalPosition,
    );

    // final success = await DragShareService.startDrag(
    //   filePath: widget.note.filePath,
    //   title: widget.note.title,
    // );

    // if (success) {
    //   provider.hideOverlay();
    // }

    HapticFeedback.mediumImpact();

    _sharingStarted = true;
  }

  Future<void> _update(LongPressMoveUpdateDetails details) async {
    if (!_sharingStarted) return;

    final provider = context.read<ShareOverlayProvider>();

    provider.updateFingerPosition(details.globalPosition);

    if (!_nativeDragStarted) {
      final distance = (details.globalPosition - _dragStartPosition!).distance;

      if (distance > 24) {
        _nativeDragStarted = true;

        final success = await DragShareService.startDrag(
          filePath: widget.note.filePath,
          title: widget.note.title,
        );

        if (success) {
          provider.hideOverlay();
        }
      }
    }
  }

  void _end() {
    if (!_sharingStarted) return;

    if (_nativeDragStarted) {
      return;
    }

    _sharingStarted = false;

    context.read<ShareOverlayProvider>().stopSharing();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      onLongPressStart: _start,

      onLongPressMoveUpdate: _update,

      onLongPressEnd: (_) => _end(),

      onLongPressCancel: _end,

      child: KeyedSubtree(key: _cardKey, child: widget.child),
    );
  }
}
