import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/provider/home_provider.dart';
import 'package:studyvault/repositories/assignment_repository.dart';
import 'package:studyvault/repositories/note_repository.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final Assignment assignment;

  const AssignmentDetailScreen({super.key, required this.assignment});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _pdfNameController;
  late DateTime _selectedDueDate;
  late AssignmentStatus _selectedStatus;

  Note? _attachedNote;
  bool _isLoadingNote = true;
  bool _showThumbnail = false;

  PdfController? _pdfController;
  Uint8List? _pdfThumbnailBytes;
  bool _isLoadingThumbnail = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assignment.title);
    _pdfNameController = TextEditingController();
    _selectedDueDate = widget.assignment.dueDate;

    // Resolve initial status
    if (widget.assignment.submitted) {
      _selectedStatus = AssignmentStatus.completed;
    } else {
      _selectedStatus = widget.assignment.status;
    }

    _loadAttachedPdf();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pdfNameController.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadAttachedPdf() async {
    try {
      final notes = await NoteRepository.instance.getNotesForSubject(
        widget.assignment.subjectId,
      );

      Note? targetNote;
      for (final n in notes) {
        if (n.filePath.isNotEmpty) {
          if (n.title.toLowerCase().contains(
                widget.assignment.title.toLowerCase(),
              ) ||
              targetNote == null) {
            targetNote = n;
          }
        }
      }

      if (mounted) {
        PdfController? controller;
        if (targetNote != null && targetNote.filePath.isNotEmpty) {
          final file = File(targetNote.filePath);
          if (await file.exists()) {
            try {
              controller = PdfController(
                document: PdfDocument.openFile(targetNote.filePath),
              );
            } catch (e) {
              AppLogger.error('AssignmentDetailScreen.PdfControllerInit', e);
            }
          }
        }

        setState(() {
          _attachedNote = targetNote;
          _pdfController = controller;
          if (targetNote != null) {
            _pdfNameController.text = targetNote.title;
          }
          _isLoadingNote = false;
        });

        if (targetNote != null && targetNote.filePath.isNotEmpty) {
          _renderPdfThumbnail(targetNote.filePath);
        }
      }
    } catch (e, st) {
      AppLogger.error('AssignmentDetailScreen._loadAttachedPdf', e, st);
      if (mounted) {
        setState(() => _isLoadingNote = false);
      }
    }
  }

  Future<void> _renderPdfThumbnail(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    try {
      if (mounted) setState(() => _isLoadingThumbnail = true);
      final pdfDoc = await PdfDocument.openFile(filePath);
      final page = await pdfDoc.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      await pdfDoc.close();

      if (mounted && pageImage != null) {
        setState(() {
          _pdfThumbnailBytes = pageImage.bytes;
          _isLoadingThumbnail = false;
        });
      }
    } catch (e, st) {
      AppLogger.error('AssignmentDetailScreen._renderPdfThumbnail', e, st);
      if (mounted) {
        setState(() => _isLoadingThumbnail = false);
      }
    }
  }

  Future<void> _pickDueDate() async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final initialDate = _selectedDueDate.isBefore(today) ? today : _selectedDueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6750A4),
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDueDate.hour,
          _selectedDueDate.minute,
        );
      });
    }
  }

  Future<void> _onPdfNameChanged(String newName) async {
    if (_attachedNote == null || newName.trim().isEmpty) return;
    try {
      _attachedNote!.title = newName.trim();
      await NoteRepository.instance.updateNote(_attachedNote!);
      AppLogger.info(
        'AssignmentDetailScreen',
        'Updated PDF name to: ${newName.trim()}',
      );
    } catch (e, st) {
      AppLogger.error('AssignmentDetailScreen._onPdfNameChanged', e, st);
    }
  }

  Future<void> _openPdfInDevice() async {
    if (_attachedNote == null || _attachedNote!.filePath.isEmpty) {
      Fluttertoast.showToast(msg: 'No PDF file attached to open');
      return;
    }

    final filePath = _attachedNote!.filePath;
    const platform = MethodChannel('com.singhtarun.stuvio/open_file');
    try {
      final result = await platform.invokeMethod('openFile', {
        'filePath': filePath,
      });
      AppLogger.action(
        'OPEN_FILE',
        'Platform openFile result: $result for $filePath',
      );
    } on MissingPluginException {
      Fluttertoast.showToast(
        msg: 'Please rebuild app to enable device PDF viewing',
      );
    } catch (e, st) {
      AppLogger.error('AssignmentDetailScreen._openPdfInDevice', e, st);
      Fluttertoast.showToast(msg: 'Could not open PDF: $e');
    }
  }

  Future<void> _saveAssignment() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter assignment title');
      return;
    }

    try {
      final isCompleted = _selectedStatus == AssignmentStatus.completed;
      widget.assignment.title = title;
      widget.assignment.dueDate = _selectedDueDate;
      widget.assignment.status = _selectedStatus;
      widget.assignment.submitted = isCompleted;

      await AssignmentRepository.instance.updateAssignment(widget.assignment);

      // Also update PDF title if edited
      if (_attachedNote != null && _pdfNameController.text.trim().isNotEmpty) {
        _attachedNote!.title = _pdfNameController.text.trim();
        await NoteRepository.instance.updateNote(_attachedNote!);
      }

      if (mounted) {
        context.read<HomeProvider>().reload();
        Fluttertoast.showToast(msg: 'Assignment updated successfully');
        Navigator.pop(context);
      }
    } catch (e, st) {
      AppLogger.error('AssignmentDetailScreen._saveAssignment', e, st);
      Fluttertoast.showToast(msg: 'Failed to update assignment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF111827),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assignment Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: _saveAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6750A4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                'Save',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Title Card
            _buildSectionHeader('ASSIGNMENT NAME'),
            const SizedBox(height: 8),
            Container(
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
              child: TextField(
                controller: _titleController,
                enabled: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  hintText: 'Enter assignment title...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF6750A4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Due Date Selector
            _buildSectionHeader('SUBMISSION DATE'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDueDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6750A4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF6750A4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HomeProvider.formatDate(_selectedDueDate),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          HomeProvider.daysLeftLabel(_selectedDueDate),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status Selector
            _buildSectionHeader('STATUS'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatusChip(
                    label: 'Pending',
                    status: AssignmentStatus.pending,
                    activeColor: const Color(0xFFF59E0B),
                    icon: Icons.hourglass_empty_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusChip(
                    label: 'On Going',
                    status: AssignmentStatus.ongoing,
                    activeColor: const Color(0xFF3B82F6),
                    icon: Icons.autorenew_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusChip(
                    label: 'Completed',
                    status: AssignmentStatus.completed,
                    activeColor: const Color(0xFF10B981),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Attached PDF Section
            _buildSectionHeader('ATTACHED MATERIAL'),
            const SizedBox(height: 8),
            if (_isLoadingNote)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: Color(0xFF6750A4)),
                ),
              )
            else if (_attachedNote == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Color(0xFF9CA3AF),
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No PDF attached to this assignment',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PDF Preview / Thumbnail Area
                    Stack(
                      children: [
                        InkWell(
                          onTap: _openPdfInDevice,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: _showThumbnail
                                  ? (_pdfController != null
                                        ? PdfView(
                                            controller: _pdfController!,
                                            scrollDirection: Axis.vertical,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                          )
                                        : (_pdfThumbnailBytes != null
                                              ? Image.memory(
                                                  _pdfThumbnailBytes!,
                                                  fit: BoxFit.contain,
                                                )
                                              : (_isLoadingThumbnail
                                                    ? const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                              color: Color(
                                                                0xFF6750A4,
                                                              ),
                                                            ),
                                                      )
                                                    : Image.asset(
                                                        'assets/images/standard_pdf_img.png',
                                                        fit: BoxFit.contain,
                                                      ))))
                                  : Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Image.asset(
                                          'assets/images/standard_pdf_img.png',
                                          height: 120,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        // Toggle Icon (Asset Image <-> Page 1 Thumbnail)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 2,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _showThumbnail = !_showThumbnail;
                                });
                                if (_showThumbnail &&
                                    _pdfThumbnailBytes == null &&
                                    _attachedNote != null) {
                                  _renderPdfThumbnail(_attachedNote!.filePath);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _showThumbnail
                                          ? Icons.image_rounded
                                          : Icons.auto_stories_rounded,
                                      color: const Color(0xFF6750A4),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _showThumbnail ? 'Default' : 'Thumbnail',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF6750A4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // PDF Title Field below PDF preview
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                color: Color(0xFFEF4444),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tap PDF card to open in device viewer',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'PDF Name',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: TextField(
                              controller: _pdfNameController,
                              enabled: true,
                              onChanged: _onPdfNameChanged,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter PDF name...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: const Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required AssignmentStatus status,
    required Color activeColor,
    required IconData icon,
  }) {
    final isSelected = _selectedStatus == status;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF4B5563),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
