import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/provider/search_provider.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final workspaceId = context
        .read<WorkspaceCounterProvider>()
        .selectedWorkspace
        ?.id;

    context.read<SearchProvider>().loadForWorkspace(workspaceId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        final searching = provider.searchController.text.trim().isNotEmpty;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: provider.searchController,
                    onChanged: provider.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search notes, PDFs, PYQs...",
                      prefixIcon: const Icon(Icons.search),

                      suffixIcon: provider.searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                provider.searchController.clear();
                                provider.onSearchChanged("");
                              },
                              icon: const Icon(Icons.close),
                            )
                          : null,

                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: searching
                      ? _SearchResultView()
                      : _SearchSuggestionView(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchSuggestionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ---------------- Recent Searches ----------------
              if (provider.recentSearches.isNotEmpty) ...[
                Row(
                  children: [
                    const Text(
                      "Recent Searches",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: provider.clearRecentSearches,
                      child: const Text("Clear"),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: provider.recentSearches.map((text) {
                    return ActionChip(
                      avatar: const Icon(Icons.history, size: 18),
                      label: Text(text),
                      onPressed: () {
                        provider.searchController.text = text;
                        provider.onSearchChanged(text);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),
              ],

              /// ---------------- Subjects ----------------
              const Text(
                "Subjects",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: provider.suggestions.map((subject) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      provider.searchController.text = subject;
                      provider.onSearchChanged(subject);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            child: Text(subject[0].toUpperCase()),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              /// ---------------- Quick Filters ----------------
              const Text(
                "Quick Filters",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickFilterCard(
                    icon: Icons.menu_book_rounded,
                    title: "Notes",
                    filter: SearchFilter.notes,
                  ),

                  _QuickFilterCard(
                    icon: Icons.assignment_rounded,
                    title: "Assignments",
                    filter: SearchFilter.assignments,
                  ),

                  _QuickFilterCard(
                    icon: Icons.quiz_outlined,
                    title: "PYQs",
                    filter: SearchFilter.pyqs,
                  ),

                  _QuickFilterCard(
                    icon: Icons.science_outlined,
                    title: "Labs",
                    filter: SearchFilter.labs,
                  ),
                ],
              ),

              const SizedBox(height: 40),
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

  const _QuickFilterCard({
    required this.icon,
    required this.title,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (_, provider, __) {
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            provider.changeFilter(filter);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 150,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: provider.selectedFilter == filter
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              children: [
                Icon(icon, size: 32),

                const SizedBox(height: 12),

                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchResultView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        if (provider.isSearching && provider.results.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.results.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 70, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No files found",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Try searching with another keyword.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // ---------------- Filter Chips ----------------
            SizedBox(
              height: 52,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
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

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: provider.results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final note = provider.results[index];
                  final subject = provider.getSubject(note.subjectId);

                  return _SearchResultCard(
                    note: note,
                    subjectName: subject?.name ?? "",
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
      builder: (_, provider, _) {
        final selected = provider.selectedFilter == filter;

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
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
        return Icons.menu_book;

      case NoteType.pdf:
        return Icons.assignment;

      case NoteType.pyq:
        return Icons.quiz;

      case NoteType.lab:
        return Icons.science;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // TODO:
          // open pdf
          // update last opened
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(radius: 28, child: Icon(_icon(), size: 28)),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      subjectName,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          Icons.storage_rounded,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          "${(note.fileSize / 1024).toStringAsFixed(1)} KB",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),

                        const SizedBox(width: 14),

                        Icon(
                          Icons.schedule,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          "${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
