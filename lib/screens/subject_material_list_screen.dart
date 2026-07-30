import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/subject.dart';
import 'package:studyvault/core/utils/note_type_theme.dart';
import 'package:studyvault/repositories/assignment_repository.dart';
import 'package:studyvault/repositories/note_repository.dart';
import 'package:studyvault/screens/assignment_detail_screen.dart';
import 'package:studyvault/screens/note_detail_screen.dart';

class SubjectMaterialListScreen extends StatefulWidget {
  final Subject subject;
  final String title;
  final NoteType? noteType;
  final bool isAssignment;

  const SubjectMaterialListScreen({
    super.key,
    required this.subject,
    required this.title,
    this.noteType,
    this.isAssignment = false,
  });

  @override
  State<SubjectMaterialListScreen> createState() =>
      _SubjectMaterialListScreenState();
}

class _SubjectMaterialListScreenState extends State<SubjectMaterialListScreen> {
  static const Color _bg = Color(0xFFF8F9FD);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textLight = Color(0xFF6B7280);

  bool _isLoading = true;
  List<Note> _notes = [];
  List<Assignment> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      if (widget.isAssignment) {
        final list = await AssignmentRepository.instance
            .getAssignmentsForSubject(widget.subject.id);
        list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        if (mounted) {
          setState(() {
            _assignments = list;
          });
        }
      } else if (widget.noteType != null) {
        final list = await NoteRepository.instance.getNotesForSubject(
          widget.subject.id,
          type: widget.noteType,
        );
        // Exclude notes that were auto-created as assignment PDF attachments
        final filtered = list
            .where((n) => !n.title.endsWith('(Attached PDF)'))
            .toList();
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (mounted) {
          setState(() {
            _notes = filtered;
          });
        }
      }
    } catch (e) {
      // Log error gracefully
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color get _headerColor {
    if (widget.isAssignment) {
      return NoteTypeTheme.assignmentColor;
    }
    if (widget.noteType != null) {
      return NoteTypeTheme.color(widget.noteType!);
    }
    return const Color(0xFF5C35E8);
  }

  IconData get _headerIcon {
    if (widget.isAssignment) {
      return NoteTypeTheme.assignmentIcon;
    }
    if (widget.noteType != null) {
      return NoteTypeTheme.icon(widget.noteType!);
    }
    return Icons.folder_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _headerColor;
    final themeIcon = _headerIcon;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.plusJakartaSans(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.subject.name,
              style: GoogleFonts.plusJakartaSans(
                color: _textLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : (widget.isAssignment ? _buildAssignmentsList(themeColor, themeIcon) : _buildNotesList(themeColor, themeIcon)),
    );
  }

  Widget _buildEmptyState(Color color, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 18),
            Text(
              'No ${widget.title} Found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No ${widget.title.toLowerCase()} added yet for ${widget.subject.name}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: _textLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesList(Color color, IconData icon) {
    if (_notes.isEmpty) {
      return _buildEmptyState(color, icon);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _notes.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final note = _notes[index];
        final sizeText = note.fileSize > 0
            ? '${(note.fileSize / 1024).toStringAsFixed(1)} KB'
            : 'Text Note';

        final dateText =
            '${note.createdAt.day.toString().padLeft(2, '0')}/${note.createdAt.month.toString().padLeft(2, '0')}/${note.createdAt.year}';

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteDetailScreen(
                  note: note,
                  subjectName: widget.subject.name,
                ),
              ),
            );
            _loadItems();
          },
          child: Container(
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            sizeText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: _textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFF9CA3AF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: _textLight,
                              fontWeight: FontWeight.w500,
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
        );
      },
    );
  }

  Widget _buildAssignmentsList(Color color, IconData icon) {
    if (_assignments.isEmpty) {
      return _buildEmptyState(color, icon);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _assignments.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        final dueText =
            'Due: ${assignment.dueDate.day.toString().padLeft(2, '0')}/${assignment.dueDate.month.toString().padLeft(2, '0')}/${assignment.dueDate.year}';

        final priorityColor = assignment.priority == AssignmentPriority.high
            ? Colors.red
            : assignment.priority == AssignmentPriority.medium
                ? Colors.orange
                : Colors.blue;

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssignmentDetailScreen(assignment: assignment),
              ),
            );
            _loadItems();
          },
          child: Container(
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              assignment.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              assignment.priority.name.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            dueText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: _textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFF9CA3AF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            assignment.submitted
                                ? 'Submitted'
                                : assignment.status == AssignmentStatus.ongoing
                                    ? 'Ongoing'
                                    : 'Pending',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: assignment.submitted
                                  ? Colors.green
                                  : assignment.status == AssignmentStatus.ongoing
                                      ? Colors.blue
                                      : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
