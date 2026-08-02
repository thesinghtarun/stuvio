import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/core/utils/note_type_theme.dart';
import 'package:studyvault/provider/home_provider.dart';
import 'package:studyvault/repositories/note_repository.dart';
import 'package:studyvault/services/share_services.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  final String? subjectName;

  const NoteDetailScreen({super.key, required this.note, this.subjectName});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  static const Color _primary = Color(0xFF5C35E8);
  static const Color _primaryLight = Color(0xFF7C5FF8);
  static const Color _bg = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textLight = Color(0xFF6B7280);

  bool _fileExists = false;
  bool _isCheckingFile = true;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _checkFile();
    _markOpened();
  }

  Future<void> _checkFile() async {
    if (widget.note.filePath.isNotEmpty) {
      final exists = await File(widget.note.filePath).exists();
      if (mounted) {
        setState(() {
          _fileExists = exists;
          _isCheckingFile = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isCheckingFile = false;
        });
      }
    }
  }

  Future<void> _markOpened() async {
    await NoteRepository.instance.updateLastOpened(widget.note.id);
  }

  Future<void> _openFile() async {
    if (!_fileExists) {
      Fluttertoast.showToast(msg: 'File not found on device');
      return;
    }

    setState(() => _isOpening = true);

    try {
      const platform = MethodChannel('com.singhtarun.stuvio/open_file');
      final result = await platform.invokeMethod('openFile', {
        'filePath': widget.note.filePath,
      });
      AppLogger.action(
        'NoteDetailScreen',
        'Opened file: ${widget.note.filePath} result=$result',
      );
    } on MissingPluginException {
      Fluttertoast.showToast(
        msg: 'Please rebuild & restart the app to enable file opening!',
      );
    } catch (e, st) {
      AppLogger.error('NoteDetailScreen._openFile', e, st);
      Fluttertoast.showToast(msg: 'Could not open file: $e');
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final subject = widget.subjectName;
    final typeColor = NoteTypeTheme.color(note.type);
    final typeIcon = NoteTypeTheme.icon(note.type);
    final typeLabel = NoteTypeTheme.label(note.type);

    final fileSizeLabel = note.fileSize > 0
        ? '${(note.fileSize / 1024).toStringAsFixed(1)} KB'
        : null;

    final createdStr =
        '${note.createdAt.day.toString().padLeft(2, '0')}/${note.createdAt.month.toString().padLeft(2, '0')}/${note.createdAt.year}';
    final updatedStr =
        '${note.updatedAt.day.toString().padLeft(2, '0')}/${note.updatedAt.month.toString().padLeft(2, '0')}/${note.updatedAt.year}';

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: typeColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                tooltip: "Share",
                onPressed: () async {
                  await ShareService.shareFile(note.filePath);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [typeColor.withValues(alpha: 0.9), typeColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeIcon, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                typeLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          note.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subject != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subject,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (subject == null) Text("data"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body Content ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Meta info card ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _metaRow(
                        Icons.category_rounded,
                        'Type',
                        typeLabel,
                        typeColor,
                      ),
                      const Divider(height: 20, color: Color(0xFFF3F4F6)),
                      _metaRow(
                        Icons.calendar_today_rounded,
                        'Created',
                        createdStr,
                        _primary,
                      ),
                      if (updatedStr != createdStr) ...[
                        const Divider(height: 20, color: Color(0xFFF3F4F6)),
                        _metaRow(
                          Icons.update_rounded,
                          'Updated',
                          updatedStr,
                          _primaryLight,
                        ),
                      ],
                      if (fileSizeLabel != null) ...[
                        const Divider(height: 20, color: Color(0xFFF3F4F6)),
                        _metaRow(
                          Icons.storage_rounded,
                          'File Size',
                          fileSizeLabel,
                          const Color(0xFF10B981),
                        ),
                      ],
                      if (note.pages > 0) ...[
                        const Divider(height: 20, color: Color(0xFFF3F4F6)),
                        _metaRow(
                          Icons.auto_stories_rounded,
                          'Pages',
                          '${note.pages}',
                          Colors.blue,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Note content (text notes) ───────────────────────────────
                if (note.content != null && note.content!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Content',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          note.content!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: _textLight,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── File section ────────────────────────────────────────────
                if (note.filePath.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attached File',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isCheckingFile
                                    ? Colors.grey.withValues(alpha: 0.1)
                                    : _fileExists
                                    ? typeColor.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _isCheckingFile
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _fileExists
                                          ? Icons.picture_as_pdf_rounded
                                          : Icons.broken_image_rounded,
                                      color: _fileExists
                                          ? typeColor
                                          : Colors.red,
                                      size: 20,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: _textDark,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 6),

                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: _showRenameDialog,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: typeColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.edit_rounded,
                                            size: 16,
                                            color: typeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    _isCheckingFile
                                        ? 'Checking...'
                                        : _fileExists
                                        ? 'Available on device'
                                        : 'File not found on device',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: _isCheckingFile
                                          ? Colors.grey
                                          : _fileExists
                                          ? const Color(0xFF10B981)
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Open file button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: typeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      onPressed: (_isCheckingFile || !_fileExists || _isOpening)
                          ? null
                          : _openFile,
                      icon: _isOpening
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.open_in_new_rounded, size: 20),
                      label: Text(
                        _isOpening ? 'Opening...' : 'Open File',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: _textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  Future<void> _showRenameDialog() async {
    final controller = TextEditingController(text: widget.note.title);

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Rename File",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Enter new file name",
                  prefixIcon: const Icon(Icons.drive_file_rename_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 22),
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
                    child: ElevatedButton(
                      onPressed: () async {
                        final newName = controller.text.trim();

                        if (newName.isEmpty) {
                          Fluttertoast.showToast(
                            msg: "File name cannot be empty",
                          );
                          return;
                        }

                        if (newName == widget.note.title) {
                          Navigator.pop(context);
                          return;
                        }

                        widget.note.title = newName;

                        await NoteRepository.instance.updateNote(widget.note);

                        if (!mounted) return;

                        setState(() {});

                        Navigator.pop(context);

                        context.read<HomeProvider>().reload();
                        Fluttertoast.showToast(
                          msg: "File renamed successfully",
                        );
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
