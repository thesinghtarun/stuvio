import 'package:flutter/material.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/subject.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/repositories/assignment_repository.dart';
import 'package:studyvault/repositories/note_repository.dart';
import 'package:studyvault/repositories/subject_repository.dart';

class SubjectProvider extends ChangeNotifier {
  SubjectProvider();

  final PageController pageController = PageController(viewportFraction: 0.88);

  int? _workspaceId;

  bool _isLoading = false;

  List<Subject> _subjects = [];

  int _selectedIndex = 0;

  List<Note> _recentFiles = [];

  int _notesCount = 0;
  int _assignmentCount = 0;
  int _pyqCount = 0;
  int _labCount = 0;

  bool get isLoading => _isLoading;

  List<Subject> get subjects => _subjects;

  int get selectedIndex => _selectedIndex;

  Subject? get selectedSubject =>
      _subjects.isEmpty ? null : _subjects[_selectedIndex];

  List<Note> get recentFiles => _recentFiles;

  int get notesCount => _notesCount;

  int get assignmentCount => _assignmentCount;

  int get pyqCount => _pyqCount;

  int get labCount => _labCount;

  Future<void> loadForWorkspace(int? workspaceId) async {
    if (_workspaceId == workspaceId) return;

    _workspaceId = workspaceId;

    _selectedIndex = 0;

    _subjects = [];

    _recentFiles = [];

    _notesCount = 0;
    _assignmentCount = 0;
    _pyqCount = 0;
    _labCount = 0;

    notifyListeners();

    if (workspaceId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _subjects = await SubjectRepository.instance.getSubjectsForWorkspace(
        workspaceId,
      );

      AppLogger.info("SubjectProvider", "Loaded ${_subjects.length} subjects");

      if (_subjects.isNotEmpty) {
        await _loadSubjectData(_subjects.first);
      }
    } catch (e, st) {
      AppLogger.error("SubjectProvider.loadForWorkspace", e, st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> onPageChanged(int index) async {
    if (index == _selectedIndex) return;

    _selectedIndex = index;

    notifyListeners();

    await _loadSubjectData(_subjects[index]);
  }

  Future<void> _loadSubjectData(Subject subject) async {
    _isLoading = true;
    notifyListeners();

    try {
      final notes = await NoteRepository.instance.getNotesForSubject(
        subject.id,
      );

      final assignments = await AssignmentRepository.instance
          .getAssignmentsForSubject(subject.id);

      _notesCount = notes.where((e) => e.type == NoteType.note).length;

      _pyqCount = notes.where((e) {
        return e.type == NoteType.pyq;
      }).length;

      _labCount = notes.where((e) {
        return e.type == NoteType.lab;
      }).length;

      _assignmentCount = assignments.length;

      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _recentFiles = notes.take(3).toList();
      
    } catch (e, st) {
      AppLogger.error("SubjectProvider.loadSubjectData", e, st);

      _recentFiles = [];
      _notesCount = 0;
      _assignmentCount = 0;
      _pyqCount = 0;
      _labCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    if (_workspaceId == null) return;

    _subjects = await SubjectRepository.instance.getSubjectsForWorkspace(
      _workspaceId!,
    );

    if (_subjects.isNotEmpty) {
      if (_selectedIndex >= _subjects.length) {
        _selectedIndex = 0;
      }

      await _loadSubjectData(_subjects[_selectedIndex]);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
