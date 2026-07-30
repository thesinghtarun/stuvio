import 'dart:async';
import 'package:flutter/material.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/subject.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/repositories/assignment_repository.dart';
import 'package:studyvault/repositories/note_repository.dart';
import 'package:studyvault/repositories/subject_repository.dart';

enum SearchFilter { all, notes, assignments, pyqs, labs }

class SearchResultItem {
  final Note? note;
  final Assignment? assignment;

  SearchResultItem.fromNote(this.note) : assignment = null;
  SearchResultItem.fromAssignment(this.assignment) : note = null;

  bool get isAssignment => assignment != null;
  bool get isNote => note != null;

  int get subjectId => note?.subjectId ?? assignment!.subjectId;
  String get title => note?.title ?? assignment!.title;
  DateTime get date => note?.createdAt ?? assignment!.createdAt;
}

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

  List<SearchResultItem> _results = [];
  List<SearchResultItem> _allResults = [];

  //================== Getters ==================

  bool get isSearching => _isSearching;
  SearchFilter get selectedFilter => _selectedFilter;
  List<String> get suggestions => _suggestions;
  List<String> get recentSearches => _recentSearches;
  List<SearchResultItem> get results => _results;

  Subject? getSubject(int id) => _subjectMap[id];

  //================== Workspace ==================

  Future<void> loadForWorkspace(int? workspaceId) async {
    if (_workspaceId == workspaceId && _subjects.isNotEmpty) return;

    _workspaceId = workspaceId;
    _results.clear();
    _allResults.clear();
    _suggestions.clear();
    _subjectMap.clear();

    if (workspaceId == null) {
      AppLogger.info(
        'SearchProvider',
        'Workspace ID is null. Cleared search context.',
      );
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
      AppLogger.info(
        'SearchProvider',
        'Loaded ${_subjects.length} subject(s) for workspaceId=$workspaceId',
      );

      // If filter is active or search query present, refresh search
      if (searchController.text.trim().isNotEmpty ||
          _selectedFilter != SearchFilter.all) {
        await search(searchController.text);
      }
    } catch (e, st) {
      AppLogger.error('SearchProvider.loadForWorkspace', e, st);
    }

    notifyListeners();
  }

  //================== Search ==================

  void onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      search(text);
    });
  }

  Future<void> search(String query) async {
    final trimmedQuery = query.trim();

    // If query is empty and filter is 'all', return to home suggestion state
    if (trimmedQuery.isEmpty && _selectedFilter == SearchFilter.all) {
      _isSearching = false;
      _results.clear();
      _allResults.clear();
      AppLogger.info(
        'SearchProvider',
        'Search cleared. Returned to suggestions.',
      );
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final ids = _subjects.map((e) => e.id).toList();

      if (ids.isEmpty) {
        _allResults = [];
        _results = [];
        _isSearching = false;
        notifyListeners();
        return;
      }

      final List<SearchResultItem> items = [];

      if (trimmedQuery.isNotEmpty) {
        addRecentSearch(trimmedQuery);
        AppLogger.action(
          'SEARCH',
          'Searching for "$trimmedQuery" across ${ids.length} subjects',
        );

        final notes = await NoteRepository.instance.searchNotes(
          subjectIds: ids,
          query: trimmedQuery,
        );
        for (final n in notes) {
          items.add(SearchResultItem.fromNote(n));
        }

        final assignments = await AssignmentRepository.instance
            .searchAssignments(subjectIds: ids, query: trimmedQuery);
        for (final a in assignments) {
          items.add(SearchResultItem.fromAssignment(a));
        }
      } else {
        // Query empty but category filter selected: load all items for workspace subjects
        AppLogger.action(
          'SearchProvider',
          'Loading all items for filter: ${_selectedFilter.name}',
        );
        for (final id in ids) {
          final notes = await NoteRepository.instance.getNotesForSubject(id);
          for (final n in notes) {
            items.add(SearchResultItem.fromNote(n));
          }
          final assignments = await AssignmentRepository.instance
              .getAssignmentsForSubject(id);
          for (final a in assignments) {
            items.add(SearchResultItem.fromAssignment(a));
          }
        }
      }

      items.sort((a, b) => b.date.compareTo(a.date));
      _allResults = items;

      _applyFilter();

      AppLogger.info(
        'SearchProvider',
        'Search completed -> Query: "$trimmedQuery" | Filter: ${_selectedFilter.name} | Results: ${_results.length}',
      );
    } catch (e, st) {
      AppLogger.error('SearchProvider.search', e, st);
      _results.clear();
      _allResults.clear();
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  //================== Filter ==================

  void changeFilter(SearchFilter filter) {
    if (_selectedFilter == filter && searchController.text.trim().isEmpty) {
      // Toggle off filter if clicked again when empty
      _selectedFilter = SearchFilter.all;
    } else {
      _selectedFilter = filter;
    }

    AppLogger.click(
      'SearchProvider.changeFilter',
      'Selected filter: ${_selectedFilter.name}',
    );

    // Perform search / refresh list for new filter
    search(searchController.text);
  }

  void _applyFilter() {
    switch (_selectedFilter) {
      case SearchFilter.all:
        _results = List.from(_allResults);
        break;
      case SearchFilter.notes:
        _results = _allResults
            .where((e) => e.isNote && e.note!.type == NoteType.note)
            .toList();
        break;
      case SearchFilter.assignments:
        _results = _allResults
            .where(
              (e) =>
                  e.isAssignment ||
                  (e.isNote && e.note!.type == NoteType.assignment),
            )
            .toList();
        break;
      case SearchFilter.pyqs:
        _results = _allResults
            .where((e) => e.isNote && e.note!.type == NoteType.pyq)
            .toList();
        break;
      case SearchFilter.labs:
        _results = _allResults
            .where((e) => e.isNote && e.note!.type == NoteType.lab)
            .toList();
        break;
    }
  }

  //================== Recent Searches ==================

  void addRecentSearch(String text) {
    final sanitized = text.trim();
    if (sanitized.isEmpty) return;

    _recentSearches.remove(sanitized);
    _recentSearches.insert(0, sanitized);

    if (_recentSearches.length > 8) {
      _recentSearches.removeLast();
    }
  }

  void clearRecentSearches() {
    AppLogger.click('SearchProvider', 'Cleared recent search history');
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
