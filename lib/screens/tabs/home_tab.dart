import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/workspace.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/core/utils/icon_helper.dart';
import 'package:studyvault/core/utils/note_type_theme.dart';
import 'package:studyvault/provider/home_provider.dart';
import 'package:studyvault/provider/inbox_provider.dart';
import 'package:studyvault/provider/inner_banner_provider.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';
import 'package:studyvault/repositories/subject_repository.dart';
import 'package:studyvault/screens/assignment_detail_screen.dart';
import 'package:studyvault/screens/inbox_screen.dart';
import 'package:studyvault/screens/note_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.read<HomeProvider>().loadBannerAd();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Trigger HomeProvider load when workspace changes
    final homeProvider = context.watch<HomeProvider>();
    return Consumer<WorkspaceCounterProvider>(
      builder: (context, workspaceProvider, child) {
        final workspaceId = workspaceProvider.selectedWorkspace?.id;

        // Load home data whenever workspaceId changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<HomeProvider>().loadForWorkspace(workspaceId);

          //To check if inbox is empty
          final inbox = context.read<InboxProvider>();
          context.read<HomeProvider>().showInboxPopupOnce(
            inbox.items.isNotEmpty,
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final inbox = context.read<InboxProvider>();

          inbox.onInboxLoaded = () {
            context.read<HomeProvider>().showInboxPopupOnce(
              inbox.items.isNotEmpty,
            );
          };
        });
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: SafeArea(
            child: Stack(
              children: [
                IgnorePointer(
                  ignoring: homeProvider.showInboxImg,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting & Inbox Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  HomeTab._getGreeting(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${workspaceProvider.userName} 👋🏻",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                            Consumer<InboxProvider>(
                              builder: (context, inboxProvider, _) {
                                final count = inboxProvider.count;
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const InboxScreen(),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.inbox_rounded,
                                          color: Color(0xFF5C35E8),
                                          size: 24,
                                        ),
                                      ),
                                      Positioned(
                                        right: -4,
                                        top: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: count > 0
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFF9CA3AF),
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 20,
                                            minHeight: 20,
                                          ),
                                          child: Text(
                                            '$count',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Workspace Dropdown
                        _WorkspaceDropdown(provider: workspaceProvider),

                        const SizedBox(height: 24),

                        // Deadlines Section
                        const _DeadlinesSection(),

                        // Upcoming Section
                        const _UpcomingSection(),

                        // Notes Section
                        const _NotesSection(),

                        //PYQs Section
                        // const _PYQsSection(),

                        // Empty State — shown only when all sections are empty
                        const _EmptyHomeState(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                if (homeProvider.showInboxImg)
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          opacity: homeProvider.showInboxImg ? 1 : 0,
                          child: Container(
                            color: Colors.black.withOpacity(.35),
                          ),
                        ),
                      ),
                    ),
                  ),
                InboxContainer(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Consumer<HomeProvider>(
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
  }
}

class InboxContainer extends StatefulWidget {
  const InboxContainer({super.key});

  @override
  State<InboxContainer> createState() => _InboxContainerState();
}

class _InboxContainerState extends State<InboxContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scale = Tween<double>(
      begin: 0.15,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slide = Tween<Offset>(
      begin: Offset(.65, -.9),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        if (!provider.showInboxImg) {
          return const SizedBox.shrink();
        }
        if (provider.showInboxImg) {
          _controller.forward();
        } else {
          _controller.reverse();
        }

        return FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () async {
                                await _controller.reverse();
                                provider.hideInboxPopup();
                              },
                              icon: const Icon(Icons.arrow_back_ios),
                            ),
                          ),
                          Center(
                            child: Image.asset(
                              "assets/images/wave.png",
                              width: 200,
                              height: 200,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Some files need your attention",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Click the button to organize your learnings",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                          SizedBox(height: 20),
                          Consumer<HomeProvider>(
                            builder: (context, provider, child) {
                              return SizedBox(
                                height: 50,
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5C35E8),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    provider.hideInboxPopup();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => InboxScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Open Inbox",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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
                      iconFromCode(w.icon),
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

            Consumer<InlineBannerProvider>(
              builder: (context, inLineBannerProvider, child) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: inLineBannerProvider.getItemCount(
                    displayed.length,
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    if (inLineBannerProvider.isAdIndex(idx)) {
                      return const _DeadlineAdCard();
                    }
                    final realIdx = inLineBannerProvider.getRealIndex(idx);
                    if (realIdx < 0 || realIdx >= displayed.length) {
                      return const SizedBox.shrink();
                    }
                    final assignment = displayed[realIdx];
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
    final label = HomeProvider.daysLeftLabel(assignment.dueDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Top row: Dynamic due label + shield icon badge
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
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

            // Bottom: title + date (styled section)
            Container(
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
          ],
        ),
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
                  'Upcoming Assignments',
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

            Consumer<InlineBannerProvider>(
              builder: (context, inLineBannerProvider, child) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: inLineBannerProvider.getItemCount(
                    displayed.length,
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    if (inLineBannerProvider.isAdIndex(idx)) {
                      return const _UpcomingAdCard();
                    }
                    final realIdx = inLineBannerProvider.getRealIndex(idx);
                    if (realIdx < 0 || realIdx >= displayed.length) {
                      return const SizedBox.shrink();
                    }
                    final assignment = displayed[realIdx];
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

            Consumer<InlineBannerProvider>(
              builder: (context, inLineBannerProvider, child) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: inLineBannerProvider.getItemCount(
                    displayed.length,
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    if (inLineBannerProvider.isAdIndex(idx)) {
                      return const _NotesAdCard();
                    }
                    final realIdx = inLineBannerProvider.getRealIndex(idx);
                    if (realIdx < 0 || realIdx >= displayed.length) {
                      return const SizedBox.shrink();
                    }
                    final note = displayed[realIdx];

                    return _NoteCard(
                      note: note,
                      onTap: () async {
                        final subject = await SubjectRepository.instance
                            .getSubjectById(note.subjectId);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoteDetailScreen(
                              note: note,
                              subjectName: subject?.name ?? 'Unknown Subject',
                            ),
                          ),
                        );
                      },
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

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = NoteTypeTheme.color(note.type);
    final typeIcon = NoteTypeTheme.icon(note.type);
    final typeLabel = NoteTypeTheme.label(note.type);

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
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 22),
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
                  FutureBuilder(
                    future: SubjectRepository.instance.getSubjectById(
                      note.subjectId,
                    ),
                    builder: (context, snapshot) {
                      return Text(
                        "$typeLabel • ${snapshot.data?.name ?? ''}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      );
                    },
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

// ─── Section Native Ad Cards ──────────────────────────────────────────────────

class _DeadlineAdCard extends StatefulWidget {
  const _DeadlineAdCard();

  @override
  State<_DeadlineAdCard> createState() => _DeadlineAdCardState();
}

class _DeadlineAdCardState extends State<_DeadlineAdCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-1345393972469011/4027558652',
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 19.0,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _nativeAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sponsored',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
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
          if (_isLoaded && _nativeAd != null)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 80, maxHeight: 110),
              child: AdWidget(ad: _nativeAd!),
            )
          else
            Container(
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
                    'StudyVault Sponsored',
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
                    'Organize notes, pyqs & assignments effortlessly',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
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

class _UpcomingAdCard extends StatefulWidget {
  const _UpcomingAdCard();

  @override
  State<_UpcomingAdCard> createState() => _UpcomingAdCardState();
}

class _UpcomingAdCardState extends State<_UpcomingAdCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-1345393972469011/4027558652',
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: const Color(0xFFF0EFFE),
        cornerRadius: 16.0,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _nativeAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _nativeAd != null) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EFFE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AdWidget(ad: _nativeAd!),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Featured Partner',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sponsored',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E0FE),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.star_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesAdCard extends StatefulWidget {
  const _NotesAdCard();

  @override
  State<_NotesAdCard> createState() => _NotesAdCardState();
}

class _NotesAdCardState extends State<_NotesAdCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-1345393972469011/4027558652',
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 18.0,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _nativeAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _nativeAd != null) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AdWidget(ad: _nativeAd!),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFF6750A4),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Material',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6750A4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sponsored',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
