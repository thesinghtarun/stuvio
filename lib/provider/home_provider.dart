import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/repositories/assignment_repository.dart';
import 'package:studyvault/repositories/note_repository.dart';
import 'package:studyvault/repositories/subject_repository.dart';

class HomeProvider extends ChangeNotifier {
  // ─── State ────────────────────────────────────────────────────────────────
  int? _currentWorkspaceId;

  List<Assignment> _deadlines = [];
  bool _isLoadingDeadlines = false;
  bool _isDeadlinesExpanded = false;

  List<Assignment> _upcoming = [];
  bool _isLoadingUpcoming = false;
  bool _isUpcomingExpanded = false;

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<Assignment> get deadlines => _deadlines;
  bool get isLoadingDeadlines => _isLoadingDeadlines;
  bool get isDeadlinesExpanded => _isDeadlinesExpanded;

  List<Assignment> get upcoming => _upcoming;
  bool get isLoadingUpcoming => _isLoadingUpcoming;
  bool get isUpcomingExpanded => _isUpcomingExpanded;

  // ─── Load for workspace ───────────────────────────────────────────────────

  /// Called whenever the selected workspace changes.
  Future<void> loadForWorkspace(int? workspaceId) async {
    if (_currentWorkspaceId == workspaceId) return;
    _currentWorkspaceId = workspaceId;
    AppLogger.info(
      'HomeProvider',
      'Loading home data for workspaceId=$workspaceId',
    );
    await Future.wait([_loadDeadlines(workspaceId), _loadUpcoming(workspaceId)]);
  }

  /// Force-reload even if workspaceId hasn't changed (e.g. after saving new assignment).
  Future<void> reload() async {
    await Future.wait([
      _loadDeadlines(_currentWorkspaceId),
      _loadUpcoming(_currentWorkspaceId),
    ]);
  }

  // ─── Deadlines (due tomorrow) ─────────────────────────────────────────────
  Future<void> _loadDeadlines(int? workspaceId) async {
    _isLoadingDeadlines = true;
    notifyListeners();

    if (workspaceId == null) {
      _deadlines = [];
      _isLoadingDeadlines = false;
      notifyListeners();
      return;
    }

    try {
      final subjects = await SubjectRepository.instance
          .getSubjectsForWorkspace(workspaceId);

      if (subjects.isEmpty) {
        _deadlines = [];
        _isLoadingDeadlines = false;
        notifyListeners();
        return;
      }

      final subjectIds = subjects.map((s) => s.id).toList();
      final pending = await AssignmentRepository.instance
          .getPendingAssignmentsForSubjects(subjectIds);

      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      _deadlines = pending.where((a) {
        return a.dueDate.year == tomorrow.year &&
            a.dueDate.month == tomorrow.month &&
            a.dueDate.day == tomorrow.day;
      }).toList();

      AppLogger.info(
        'HomeProvider',
        'Deadlines loaded: ${_deadlines.length} due tomorrow',
      );
    } catch (e, st) {
      AppLogger.error('HomeProvider._loadDeadlines', e, st);
      _deadlines = [];
    } finally {
      _isLoadingDeadlines = false;
      notifyListeners();
    }
  }

  // ─── Upcoming (all pending assignments) ───────────────────────────────────
  Future<void> _loadUpcoming(int? workspaceId) async {
    _isLoadingUpcoming = true;
    notifyListeners();

    if (workspaceId == null) {
      _upcoming = [];
      _isLoadingUpcoming = false;
      notifyListeners();
      return;
    }

    try {
      final subjects = await SubjectRepository.instance
          .getSubjectsForWorkspace(workspaceId);

      if (subjects.isEmpty) {
        _upcoming = [];
        _isLoadingUpcoming = false;
        notifyListeners();
        return;
      }

      final subjectIds = subjects.map((s) => s.id).toList();
      _upcoming = await AssignmentRepository.instance
          .getPendingAssignmentsForSubjects(subjectIds);

      AppLogger.info(
        'HomeProvider',
        'Upcoming loaded: ${_upcoming.length} pending assignments',
      );
    } catch (e, st) {
      AppLogger.error('HomeProvider._loadUpcoming', e, st);
      _upcoming = [];
    } finally {
      _isLoadingUpcoming = false;
      notifyListeners();
    }
  }

  // ─── Expand/Collapse ──────────────────────────────────────────────────────
  void toggleDeadlinesExpanded() {
    _isDeadlinesExpanded = !_isDeadlinesExpanded;
    AppLogger.click('HomeProvider', 'Deadlines expanded: $_isDeadlinesExpanded');
    notifyListeners();
  }

  void toggleUpcomingExpanded() {
    _isUpcomingExpanded = !_isUpcomingExpanded;
    AppLogger.click('HomeProvider', 'Upcoming expanded: $_isUpcomingExpanded');
    notifyListeners();
  }

  // ─── Open PDF ─────────────────────────────────────────────────────────────
  Future<void> openPdfForAssignment(Assignment assignment) async {
    AppLogger.click(
      'HomeProvider',
      'Opening PDF for assignment "${assignment.title}"',
    );
    try {
      final notes = await NoteRepository.instance
          .getNotesForSubject(assignment.subjectId);

      String? targetPath;
      for (final n in notes) {
        if (n.filePath.isNotEmpty) {
          if (n.title.toLowerCase().contains(assignment.title.toLowerCase()) ||
              targetPath == null) {
            targetPath = n.filePath;
          }
        }
      }

      if (targetPath != null && targetPath.isNotEmpty) {
        const platform = MethodChannel('com.singhtarun.stuvio/open_file');
        try {
          final result = await platform.invokeMethod('openFile', {
            'filePath': targetPath,
          });
          AppLogger.action(
            'OPEN_FILE',
            'Platform openFile result: $result for $targetPath',
          );
        } on MissingPluginException {
          AppLogger.error(
            'HomeProvider',
            'MissingPluginException: App must be fully rebuilt after native Kotlin changes.',
          );
          Fluttertoast.showToast(
            msg: 'Please rebuild & restart the app to enable file opening!',
            toastLength: Toast.LENGTH_LONG,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'No attached PDF file found for this assignment',
        );
      }
    } catch (e, st) {
      AppLogger.error('HomeProvider.openPdfForAssignment', e, st);
      Fluttertoast.showToast(msg: 'Could not open file: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  static String daysLeftLabel(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;
    if (diff == 0) return 'Due Today';
    if (diff == 1) return 'Due Tomorrow';
    if (diff < 0) return 'Overdue';
    return '$diff Days Left';
  }
}
