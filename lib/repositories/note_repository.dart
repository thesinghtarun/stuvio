import 'package:isar/isar.dart';
import 'package:studyvault/core/database/isar_service.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/subject.dart';
import 'package:studyvault/core/utils/app_logger.dart';

class NoteRepository {
  NoteRepository._();

  static final NoteRepository instance = NoteRepository._();

  Isar get isar => IsarService.instance.isar;

  // ===========================================================================
  // QUERIES
  // ===========================================================================

  /// Fetch all notes for a subject.
  Future<List<Note>> getNotesForSubject(int subjectId, {NoteType? type}) async {
    final List<Note> list;

    if (type != null) {
      list = await isar.notes
          .filter()
          .subjectIdEqualTo(subjectId)
          .and()
          .typeEqualTo(type)
          .findAll();
    } else {
      list = await isar.notes.filter().subjectIdEqualTo(subjectId).findAll();
    }

    AppLogger.db(
      "NoteRepository.getNotesForSubject",
      "Fetched ${list.length} note(s) [${type?.name ?? "all"}]",
    );

    return list;
  }

  /// Search notes by title or subject name.
  Future<List<Note>> searchNotes({
    required List<int> subjectIds,
    required String query,
    NoteType? type,
    int limit = 50,
    int offset = 0,
  }) async {
    if (subjectIds.isEmpty || query.trim().isEmpty) {
      return [];
    }

    final keyword = query.trim().toLowerCase();

    // 1. Find subject IDs whose name contains keyword
    final matchingSubjectIds = <int>[];
    for (final sId in subjectIds) {
      final subject = await isar.subjects.get(sId);
      if (subject != null && subject.name.toLowerCase().contains(keyword)) {
        matchingSubjectIds.add(sId);
      }
    }

    List<Note> results;

    if (matchingSubjectIds.isNotEmpty) {
      // Notes under matching subjects OR matching title
      final notesBySubject = await isar.notes
          .filter()
          .anyOf(matchingSubjectIds, (q, id) => q.subjectIdEqualTo(id))
          .findAll();

      final notesByTitle = await isar.notes
          .filter()
          .anyOf(subjectIds, (q, id) => q.subjectIdEqualTo(id))
          .and()
          .titleContains(keyword, caseSensitive: false)
          .findAll();

      final Map<int, Note> noteMap = {};
      for (final n in [...notesBySubject, ...notesByTitle]) {
        if (type == null || n.type == type) {
          noteMap[n.id] = n;
        }
      }
      results = noteMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      if (type != null) {
        results = await isar.notes
            .filter()
            .anyOf(subjectIds, (q, id) => q.subjectIdEqualTo(id))
            .and()
            .typeEqualTo(type)
            .and()
            .titleContains(keyword, caseSensitive: false)
            .sortByCreatedAtDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      } else {
        results = await isar.notes
            .filter()
            .anyOf(subjectIds, (q, id) => q.subjectIdEqualTo(id))
            .and()
            .titleContains(keyword, caseSensitive: false)
            .sortByCreatedAtDesc()
            .offset(offset)
            .limit(limit)
            .findAll();
      }
    }

    AppLogger.db(
      "NoteRepository.searchNotes",
      'Search "$keyword" → ${results.length} result(s)',
    );

    return results;
  }

  /// Fetch newest notes for a subject.
  Future<List<Note>> getRecentNotesForSubject(
    int subjectId, {
    int limit = 3,
  }) async {
    final list = await isar.notes
        .filter()
        .subjectIdEqualTo(subjectId)
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();

    AppLogger.db(
      "NoteRepository.getRecentNotesForSubject",
      "Fetched ${list.length} recent note(s)",
    );

    return list;
  }

  /// Count notes.
  Future<int> countNotes(int subjectId, {NoteType? type}) async {
    if (type != null) {
      return await isar.notes
          .filter()
          .subjectIdEqualTo(subjectId)
          .and()
          .typeEqualTo(type)
          .count();
    }

    return await isar.notes.filter().subjectIdEqualTo(subjectId).count();
  }

  /// Fetch favorite notes.
  Future<List<Note>> getFavoriteNotes(int subjectId) async {
    final list = await isar.notes
        .filter()
        .subjectIdEqualTo(subjectId)
        .and()
        .favoriteEqualTo(true)
        .findAll();

    AppLogger.db(
      "NoteRepository.getFavoriteNotes",
      "Fetched ${list.length} favorite note(s)",
    );

    return list;
  }

  /// Get note by ID.
  Future<Note?> getNoteById(int id) async {
    final note = await isar.notes.get(id);

    AppLogger.db(
      "NoteRepository.getNoteById",
      "Found Note ${note?.title ?? "null"}",
    );

    return note;
  }

  // ===========================================================================
  // CRUD
  // ===========================================================================

