import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/subject.dart';
import 'package:studyvault/provider/subject_provider.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';

class SubjectsTab extends StatelessWidget {
  const SubjectsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceCounterProvider>(
      builder: (context, workspaceProvider, child) {
        final workspaceId = workspaceProvider.selectedWorkspace?.id;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<SubjectProvider>().loadForWorkspace(workspaceId);
        });

        return Consumer<SubjectProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.subjects.isEmpty) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (provider.subjects.isEmpty) {
              return Scaffold(
                backgroundColor: const Color(0xffF8F9FD),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 70,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No Subjects Found",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Create your first subject",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Scaffold(
              backgroundColor: const Color(0xffF8F9FD),
              body: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    //-----------------------------------------
                    // TITLE
                    //-----------------------------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            "Subjects",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    //-----------------------------------------
                    // PAGE VIEW
                    //-----------------------------------------
                    SizedBox(
                      height: 180,
                      child: PageView.builder(
                        controller: provider.pageController,
                        itemCount: provider.subjects.length,
                        onPageChanged: provider.onPageChanged,
                        itemBuilder: (context, index) {
                          final subject = provider.subjects[index];

                          final selected = index == provider.selectedIndex;

                          return AnimatedScale(
                            scale: selected ? 1 : .90,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            child: AnimatedOpacity(
                              opacity: selected ? 1 : .45,
                              duration: const Duration(milliseconds: 300),
                              child: _SubjectCard(
                                subject: subject,
                                selected: selected,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    SmoothPageIndicator(
                      controller: provider.pageController,
                      count: provider.subjects.length,
                      effect: ExpandingDotsEffect(
                        expansionFactor: 3,
                        spacing: 8,
                        radius: 20,
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: Colors.deepPurple,
                        dotColor: Colors.grey.shade300,
                      ),
                    ),

                    const SizedBox(height: 25),

                    //-----------------------------------------
                    // EVERYTHING BELOW ANIMATES
                    //-----------------------------------------
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: SingleChildScrollView(
                          key: ValueKey(provider.selectedSubject?.id ?? 0),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.selectedSubject?.name ?? "",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Everything related to this subject",
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.grey.shade600,
                                ),
                              ),

                              const SizedBox(height: 24),

                              //-----------------------------------------
                              // STATS GRID
                              //-----------------------------------------
                              _StatsGrid(
                                notes: provider.notesCount,
                                assignments: provider.assignmentCount,
                                pyqs: provider.pyqCount,
                                labs: provider.labCount,
                              ),

                              const SizedBox(height: 30),

                              Row(
                                children: [
                                  Text(
                                    "Recently Added",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              //-----------------------------------------
                              // RECENT FILES
                              //-----------------------------------------
                              _RecentFilesSection(provider: provider),

                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
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

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final bool selected;

  const _SubjectCard({required this.subject, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = Color(subject.color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.25),
            blurRadius: selected ? 24 : 12,
            spreadRadius: selected ? 2 : 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white.withOpacity(.08),
            ),
          ),

          Positioned(
            right: 20,
            bottom: 20,
            child: Icon(
              IconData(subject.icon, fontFamily: 'MaterialIcons'),
              color: Colors.white.withOpacity(.15),
              size: 80,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    IconData(subject.icon, fontFamily: 'MaterialIcons'),
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const Spacer(),

                Text(
                  subject.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Study smarter • Stay organized",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int notes;
  final int assignments;
  final int pyqs;
  final int labs;

  const _StatsGrid({
    required this.notes,
    required this.assignments,
    required this.pyqs,
    required this.labs,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      childAspectRatio: 1.6,

      crossAxisSpacing: 14,

      mainAxisSpacing: 14,

      children: [
        _StatCard(
          icon: Icons.menu_book_rounded,
          title: "Notes",
          value: notes.toString(),
          color: Colors.deepPurple,
        ),

        _StatCard(
          icon: Icons.assignment_rounded,
          title: "Assignments",
          value: assignments.toString(),
          color: Colors.orange,
        ),

        _StatCard(
          icon: Icons.quiz_rounded,
          title: "PYQs",
          value: pyqs.toString(),
          color: Colors.blue,
        ),

        _StatCard(
          icon: Icons.science_rounded,
          title: "Labs",
          value: labs.toString(),
          color: Colors.green,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 52,

            height: 52,

            decoration: BoxDecoration(
              color: color.withOpacity(.12),

              borderRadius: BorderRadius.circular(16),
            ),

            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  value,

                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  title,

                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,

                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentFilesSection extends StatelessWidget {
  final SubjectProvider provider;

  const _RecentFilesSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.recentFiles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              "No Files Yet",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Upload notes, PDFs, PYQs or lab manuals.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.recentFiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final note = provider.recentFiles[index];

        IconData icon;
        Color color;

        switch (note.type) {
          case NoteType.note:
            icon = Icons.menu_book_rounded;
            color = Colors.deepPurple;
            break;

          case NoteType.pdf:
            icon = Icons.picture_as_pdf_rounded;
            color = Colors.red;
            break;

          case NoteType.pyq:
            icon = Icons.quiz_rounded;
            color = Colors.blue;
            break;

          case NoteType.lab:
            icon = Icons.science_rounded;
            color = Colors.green;
            break;
        }

        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            // TODO
            // Open file
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                //----------------------------------
                // FILE ICON
                //----------------------------------
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),

                const SizedBox(width: 16),

                //----------------------------------
                // TITLE
                //----------------------------------
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
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _timeAgo(note.createdAt),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                //----------------------------------
                // FAVORITE
                //----------------------------------
                if (note.favorite)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.star_rounded, color: Colors.amber),
                  ),

                //----------------------------------
                // PINNED
                //----------------------------------
                if (note.pinned)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.push_pin_rounded,
                      color: Colors.deepPurple,
                    ),
                  ),

                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
              ],
            ),
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) {
      return "Just now";
    }

    if (difference.inHours < 1) {
      return "${difference.inMinutes} min ago";
    }

    if (difference.inDays < 1) {
      return "${difference.inHours} hr ago";
    }

    if (difference.inDays == 1) {
      return "Yesterday";
    }

    if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    }

    return "${date.day}/${date.month}/${date.year}";
  }
}
