import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/core/utils/note_type_theme.dart';
import 'package:studyvault/provider/search_provider.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';
import 'package:studyvault/repositories/note_repository.dart';
import 'package:studyvault/screens/assignment_detail_screen.dart';
import 'package:studyvault/screens/note_detail_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  int? _lastWorkspaceId;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SearchProvider>().loadBannerAd();
    });
    super.initState();
  }

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
                child: Stack(
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 20),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              "Search",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search Input Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
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
                                        provider.selectedFilter !=
                                            SearchFilter.all
                                    ? IconButton(
                                        onPressed: () {
                                          AppLogger.click(
                                            'SearchTab',
                                            'Cleared search query and filters',
                                          );
                                          provider.searchController.clear();
                                          provider.changeFilter(
                                            SearchFilter.all,
                                          );
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
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Consumer<SearchProvider>(
                        builder: (context, provider, child) {
                          if (provider.bannerAd == null) {
                            return const SizedBox.shrink();
                          }

                          return SizedBox(
                            width: provider.bannerAd!.size.width.toDouble(),
                            height: provider.bannerAd!.size.height.toDouble(),
                            child: AdWidget(ad: provider.bannerAd!),
                          );
                        },
                      ),
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
                children: [
                  _QuickFilterCard(
                    icon: NoteTypeTheme.icon(NoteType.note),
                    title: "Notes",
                    filter: SearchFilter.notes,
                    color: NoteTypeTheme.color(NoteType.note),
                  ),
                  _QuickFilterCard(
                    icon: NoteTypeTheme.assignmentIcon,
                    title: "Assignments",
                    filter: SearchFilter.assignments,
                    color: NoteTypeTheme.assignmentColor,
                  ),
                  _QuickFilterCard(
                    icon: NoteTypeTheme.icon(NoteType.pyq),
                    title: "PYQs",
                    filter: SearchFilter.pyqs,
                    color: NoteTypeTheme.color(NoteType.pyq),
                  ),
                  _QuickFilterCard(
                    icon: NoteTypeTheme.icon(NoteType.lab),
                    title: "Labs",
                    filter: SearchFilter.labs,
                    color: NoteTypeTheme.color(NoteType.lab),
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
                  Image.asset("assets/images/no_search.png", height: 200),
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
                  final item = provider.results[index];
                  final subject = provider.getSubject(item.subjectId);

                  return _SearchResultCard(
                    item: item,
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
  final SearchResultItem item;
  final String subjectName;

  const _SearchResultCard({required this.item, required this.subjectName});

  IconData _icon() {
    if (item.isAssignment) return NoteTypeTheme.assignmentIcon;
    return NoteTypeTheme.icon(item.note!.type);
  }

  Color _iconColor() {
    if (item.isAssignment) return NoteTypeTheme.assignmentColor;
    return NoteTypeTheme.color(item.note!.type);
  }

  Future<void> _handleTap(BuildContext context) async {
    if (item.isAssignment) {
      AppLogger.click(
        'SearchTab.SearchResultCard',
        'Tapped assignment search result ID=${item.assignment!.id}: "${item.assignment!.title}"',
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssignmentDetailScreen(assignment: item.assignment!),
        ),
      );
    } else if (item.isNote) {
      final note = item.note!;
      AppLogger.click(
        'SearchTab.SearchResultCard',
        'Tapped note search result ID=${note.id}: "${note.title}"',
      );
      await NoteRepository.instance.updateLastOpened(note.id);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                NoteDetailScreen(note: note, subjectName: subjectName),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String subtitle;
    final String extraMeta;

    if (item.isAssignment) {
      final a = item.assignment!;
      subtitle = "$subjectName • Assignment";
      extraMeta =
          "Due: ${a.dueDate.day.toString().padLeft(2, '0')}/${a.dueDate.month.toString().padLeft(2, '0')}/${a.dueDate.year}";
    } else {
      final n = item.note!;
      final formattedSize = n.fileSize > 0
          ? "${(n.fileSize / 1024).toStringAsFixed(1)} KB"
          : "Text Note";
      subtitle = "$subjectName • ${NoteTypeTheme.label(n.type)}";
      extraMeta = formattedSize;
    }

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
        onTap: () => _handleTap(context),
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
                      item.title,
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
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          item.isAssignment
                              ? Icons.event_rounded
                              : Icons.storage_rounded,
                          size: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          extraMeta,
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
                          "${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}",
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