  /// Create note.
  Future<Note> createNote({
    required int subjectId,
    required String title,
    NoteType type = NoteType.note,
    String? content,
    String filePath = '',
    int fileSize = 0,
    int pages = 0,
    bool favorite = false,
    bool pinned = false,
  }) async {
    final note = Note()
      ..subjectId = subjectId
      ..title = title.trim()
      ..type = type
      ..content = content
      ..filePath = filePath
      ..fileSize = fileSize
      ..pages = pages
      ..favorite = favorite
      ..pinned = pinned
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      note.id = await isar.notes.put(note);
    });

    AppLogger.db(
      "NoteRepository.createNote",
      'Created "${note.title}" (${note.type.name})',
    );

    return note;
  }

  /// Update note.
  Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.notes.put(note);
    });

    AppLogger.db("NoteRepository.updateNote", 'Updated "${note.title}"');
  }

  /// Delete note.
  Future<void> deleteNote(int noteId) async {
    await isar.writeTxn(() async {
      await isar.notes.delete(noteId);
    });

    AppLogger.db("NoteRepository.deleteNote", "Deleted Note ID: $noteId");
  }

  // ===========================================================================
  // FAVORITES / PINS / RECENTLY OPENED
  // ===========================================================================

  /// Toggle favorite status
  Future<void> toggleFavorite(int noteId) async {
    final note = await getNoteById(noteId);

    if (note == null) return;

    note.favorite = !note.favorite;

    await updateNote(note);

    AppLogger.db(
      "NoteRepository.toggleFavorite",
      "Favorite -> ${note.favorite} (${note.title})",
    );
  }

  /// Toggle pin status
  Future<void> togglePin(int noteId) async {
    final note = await getNoteById(noteId);

    if (note == null) return;

    note.pinned = !note.pinned;

    await updateNote(note);

    AppLogger.db(
      "NoteRepository.togglePin",
      "Pinned -> ${note.pinned} (${note.title})",
    );
  }

  /// Update last opened timestamp
  Future<void> updateLastOpened(int noteId) async {
    final note = await getNoteById(noteId);

    if (note == null) return;

    note.lastOpened = DateTime.now();

    await updateNote(note);

    AppLogger.db(
      "NoteRepository.updateLastOpened",
      "Updated last opened (${note.title})",
    );
  }

  // ===========================================================================
  // EXTRA HELPERS
  // ===========================================================================

  /// Get all pinned notes for a subject
  Future<List<Note>> getPinnedNotes(int subjectId) async {
    final list = await isar.notes
        .filter()
        .subjectIdEqualTo(subjectId)
        .and()
        .pinnedEqualTo(true)
        .sortByUpdatedAtDesc()
        .findAll();

    AppLogger.db(
      "NoteRepository.getPinnedNotes",
      "Fetched ${list.length} pinned note(s)",
    );

    return list;
  }

  /// Get recently opened notes
  Future<List<Note>> getRecentlyOpenedNotes({int limit = 10}) async {
    final list = await isar.notes
        .where()
        .sortByLastOpenedDesc()
        .limit(limit)
        .findAll();

    AppLogger.db(
      "NoteRepository.getRecentlyOpenedNotes",
      "Fetched ${list.length} recently opened note(s)",
    );

    return list;
  }

  /// Get largest files
  Future<List<Note>> getLargestFiles({int limit = 20}) async {
    final list = await isar.notes
        .where()
        .sortByFileSizeDesc()
        .limit(limit)
        .findAll();

    AppLogger.db(
      "NoteRepository.getLargestFiles",
      "Fetched ${list.length} largest file(s)",
    );

    return list;
  }

  /// Get favorite notes across all subjects
  Future<List<Note>> getAllFavoriteNotes() async {
    final list = await isar.notes
        .filter()
        .favoriteEqualTo(true)
        .sortByUpdatedAtDesc()
        .findAll();

    AppLogger.db(
      "NoteRepository.getAllFavoriteNotes",
      "Fetched ${list.length} favorite note(s)",
    );

    return list;
  }

  /// Get pinned notes across all subjects
  Future<List<Note>> getAllPinnedNotes() async {
    final list = await isar.notes
        .filter()
        .pinnedEqualTo(true)
        .sortByUpdatedAtDesc()
        .findAll();

    AppLogger.db(
      "NoteRepository.getAllPinnedNotes",
      "Fetched ${list.length} pinned note(s)",
    );

    return list;
  }

  /// Get total notes count
  Future<int> getTotalNotesCount() async {
    return await isar.notes.count();
  }

  /// Get total storage used (bytes)
  Future<int> getTotalStorageUsed() async {
    final notes = await isar.notes.where().findAll();

    int total = 0;

    for (final note in notes) {
      total += note.fileSize;
    }

    return total;
  }

  /// Check if a file already exists by path
  Future<bool> fileExists(String filePath) async {
    final note = await isar.notes
        .filter()
        .filePathEqualTo(filePath)
        .findFirst();

    return note != null;
  }

  /// Get note by file path
  Future<Note?> getNoteByFilePath(String filePath) async {
    return await isar.notes.filter().filePathEqualTo(filePath).findFirst();
  }
}
