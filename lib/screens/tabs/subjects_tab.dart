import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/subject.dart';
import 'package:studyvault/core/utils/icon_helper.dart';
import 'package:studyvault/core/utils/note_type_theme.dart';
import 'package:studyvault/provider/subject_provider.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';
import 'package:studyvault/screens/note_detail_screen.dart';
import 'package:studyvault/screens/subject_material_list_screen.dart';

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

            // if (provider.subjects.isEmpty) {
            //   return Scaffold(
            //     backgroundColor: const Color(0xffF8F9FD),
            //     body: Center(
            //       child: Column(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           Icon(
            //             Icons.menu_book_rounded,
            //             size: 70,
            //             color: Colors.grey.shade400,
            //           ),
            //           const SizedBox(height: 16),
            //           Text(
            //             "No Subjects Found",
            //             style: GoogleFonts.plusJakartaSans(
            //               fontSize: 22,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //           const SizedBox(height: 8),
            //           Text(
            //             "Create your first subject",
            //             style: GoogleFonts.plusJakartaSans(
            //               color: Colors.grey.shade600,
            //             ),
            //           ),
            //           SizedBox(height: 10),
            //           _AddSubjectCard(),
            //         ],
            //       ),
            //     ),
            //   );
            // }

            return Scaffold(
              backgroundColor: const Color(0xffF8F9FD),
              body: Stack(
                children: [
                  SafeArea(
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
                            itemCount: provider.subjects.length + 1,
                            onPageChanged: provider.onPageChanged,
                            itemBuilder: (context, index) {
                              if (index == provider.subjects.length) {
                                return const _AddSubjectCard();
                              }

                              final subject = provider.subjects[index];
                              final selected = index == provider.selectedIndex;

                              return AnimatedScale(
                                scale: selected ? 1 : .90,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: AnimatedOpacity(
                                  opacity: selected ? 1 : .45,
                                  duration: const Duration(milliseconds: 300),
                                  child: LongPressDraggable<Subject>(
                                    data: subject,

                                    dragAnchorStrategy: childDragAnchorStrategy,
                                    feedbackOffset: const Offset(0, -40),

                                    onDragStarted: () {
                                      HapticFeedback.mediumImpact();
                                      provider.startDragging();
                                    },

                                    onDragEnd: (_) {
                                      provider.stopDragging();
                                    },

                                    feedback: Material(
                                      color: Colors.transparent,
                                      elevation: 20,
                                      child: Transform.scale(
                                        scale: .9,
                                        child: SizedBox(
                                          width: 280,
                                          height: 180, // <-- ADD THIS
                                          child: _SubjectCard(
                                            subject: subject,
                                            selected: true,
                                          ),
                                        ),
                                      ),
                                    ),

                                    childWhenDragging: Opacity(
                                      opacity: .25,
                                      child: _SubjectCard(
                                        subject: subject,
                                        selected: selected,
                                      ),
                                    ),

                                    child: _SubjectCard(
                                      subject: subject,
                                      selected: selected,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        SmoothPageIndicator(
                          controller: provider.pageController,
                          count: provider.subjects.length + 1,
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
                          child:
                              provider.selectedIndex == provider.subjects.length
                              ? const SizedBox()
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: SingleChildScrollView(
                                    key: ValueKey(
                                      provider.selectedSubject?.id ?? 0,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          subject: provider.selectedSubject,
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
                                              style:
                                                  GoogleFonts.plusJakartaSans(
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

                  //Delete bar to delete subject---------------------------------
                  Consumer<SubjectProvider>(
                    builder: (_, provider, __) {
                      return IgnorePointer(
                        ignoring: !provider.dragging,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 250),
                          offset: provider.dragging
                              ? Offset.zero
                              : const Offset(0, -1.5),

                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: provider.dragging ? 1 : 0,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(16),

                                child: DragTarget<Subject>(
                                  onWillAcceptWithDetails: (_) {
                                    provider.enterDelete();
                                    return true;
                                  },

                                  onLeave: (_) {
                                    provider.leaveDelete();
                                  },

                                  onAcceptWithDetails: (details) {
                                    provider.stopDragging();

                                    showDeleteDialog(context, details.data.id);
                                  },

                                  builder: (_, __, ___) {
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: provider.overDelete
                                              ? [
                                                  Colors.red.shade700,
                                                  Colors.red.shade500,
                                                  Colors.red.shade300,
                                                  Colors.red.withOpacity(.0),
                                                ]
                                              : [
                                                  Colors.redAccent,
                                                  Colors.redAccent.withOpacity(
                                                    .85,
                                                  ),
                                                  Colors.redAccent.withOpacity(
                                                    .45,
                                                  ),
                                                  Colors.redAccent.withOpacity(
                                                    0,
                                                  ),
                                                ],
                                          stops: const [0.0, 0.35, 0.7, 1.0],
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.delete_rounded,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            "Drop here to delete",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> showDeleteDialog(BuildContext context, Id id) async {
    final provider = context.read<SubjectProvider>();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Subject"),
          content: const Text(
            "This subject and all its notes will be permanently deleted.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),

            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await provider.deleteSubject(id);
    }
  }
}

class _AddSubjectCard extends StatelessWidget {
  const _AddSubjectCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        _showAddSubjectDialog(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.deepPurple.withOpacity(.25),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 40,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Add Subject",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Create a new subject",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSubjectDialog(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add Subject",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: "Subject Name",
                    prefixIcon: const Icon(Icons.menu_book_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final name = controller.text.trim();

                          if (name.isEmpty) return;

                          Navigator.of(context).pop();

                          Future.microtask(() {
                            context.read<SubjectProvider>().addSubject(name);
                          });
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              iconFromCode(subject.icon),
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
                    iconFromCode(subject.icon),
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                Flexible(child: SizedBox()),

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
  final Subject? subject;
  final int notes;
  final int assignments;
  final int pyqs;
  final int labs;

  const _StatsGrid({
    required this.subject,
    required this.notes,
    required this.assignments,
    required this.pyqs,
    required this.labs,
  });

  void _openCategory(
    BuildContext context, {
    required String title,
    NoteType? noteType,
    bool isAssignment = false,
  }) {
    if (subject == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectMaterialListScreen(
          subject: subject!,
          title: title,
          noteType: noteType,
          isAssignment: isAssignment,
        ),
      ),
    );
  }

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
          icon: NoteTypeTheme.icon(NoteType.note),
          title: "Notes",
          value: notes.toString(),
          color: NoteTypeTheme.color(NoteType.note),
          onTap: () =>
              _openCategory(context, title: "Notes", noteType: NoteType.note),
        ),
        _StatCard(
          icon: NoteTypeTheme.assignmentIcon,
          title: "Assignments",
          value: assignments.toString(),
          color: NoteTypeTheme.assignmentColor,
          onTap: () =>
              _openCategory(context, title: "Assignments", isAssignment: true),
        ),
        _StatCard(
          icon: NoteTypeTheme.icon(NoteType.pyq),
          title: "PYQs",
          value: pyqs.toString(),
          color: NoteTypeTheme.color(NoteType.pyq),
          onTap: () =>
              _openCategory(context, title: "PYQs", noteType: NoteType.pyq),
        ),
        _StatCard(
          icon: NoteTypeTheme.icon(NoteType.lab),
          title: "Labs",
          value: labs.toString(),
          color: NoteTypeTheme.color(NoteType.lab),
          onTap: () =>
              _openCategory(context, title: "Labs", noteType: NoteType.lab),
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
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
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
          case NoteType.assignment:
          case NoteType.pyq:
          case NoteType.lab:
            icon = NoteTypeTheme.icon(note.type);
            color = NoteTypeTheme.color(note.type);
            break;
        }

        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteDetailScreen(
                  note: note,
                  subjectName: provider.selectedSubject?.name,
                ),
              ),
            );
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
