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

  Future<void> _start(LongPressStartDetails details) async {
    final provider = context.read<ShareOverlayProvider>();

    final renderBox = _cardKey.currentContext!.findRenderObject() as RenderBox;

    final position = renderBox.localToGlobal(Offset.zero);

    provider.startSharing(
      note: widget.note,
      cardOrigin: position,
      cardSize: renderBox.size,
      fingerPosition: details.globalPosition,
    );

    HapticFeedback.mediumImpact();

    _sharingStarted = true;
  }

  void _update(LongPressMoveUpdateDetails details) {
    if (!_sharingStarted) return;

    context.read<ShareOverlayProvider>().updateFingerPosition(
      details.globalPosition,
    );
  }

  void _end() {
    if (!_sharingStarted) return;

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
