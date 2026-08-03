import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  static const Color _primary = Color(0xFF5C35E8);
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _cardColor = Colors.white;
  static const Color _titleColor = Color(0xFF111827);
  static const Color _subtitleColor = Color(0xFF6B7280);
  static const Color _warning = Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "How to Use",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
        iconTheme: const IconThemeData(color: _titleColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Getting Started ───────────────────────────────────────────────
          _sectionTitle("Getting Started"),

          _stepCard(
            step: "1",
            icon: Icons.workspaces_outline,
            title: "Create Your First Workspace",
            description:
                "When you open the app for the first time, create your first workspace to start organizing your study materials. Give it a name like \"Semester 5\" or \"GATE Prep\".",
          ),

          _stepCard(
            step: "2",
            icon: Icons.add_circle_outline,
            title: "Add Files",
            description:
                "Tap the + button to add study files from your device. Only study-relevant formats are accepted. Maximum file size: 50 MB.",
          ),

          _fileTypesCard(),

          _stepCard(
            step: "3",
            icon: Icons.share_outlined,
            title: "Share Files From Other Apps",
            description:
                "Open any file in WhatsApp, Gmail, Files, or any other app, tap Share, then select StudyVault. The file lands in your Inbox automatically. Files with unsupported formats or size over 50 MB will be rejected with an error message.",
          ),

          _stepCard(
            step: "4",
            icon: Icons.category_outlined,
            title: "Understand Note Categories",
            description:
                "When saving a file from Inbox to a subject, you choose a category. Each category organizes your files differently:",
            extra: _noteCategoriesWidget(),
          ),

          _stepCard(
            step: "5",
            icon: Icons.inbox_outlined,
            title: "Organize Your Files",
            description:
                "Open the Inbox section to rename, choose a category, pick a subject, and save newly added files. Files stay in the Inbox until you organize them.",
          ),

          _stepCard(
            step: "6",
            icon: Icons.delete_outline,
            title: "Delete a File",
            description:
                "Go to the Notes section inside a subject and swipe left on any file to permanently delete it.",
          ),

          _stepCard(
            step: "7",
            icon: Icons.description_outlined,
            title: "View, Edit & Share Files",
            description:
                "Tap any file in the Notes section to open it. From there you can view its details, rename it, or share it with another app.",
          ),

          _stepCard(
            step: "8",
            icon: Icons.drag_indicator_rounded,
            title: "Share Using Dynamic Island",
            description:
                "On supported devices, tap and hold a file, then drag it to the Dynamic Island to quickly share it with another app.",
          ),

          const SizedBox(height: 30),

          // ── Subject Management ────────────────────────────────────────────
          _sectionTitle("Subject Management"),

          _stepCard(
            step: "9",
            icon: Icons.library_add_outlined,
            title: "Add a New Subject",
            description:
                "Scroll to the end of the Subject carousel on the Subjects tab and tap \"Add Subject\" to create a new subject within the current workspace.",
          ),

          _stepCard(
            step: "10",
            icon: Icons.delete_forever_outlined,
            title: "Delete a Subject",
            description:
                "Tap and hold a subject card, then swipe it upward to delete the subject.",
            warning:
                "Deleting a subject permanently removes all Notes, Assignments, PYQs, and Labs associated with it. This action cannot be undone.",
          ),

          const SizedBox(height: 30),

          // ── Search & Filters ──────────────────────────────────────────────
          _sectionTitle("Search & Filters"),

          _stepCard(
            step: "11",
            icon: Icons.search_rounded,
            title: "Search Your Files",
            description:
                "Open the Search tab to find any file or assignment across all subjects in your workspace. Type a filename or use the quick filter chips to narrow results by type:",
            extra: _searchFiltersWidget(),
          ),

          const SizedBox(height: 30),

          // ── Assignment Tracking ───────────────────────────────────────────
          _sectionTitle("Assignment Tracking"),

          _stepCard(
            step: "12",
            icon: Icons.assignment_outlined,
            title: "Track Deadlines & Upcoming",
            description:
                "When you save a file as the Assignment category, a deadline entry is automatically created. The Home tab shows two smart sections:",
            extra: _deadlineInfoWidget(),
          ),

          const SizedBox(height: 30),

          // ── Workspace & Profile ───────────────────────────────────────────
          _sectionTitle("Workspace & Profile"),

          _stepCard(
            step: "13",
            icon: Icons.account_circle_outlined,
            title: "Create Another Workspace",
            description:
                "Open the Profile tab and select \"Create Workspace\" to add another workspace for a different semester, exam, or purpose.",
          ),

          _stepCard(
            step: "14",
            icon: Icons.edit_outlined,
            title: "Edit Your Profile",
            description:
                "Open the Profile tab to personalise your account. Tap your avatar to pick a profile photo from your gallery. Tap your display name to rename it.",
          ),

          const SizedBox(height: 24),

          _tipCard(
            "Tip: Keep separate workspaces for different semesters, exams, or personal projects to stay organised and avoid mixing up study materials.",
          ),

          const SizedBox(height: 12),

          _tipCard(
            "Tip: Use the Search tab with filters to quickly find all PYQs, Labs, or Assignments before an exam — no need to open each subject manually.",
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _titleColor,
        ),
      ),
    );
  }

  Widget _stepCard({
    required String step,
    required IconData icon,
    required String title,
    required String description,
    String? warning,
    Widget? extra,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _primary.withValues(alpha: 0.12),
            child: Text(
              step,
              style: GoogleFonts.poppins(
                color: _primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: _primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _subtitleColor,
                    height: 1.6,
                  ),
                ),
                if (extra != null) ...[
                  const SizedBox(height: 12),
                  extra,
                ],
                if (warning != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: _warning,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            warning,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileTypesCard() {
    const types = [
      ('PDF', Icons.picture_as_pdf_rounded, Color(0xFFEF4444)),
      ('JPG / PNG\nWEBP', Icons.image_rounded, Color(0xFF10B981)),
      ('DOC / DOCX', Icons.description_rounded, Color(0xFF3B82F6)),
      ('TXT / ODT', Icons.text_snippet_rounded, Color(0xFF6B7280)),
      ('PPT / PPTX', Icons.slideshow_rounded, Color(0xFFF59E0B)),
      ('XLS / XLSX', Icons.table_chart_rounded, Color(0xFF059669)),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open_rounded, color: _primary, size: 18),
              const SizedBox(width: 8),
              Text(
                "Supported File Types",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: types.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: t.$3.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: t.$3.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$2, size: 15, color: t.$3),
                    const SizedBox(width: 5),
                    Text(
                      t.$1,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: t.$3,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: _warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.data_usage_rounded,
                    size: 14, color: _warning),
                const SizedBox(width: 6),
                Text(
                  "Max file size: 50 MB",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteCategoriesWidget() {
    const categories = [
      (Icons.menu_book_rounded, 'Notes',
          'Regular class notes & handouts', Color(0xFF6750A4)),
      (Icons.assignment_rounded, 'Assignments',
          'Submitted work — auto-creates a deadline entry', Color(0xFF3B82F6)),
      (Icons.history_edu_rounded, 'PYQs',
          'Previous Year Question papers', Color(0xFFF59E0B)),
      (Icons.science_rounded, 'Labs',
          'Lab reports & practical files', Color(0xFF10B981)),
    ];

    return Column(
      children: categories.map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.$4.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(c.$1, size: 16, color: c.$4),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.$2,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _titleColor,
                      ),
                    ),
                    Text(
                      c.$3,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _searchFiltersWidget() {
    const filters = [
      ('All', Color(0xFF6B7280)),
      ('Notes', Color(0xFF6750A4)),
      ('Assignments', Color(0xFF3B82F6)),
      ('PYQs', Color(0xFFF59E0B)),
      ('Labs', Color(0xFF10B981)),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: filters.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: f.$2.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: f.$2.withValues(alpha: 0.3)),
          ),
          child: Text(
            f.$1,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: f.$2,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _deadlineInfoWidget() {
    return Column(
      children: [
        _deadlineRow(
          icon: Icons.alarm_rounded,
          color: const Color(0xFFEF4444),
          label: 'Deadlines',
          desc: 'Assignments due within the next 7 days',
        ),
        const SizedBox(height: 8),
        _deadlineRow(
          icon: Icons.event_rounded,
          color: const Color(0xFF6750A4),
          label: 'Upcoming',
          desc: 'Assignments due later — plan ahead',
        ),
      ],
    );
  }

  Widget _deadlineRow({
    required IconData icon,
    required Color color,
    required String label,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _titleColor,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tipCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: _primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: _subtitleColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
