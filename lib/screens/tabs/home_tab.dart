import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/workspace.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/provider/home_provider.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';
import 'package:studyvault/screens/assignment_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger HomeProvider load when workspace changes
    return Consumer<WorkspaceCounterProvider>(
      builder: (context, workspaceProvider, child) {
        final workspaceId = workspaceProvider.selectedWorkspace?.id;

        // Load home data whenever workspaceId changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<HomeProvider>().loadForWorkspace(workspaceId);
        });

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    _getGreeting(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // User Name
                  Text(
                    "${workspaceProvider.userName} 👋🏻",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Workspace Dropdown
                  _WorkspaceDropdown(provider: workspaceProvider),

                  const SizedBox(height: 24),

                  // Deadlines Section
                  const _DeadlinesSection(),

                  // Upcoming Section
                  const _UpcomingSection(),

                  const SizedBox(height: 24),

                  // Notes Section
                  const _NotesSection(),

                  // Empty State — shown only when all sections are empty
                  const _EmptyHomeState(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }
}

// ─── Workspace Dropdown ───────────────────────────────────────────────────────

class _WorkspaceDropdown extends StatelessWidget {
  final WorkspaceCounterProvider provider;
  const _WorkspaceDropdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    final workspaces = provider.workspaces;
    final selectedWorkspace = provider.selectedWorkspace;

    if (workspaces.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.work_outline, color: Color(0xFF9CA3AF), size: 20),
            const SizedBox(width: 10),
            Text(
              'No workspace created',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Workspace>(
          value: selectedWorkspace,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6750A4),
            size: 24,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          items: workspaces.map((w) {
            return DropdownMenuItem<Workspace>(
              value: w,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6750A4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      IconData(w.icon, fontFamily: 'MaterialIcons'),
                      color: const Color(0xFF6750A4),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          w.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Workspace',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (Workspace? newWorkspace) {
            if (newWorkspace != null) {
              AppLogger.click(
                'HomeScreen.WorkspaceDropdown',
                'Selected workspace: ${newWorkspace.name}',
              );
              provider.selectWorkspace(newWorkspace);
            }
          },
        ),
      ),
    );
  }
}

// ─── Deadlines Section ────────────────────────────────────────────────────────

class _DeadlinesSection extends StatelessWidget {
  const _DeadlinesSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, home, child) {
        if (home.isLoadingDeadlines || home.deadlines.isEmpty) {
          return const SizedBox.shrink();
        }

        final hasMultiple = home.deadlines.length > 1;
        final displayed = home.isDeadlinesExpanded
            ? home.deadlines
            : [home.deadlines.first];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deadlines',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (hasMultiple)
                  IconButton(
                    onPressed: () =>
                        context.read<HomeProvider>().toggleDeadlinesExpanded(),
                    icon: Icon(
                      home.isDeadlinesExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: const Color(0xFF111827),
                      size: 26,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayed.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final assignment = displayed[idx];
                return _DeadlineCard(
                  assignment: assignment,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AssignmentDetailScreen(assignment: assignment),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;

  const _DeadlineCard({required this.assignment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: "Due Tomorrow" label + icon badge
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Due Tomorrow',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE4E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_outlined,
                      color: Color(0xFFF43F5E),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom: clickable title + date
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(19),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(19),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Due: ${HomeProvider.formatDate(assignment.dueDate)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming Section ─────────────────────────────────────────────────────────

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, home, child) {
        if (home.isLoadingUpcoming || home.upcoming.isEmpty) {
          return const SizedBox.shrink();
        }

        final hasMultiple = home.upcoming.length > 1;
        final displayed = home.isUpcomingExpanded
            ? home.upcoming
            : [home.upcoming.first];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (hasMultiple)
                  IconButton(
                    onPressed: () =>
                        context.read<HomeProvider>().toggleUpcomingExpanded(),
                    icon: Icon(
                      home.isUpcomingExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: const Color(0xFF111827),
                      size: 26,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayed.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final assignment = displayed[idx];
                return _UpcomingCard(
                  assignment: assignment,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AssignmentDetailScreen(assignment: assignment),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;

  const _UpcomingCard({required this.assignment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = HomeProvider.daysLeftLabel(assignment.dueDate);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EFFE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notes Section ─────────────────────────────────────────────────────────────

class _NotesSection extends StatelessWidget {
  const _NotesSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, home, child) {
        if (home.isLoadingNotes || home.notes.isEmpty) {
          return const SizedBox.shrink();
        }

        final hasMultiple = home.notes.length > 1;
        final displayed = home.isNotesExpanded
            ? home.notes
            : [home.notes.first];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (hasMultiple)
                  IconButton(
                    onPressed: () =>
                        context.read<HomeProvider>().toggleNotesExpanded(),
                    icon: Icon(
                      home.isNotesExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: const Color(0xFF111827),
                      size: 26,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayed.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final note = displayed[idx];
                return _NoteCard(
                  note: note,
                  onTap: () async {
                    if (note.filePath.isNotEmpty) {
                      const platform = MethodChannel(
                        'com.singhtarun.stuvio/open_file',
                      );
                      try {
                        await platform.invokeMethod('openFile', {
                          'filePath': note.filePath,
                        });
                      } catch (e) {
                        Fluttertoast.showToast(msg: 'Could not open file: $e');
                      }
                    } else {
                      Fluttertoast.showToast(msg: 'Note file is not available');
                    }
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6750A4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFF6750A4),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note.type == NoteType.pdf ? 'PDF Document' : 'Note',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
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
    );
  }
}

// ─── Empty Home State ─────────────────────────────────────────────────────────

class _EmptyHomeState extends StatelessWidget {
  const _EmptyHomeState();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, home, child) {
        final isLoading =
            home.isLoadingDeadlines ||
            home.isLoadingUpcoming ||
            home.isLoadingNotes;

        final isEmpty =
            home.deadlines.isEmpty &&
            home.upcoming.isEmpty &&
            home.notes.isEmpty;

        if (isLoading || !isEmpty) return const SizedBox.shrink();

        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/no_data.png',
                  height: 300,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  "Nothing here yet!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add assignments or notes to your subjects\nand they'll show up right here.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                    height: 1.6,
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
