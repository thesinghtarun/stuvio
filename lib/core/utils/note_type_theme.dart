import 'package:flutter/material.dart';
import 'package:studyvault/core/models/note.dart';

/// Canonical icon + color mapping for [NoteType] used app-wide.
/// All screens should reference this to stay consistent.
class NoteTypeTheme {
  NoteTypeTheme._();

  // ── Icons ──────────────────────────────────────────────────────────────────
  static IconData icon(NoteType type) {
    switch (type) {
      case NoteType.note:
        return Icons.menu_book_rounded;
      case NoteType.assignment:
        return Icons.picture_as_pdf_rounded;
      case NoteType.pyq:
        return Icons.quiz_rounded;
      case NoteType.lab:
        return Icons.science_rounded;
    }
  }

  // ── Colors ─────────────────────────────────────────────────────────────────
  static Color color(NoteType type) {
    switch (type) {
      case NoteType.note:
        return Colors.deepPurple;
      case NoteType.assignment:
        return const Color(0xFFEF4444);
      case NoteType.pyq:
        return Colors.blue;
      case NoteType.lab:
        return Colors.green;
    }
  }

  // ── Display labels ─────────────────────────────────────────────────────────
  static String label(NoteType type) {
    switch (type) {
      case NoteType.note:
        return 'Note';
      case NoteType.assignment:
        return 'Assignment';
      case NoteType.pyq:
        return 'PYQ';
      case NoteType.lab:
        return 'Lab Manual';
    }
  }

  // ── Assignment icon + color (for consistency across the app) ───────────────
  static const IconData assignmentIcon = Icons.assignment_rounded;
  static const Color assignmentColor = Colors.orange;

  /// Maps a raw [NoteType] name string (e.g. from category labels) to a type.
  static NoteType? fromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'note':
        return NoteType.note;
      case 'assignment':
      // case 'a / reference':
        return NoteType.assignment;
      case 'pyq':
        return NoteType.pyq;
      case 'lab manual':
      case 'lab':
        return NoteType.lab;
      default:
        return null;
    }
  }
}
