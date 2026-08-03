import 'package:flutter/material.dart';
import 'package:studyvault/core/models/note.dart';

class ShareOverlayProvider extends ChangeNotifier {
  /// Whether the share overlay is visible
  bool _isSharing = false;
  bool get isSharing => _isSharing;

  /// Whether the floating card is currently over the share target
  bool _isOverShareTarget = false;
  bool get isOverShareTarget => _isOverShareTarget;

  /// Current dragged note
  Note? _currentNote;
  Note? get currentNote => _currentNote;

  /// Global finger position
  Offset _fingerPosition = Offset.zero;
  Offset get fingerPosition => _fingerPosition;

  /// Initial card position on the screen
  Offset _cardOrigin = Offset.zero;
  Offset get cardOrigin => _cardOrigin;

  /// Card size
  Size _cardSize = Size.zero;
  Size get cardSize => _cardSize;

  /// Starts the drag/share experience
  void startSharing({
    required Note note,
    required Offset cardOrigin,
    required Size cardSize,
    required Offset fingerPosition,
  }) {
    _currentNote = note;
    _cardOrigin = cardOrigin;
    _cardSize = cardSize;
    _fingerPosition = fingerPosition;

    _isSharing = true;
    _isOverShareTarget = false;

    notifyListeners();
  }

  /// Updates finger position while dragging
  void updateFingerPosition(Offset position) {
    if (!_isSharing) return;

    _fingerPosition = position;
    notifyListeners();
  }

  void hideOverlay() {
    if (!_isSharing) return;

    _isSharing = false;
    notifyListeners();
  }

  /// Called continuously by the share target
  void setHoveringShareTarget(bool hovering) {
    if (_isOverShareTarget == hovering) return;

    _isOverShareTarget = hovering;
    notifyListeners();
  }

  /// Reset everything after drag finishes
  void stopSharing() {
    _isSharing = false;
    _isOverShareTarget = false;

    _currentNote = null;
    _fingerPosition = Offset.zero;
    _cardOrigin = Offset.zero;
    _cardSize = Size.zero;

    notifyListeners();
  }
}
