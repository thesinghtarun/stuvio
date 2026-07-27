import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/provider/search_provider.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';
import 'package:studyvault/repositories/note_repository.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  int? _lastWorkspaceId;

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceCounterProvider>(
      builder: (context, workspaceProvider, child) {
        final workspaceId = workspaceProvider.selectedWorkspace?.id;

        if (_lastWorkspaceId != workspaceId) {
          _lastWorkspaceId = workspaceId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<SearchProvider>().loadForWorkspace(workspaceId);
          });
        }

        return Consumer<SearchProvider>(
          builder: (context, provider, child) {
            final isSearchingMode =
                provider.searchController.text.trim().isNotEmpty ||
                provider.selectedFilter != SearchFilter.all;

            return Scaffold(
              backgroundColor: const Color(0xFFF9FAFB),
              body: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Search Input Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: provider.searchController,
                          onChanged: provider.onSearchChanged,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: "Search notes, PDFs, PYQs...",
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF6750A4),
                            ),
                            suffixIcon:
                                provider.searchController.text.isNotEmpty ||
                                    provider.selectedFilter != SearchFilter.all
                                ? IconButton(
                                    onPressed: () {
                                      AppLogger.click(
                                        'SearchTab',
                                        'Cleared search query and filters',
                                      );
                                      provider.searchController.clear();
                                      provider.changeFilter(SearchFilter.all);
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFF6B7280),
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Main View Body
                    Expanded(
                      child: isSearchingMode
                          ? const _SearchResultView()
                          : const _SearchSuggestionView(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Search Suggestions View ──────────────────────────────────────────────────

class _SearchSuggestionView extends StatelessWidget {
  const _SearchSuggestionView();

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Searches
              if (provider.recentSearches.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Searches",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    TextButton(
                      onPressed: provider.clearRecentSearches,
                      child: Text(
                        "Clear",
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.recentSearches.map((text) {
                    return ActionChip(
                      elevation: 0,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      avatar: const Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: Color(0xFF6750A4),
                      ),
                      label: Text(
                        text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      onPressed: () {
                        AppLogger.click(
                          'SearchTab.RecentSearch',
                          'Selected "$text"',
                        );
                        provider.searchController.text = text;
                        provider.search(text);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Subjects Suggestions
              if (provider.suggestions.isNotEmpty) ...[
                Text(
                  "Subjects",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: provider.suggestions.map((subject) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        AppLogger.click(
                          'SearchTab.SubjectSuggestion',
                          'Selected "$subject"',
                        );
                        provider.searchController.text = subject;
                        provider.search(subject);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: const Color(
                                0xFF6750A4,
                              ).withValues(alpha: 0.1),
                              child: Text(
                                subject[0].toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6750A4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              subject,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Quick Filters
              Text(
                "Quick Filters",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: const [
                  _QuickFilterCard(
                    icon: Icons.menu_book_rounded,
                    title: "Notes",
                    filter: SearchFilter.notes,
                    color: Color(0xFF3B82F6),
                  ),
                  _QuickFilterCard(
                    icon: Icons.assignment_rounded,
                    title: "Assignments",
                    filter: SearchFilter.assignments,
                    color: Color(0xFF10B981),
                  ),
                  _QuickFilterCard(
                    icon: Icons.quiz_rounded,
                    title: "PYQs",
                    filter: SearchFilter.pyqs,
                    color: Color(0xFFF59E0B),
                  ),
                  _QuickFilterCard(
                    icon: Icons.science_rounded,
                    title: "Labs",
                    filter: SearchFilter.labs,
                    color: Color(0xFF8B5CF6),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _QuickFilterCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final SearchFilter filter;
  final Color color;

  const _QuickFilterCard({
    required this.icon,
    required this.title,
    required this.filter,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.selectedFilter == filter;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            provider.changeFilter(filter);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE5E7EB),
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                    color: isSelected ? color : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Search Results View ──────────────────────────────────────────────────────

class _SearchResultView extends StatelessWidget {
  const _SearchResultView();

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        if (provider.isSearching) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6750A4)),
          );
        }

        if (provider.results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No files found",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Try searching with another keyword or clearing category filters.",
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Filter Chips Bar
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: const [
                  _FilterChipWidget(label: "All", filter: SearchFilter.all),
                  _FilterChipWidget(label: "Notes", filter: SearchFilter.notes),
                  _FilterChipWidget(
                    label: "Assignments",
                    filter: SearchFilter.assignments,
                  ),
                  _FilterChipWidget(label: "PYQs", filter: SearchFilter.pyqs),
                  _FilterChipWidget(label: "Labs", filter: SearchFilter.labs),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Results List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: provider.results.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final note = provider.results[index];
                  final subject = provider.getSubject(note.subjectId);

                  return _SearchResultCard(
                    note: note,
                    subjectName: subject?.name ?? "Subject",
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChipWidget extends StatelessWidget {
  final String label;
  final SearchFilter filter;

  const _FilterChipWidget({required this.label, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        final selected = provider.selectedFilter == filter;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF374151),
              ),
            ),
            selected: selected,
            selectedColor: const Color(0xFF6750A4),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? const Color(0xFF6750A4)
                  : const Color(0xFFE5E7EB),
            ),
            onSelected: (_) {
              provider.changeFilter(filter);
            },
          ),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Note note;
  final String subjectName;

  const _SearchResultCard({required this.note, required this.subjectName});

  IconData _icon() {
    switch (note.type) {
      case NoteType.note:
        return Icons.menu_book_rounded;
      case NoteType.pdf:
        return Icons.picture_as_pdf_rounded;
      case NoteType.pyq:
        return Icons.quiz_rounded;
      case NoteType.lab:
        return Icons.science_rounded;
    }
  }

  Color _iconColor() {
    switch (note.type) {
      case NoteType.note:
        return const Color(0xFF3B82F6);
      case NoteType.pdf:
        return const Color(0xFFEF4444);
      case NoteType.pyq:
        return const Color(0xFFF59E0B);
      case NoteType.lab:
        return const Color(0xFF8B5CF6);
    }
  }

  Future<void> _handleNoteTap(BuildContext context) async {
    AppLogger.click(
      'SearchTab.SearchResultCard',
      'Tapped search result note ID=${note.id}: "${note.title}"',
    );

    // Update last opened in database
    await NoteRepository.instance.updateLastOpened(note.id);

    // If there is a file path, try to open it via the native viewer
    if (note.filePath.isNotEmpty) {
      final file = File(note.filePath);
      print("FileOPEN: $file");
      print("Exists: ${await file.exists()}");
      print("Length: ${await file.length()}");
      if (await file.exists()) {
        const platform = MethodChannel('com.singhtarun.stuvio/open_file');
        try {
          final result = await platform.invokeMethod('openFile', {
            'filePath': note.filePath,
          });
          AppLogger.action(
            'OPEN_FILE',
            'openFile result: $result for ${note.filePath}',
          );
          return;
        } catch (e, st) {
          AppLogger.error('SearchTab.openFile', e, st);
          Fluttertoast.showToast(msg: 'Could not open file: $e');
          return;
        }
      } else {
        AppLogger.info('SearchTab', 'File not found on disk: ${note.filePath}');
        Fluttertoast.showToast(msg: 'File not found on device');
        return;
      }
    }

    // No file path — show note details sheet (text notes)
    if (context.mounted) {
      _showNoteDetailsSheet(context);
    }
  }

  void _showNoteDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _iconColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon(), color: _iconColor(), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          subjectName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (note.content != null && note.content!.isNotEmpty) ...[
                Text(
                  "Note Content:",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    note.content!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                "Created: ${note.createdAt.day.toString().padLeft(2, '0')}/${note.createdAt.month.toString().padLeft(2, '0')}/${note.createdAt.year}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedSize = note.fileSize > 0
        ? "${(note.fileSize / 1024).toStringAsFixed(1)} KB"
        : "Text Note";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleNoteTap(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _iconColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon(), size: 22, color: _iconColor()),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subjectName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.storage_rounded,
                          size: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedSize,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${note.createdAt.day.toString().padLeft(2, '0')}/${note.createdAt.month.toString().padLeft(2, '0')}/${note.createdAt.year}",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
