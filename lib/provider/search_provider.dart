import 'dart:async';

import 'package:flutter/material.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/subject.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/repositories/note_repository.dart';
import 'package:studyvault/repositories/subject_repository.dart';

enum SearchFilter { all, notes, assignments, pyqs, labs }

class SearchProvider extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;

  int? _workspaceId;

  bool _isSearching = false;

  SearchFilter _selectedFilter = SearchFilter.all;

  List<Subject> _subjects = [];

  final Map<int, Subject> _subjectMap = {};

  List<String> _suggestions = [];

  final List<String> _recentSearches = [];

  List<Note> _results = [];

  List<Note> _allResults = [];

  //================== Getters ==================

  bool get isSearching => _isSearching;

  SearchFilter get selectedFilter => _selectedFilter;

  List<String> get suggestions => _suggestions;

  List<String> get recentSearches => _recentSearches;

  List<Note> get results => _results;

  Subject? getSubject(int id) => _subjectMap[id];

  //================== Workspace ==================

  Future<void> loadForWorkspace(int? workspaceId) async {
    if (_workspaceId == workspaceId) return;

    _workspaceId = workspaceId;

    _results.clear();
    _allResults.clear();
    _suggestions.clear();
    _subjectMap.clear();

    if (workspaceId == null) {
      notifyListeners();
      return;
    }

    try {
      _subjects = await SubjectRepository.instance.getSubjectsForWorkspace(
        workspaceId,
      );

      for (final subject in _subjects) {
        _subjectMap[subject.id] = subject;
      }

      _suggestions = _subjects.map((e) => e.name).toList()..sort();

      AppLogger.info("SearchProvider", "Loaded ${_subjects.length} subjects");
    } catch (e, st) {
      AppLogger.error("SearchProvider.loadForWorkspace", e, st);
    }

    notifyListeners();
  }

  //================== Search ==================

  void onSearchChanged(String text) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      search(text);
    });
  }

  Future<void> search(String query) async {
    query = query.trim();

    if (query.isEmpty) {
      _isSearching = false;
      _results.clear();
      _allResults.clear();
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final ids = _subjects.map((e) => e.id).toList();

      _allResults = await NoteRepository.instance.searchNotes(
        subjectIds: ids,
        query: query,
      );

      _applyFilter();

      AppLogger.info(
        "SearchProvider",
        'Search "$query" -> ${_results.length} results',
      );
    } catch (e, st) {
      AppLogger.error("SearchProvider.search", e, st);

      _results.clear();
      _allResults.clear();
    }

    notifyListeners();
  }

  //================== Filter ==================

  void changeFilter(SearchFilter filter) {
    _selectedFilter = filter;

    _applyFilter();

    notifyListeners();
  }

  void _applyFilter() {
    switch (_selectedFilter) {
      case SearchFilter.all:
        _results = List.from(_allResults);
        break;

      case SearchFilter.notes:
        _results = _allResults.where((e) => e.type == NoteType.note).toList();
        break;

      case SearchFilter.assignments:
        _results = _allResults.where((e) => e.type == NoteType.pdf).toList();
        break;

      case SearchFilter.pyqs:
        _results = _allResults.where((e) => e.type == NoteType.pyq).toList();
        break;

      case SearchFilter.labs:
        _results = _allResults.where((e) => e.type == NoteType.lab).toList();
        break;
    }
  }

  //================== Recent Searches ==================

  void addRecentSearch(String text) {
    text = text.trim();

    if (text.isEmpty) return;

    _recentSearches.remove(text);

    _recentSearches.insert(0, text);

    if (_recentSearches.length > 8) {
      _recentSearches.removeLast();
    }

    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();

    notifyListeners();
  }

  //================== Dispose ==================

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
