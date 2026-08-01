import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/repositories/assignment_repository.dart';
import 'package:studyvault/repositories/note_repository.dart';
import 'package:studyvault/repositories/subject_repository.dart';

class HomeProvider extends ChangeNotifier {
  // ─── Ads ──────────────────────────────────────────────────────────────────
  BannerAd? bannerAd;

  void loadBannerAd() {
    bannerAd?.dispose();

    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-1345393972469011/3049217586',
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("Banner Loaded home tab");
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("Banner err home tab: ${error.toString()}");
          ad.dispose();
          bannerAd = null;
          notifyListeners();
        },
      ),
    );

    bannerAd!.load();
  }

  // ─── State ────────────────────────────────────────────────────────────────
  int? _currentWorkspaceId;

  bool _showInboxImg = false;
  bool _hasShownInboxPopup = false;

  List<Assignment> _deadlines = [];
  bool _isLoadingDeadlines = false;
  bool _isDeadlinesExpanded = false;

  List<Assignment> _upcoming = [];
  bool _isLoadingUpcoming = false;
  bool _isUpcomingExpanded = false;

  List<Note> _notes = [];
  bool _isLoadingNotes = false;
  bool _isNotesExpanded = false;

  List<Note> _pyqs = [];
  bool _isLoadingPYQs = false;
  bool _isPYQsExpanded = false;

  // ─── Getters ──────────────────────────────────────────────────────────────

  bool get showInboxImg => _showInboxImg;

  List<Assignment> get deadlines => _deadlines;
  bool get isLoadingDeadlines => _isLoadingDeadlines;
  bool get isDeadlinesExpanded => _isDeadlinesExpanded;

  List<Assignment> get upcoming => _upcoming;
  bool get isLoadingUpcoming => _isLoadingUpcoming;
  bool get isUpcomingExpanded => _isUpcomingExpanded;

  List<Note> get notes => _notes;
  bool get isLoadingNotes => _isLoadingNotes;
  bool get isNotesExpanded => _isNotesExpanded;

  List<Note> get pyqs => _pyqs;
  bool get isLoadingPYQs => _isLoadingPYQs;
  bool get isPYQsExpanded => _isPYQsExpanded;

  void showInboxPopupOnce(bool hasInboxItems) {
    if (_hasShownInboxPopup || !hasInboxItems) return;

    _hasShownInboxPopup = true;
    _showInboxImg = true;
    notifyListeners();
  }

  void hideInboxPopup() {
    _showInboxImg = false;
    notifyListeners();
  }

  void resetInboxPopup() {
    _showInboxImg = false;
    _hasShownInboxPopup = false;
    notifyListeners();
  }

  // ─── Load for workspace ───────────────────────────────────────────────────

  /// Called whenever the selected workspace changes.
  Future<void> loadForWorkspace(int? workspaceId) async {
    if (_currentWorkspaceId == workspaceId) return;
    _currentWorkspaceId = workspaceId;
    AppLogger.info(
      'HomeProvider',
      'Loading home data for workspaceId=$workspaceId',
    );
    await _loadDeadlines(workspaceId);
    await _loadUpcoming(workspaceId);
    await _loadNotes(workspaceId);
    await _loadPYQs(workspaceId);
  }

  /// Force-reload even if workspaceId hasn't changed.
  Future<void> reload() async {
    await _loadDeadlines(_currentWorkspaceId);
    await _loadUpcoming(_currentWorkspaceId);
    await _loadNotes(_currentWorkspaceId);
    await _loadPYQs(_currentWorkspaceId);
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
      final subjects = await SubjectRepository.instance.getSubjectsForWorkspace(
        workspaceId,
      );

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
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      // Deadline = due today OR tomorrow
      _deadlines = pending.where((a) {
        final due = DateTime(a.dueDate.year, a.dueDate.month, a.dueDate.day);
        return !due.isAfter(tomorrow);
      }).toList();

      // Sort by priority: high → medium → low
      _deadlines.sort((a, b) => b.priority.index.compareTo(a.priority.index));

      AppLogger.info(
        'HomeProvider',
        'Deadlines loaded: ${_deadlines.length} due on/before tomorrow',
      );
    } catch (e, st) {
      AppLogger.error('HomeProvider._loadDeadlines', e, st);
      _deadlines = [];
    } finally {
      _isLoadingDeadlines = false;
      notifyListeners();
    }
  }

  // ─── Upcoming (all pending assignments excluding deadlines) ───────────────
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
      final subjects = await SubjectRepository.instance.getSubjectsForWorkspace(
        workspaceId,
      );

      if (subjects.isEmpty) {
        _upcoming = [];
        _isLoadingUpcoming = false;
        notifyListeners();
        return;
      }

      final subjectIds = subjects.map((s) => s.id).toList();
      final allPending = await AssignmentRepository.instance
          .getPendingAssignmentsForSubjects(subjectIds);

      final deadlineIds = _deadlines.map((d) => d.id).toSet();
      _upcoming = allPending.where((a) => !deadlineIds.contains(a.id)).toList();

      // Sort by priority: high → medium → low
      _upcoming.sort((a, b) => b.priority.index.compareTo(a.priority.index));

      AppLogger.info(
        'HomeProvider',
        'Upcoming loaded: ${_upcoming.length} pending assignments (excluding deadlines)',
      );
    } catch (e, st) {
      AppLogger.error('HomeProvider._loadUpcoming', e, st);
      _upcoming = [];
    } finally {
      _isLoadingUpcoming = false;
      notifyListeners();
    }
  }

  // ─── Mark Assignment Submitted ─────────────────────────────────────────────
  Future<void> markAssignmentSubmitted(Assignment assignment) async {
    try {
      assignment.submitted = true;
      assignment.status = AssignmentStatus.completed;
      await AssignmentRepository.instance.updateAssignment(assignment);

      _deadlines.removeWhere((a) => a.id == assignment.id);
      _upcoming.removeWhere((a) => a.id == assignment.id);
      notifyListeners();

      Fluttertoast.showToast(msg: 'Assignment marked as submitted');
      await reload();
    } catch (e, st) {
      AppLogger.error('HomeProvider.markAssignmentSubmitted', e, st);
      Fluttertoast.showToast(msg: 'Failed to mark assignment as submitted');
    }
  }

  // ─── Notes ────────────────────────────────────────────────────────────────
  Future<void> _loadNotes(int? workspaceId) async {
    _isLoadingNotes = true;
    notifyListeners();

    if (workspaceId == null) {
      _notes = [];
      _isLoadingNotes = false;
      notifyListeners();
      return;
    }

    try {
      final subjects = await SubjectRepository.instance.getSubjectsForWorkspace(
        workspaceId,
      );

      if (subjects.isEmpty) {
        _notes = [];
        _isLoadingNotes = false;
        notifyListeners();
        return;
      }

      final List<Note> allNotes = [];
      for (final s in subjects) {
        final subjectNotes = await NoteRepository.instance.getNotesForSubject(
          s.id,
        );
        allNotes.addAll(subjectNotes);
      }

      allNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      // Exclude notes that were auto-created as assignment PDF attachments
      _notes = allNotes
          .where((n) => !n.title.endsWith('(Attached PDF)'))
          .toList();

      AppLogger.info('HomeProvider', 'Notes loaded: ${_notes.length} note(s)');
    } catch (e, st) {
      AppLogger.error('HomeProvider._loadNotes', e, st);
      _notes = [];
    } finally {
      _isLoadingNotes = false;
      notifyListeners();
    }
  }

  // ─── PYQs ────────────────────────────────────────────────────────────────
  Future<void> _loadPYQs(int? workspaceId) async {
    _isLoadingPYQs = true;
    notifyListeners();

    if (workspaceId == null) {
      _pyqs = [];
      _isLoadingPYQs = false;
      notifyListeners();
      return;
    }

    try {
      final subjects = await SubjectRepository.instance.getSubjectsForWorkspace(
        workspaceId,
      );

      if (subjects.isEmpty) {
        _pyqs = [];
        _isLoadingPYQs = false;
        notifyListeners();
        return;
      }

      final List<Note> allPyqs = [];

      for (final subject in subjects) {
        final subjectPyqs = await NoteRepository.instance.getNotesForSubject(
          subject.id,
          type: NoteType.pyq,
        );

        allPyqs.addAll(subjectPyqs);
      }

      allPyqs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      _pyqs = allPyqs;

      AppLogger.info('HomeProvider', 'PYQs loaded: ${_pyqs.length}');
    } catch (e, st) {
      AppLogger.error('HomeProvider._loadPYQs', e, st);
      _pyqs = [];
    } finally {
      _isLoadingPYQs = false;
      notifyListeners();
    }
  }

  // ─── Expand/Collapse ──────────────────────────────────────────────────────
  void toggleDeadlinesExpanded() {
    _isDeadlinesExpanded = !_isDeadlinesExpanded;
    AppLogger.click(
      'HomeProvider',
      'Deadlines expanded: $_isDeadlinesExpanded',
    );
    notifyListeners();
  }

  void toggleUpcomingExpanded() {
    _isUpcomingExpanded = !_isUpcomingExpanded;
    AppLogger.click('HomeProvider', 'Upcoming expanded: $_isUpcomingExpanded');
    notifyListeners();
  }

  void toggleNotesExpanded() {
    _isNotesExpanded = !_isNotesExpanded;
    AppLogger.click('HomeProvider', 'Notes expanded: $_isNotesExpanded');
    notifyListeners();
  }

  void togglePYQsExpanded() {
    _isPYQsExpanded = !_isPYQsExpanded;
    AppLogger.click('HomeProvider', 'PYQs expanded: $_isPYQsExpanded');
    notifyListeners();
  }

  // ─── Open PDF ─────────────────────────────────────────────────────────────
  Future<void> openPdfForAssignment(Assignment assignment) async {
    AppLogger.click(
      'HomeProvider',
      'Opening PDF for assignment "${assignment.title}"',
    );
    try {
      final notes = await NoteRepository.instance.getNotesForSubject(
        assignment.subjectId,
      );

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

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }
}
