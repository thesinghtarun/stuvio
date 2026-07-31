import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/subject.dart';
import 'package:studyvault/core/models/user.dart';
import 'package:studyvault/core/models/workspace.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/provider/home_provider.dart';
import 'package:studyvault/provider/subject_provider.dart';
import 'package:studyvault/repositories/assignment_repository.dart';
import 'package:studyvault/repositories/note_repository.dart';
import 'package:studyvault/repositories/subject_repository.dart';
import 'package:studyvault/repositories/user_repository.dart';
import 'package:studyvault/repositories/workspace_repository.dart';

class SaveSharedPdfDialog extends StatefulWidget {
  final String sharedFilePath;
  final String? initialFileName;

  const SaveSharedPdfDialog({
    super.key,
    required this.sharedFilePath,
    this.initialFileName,
  });

  static Future<void> show(BuildContext context, String filePath) async {
    debugPrint('🚀 [SHARE_DIALOG] show() called with filePath: $filePath');
    final fileName = filePath
        .split(Platform.pathSeparator)
        .last
        .split('/')
        .last
        .replaceAll('.pdf', '');
    AppLogger.action(
      'SHARE_RECEIVER',
      'Opening Import Dialog for single file: $filePath',
    );

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => SaveSharedPdfDialog(
          sharedFilePath: filePath,
          initialFileName: fileName,
        ),
      );
      debugPrint('🚀 [SHARE_DIALOG] Modal bottom sheet closed/dismissed');
    } catch (e, st) {
      debugPrint('❌ [SHARE_DIALOG] Error launching modal bottom sheet: $e');
      AppLogger.error('SaveSharedPdfDialog.show', e, st);
    }
  }

  @override
  State<SaveSharedPdfDialog> createState() => _SaveSharedPdfDialogState();
}

class _SaveSharedPdfDialogState extends State<SaveSharedPdfDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  User? _user;
  List<Workspace> _workspaces = [];
  Workspace? _selectedWorkspace;
  List<Subject> _subjects = [];
  Subject? _selectedSubject;

  String _selectedCategory = 'Note';
  final List<String> _categories = [
    'Note',
    'Assignment',
    'PYQ',
    'Lab Manual',
  ];

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  AssignmentPriority _priority = AssignmentPriority.medium;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialFileName ?? 'Shared Document',
    );
    _descriptionController = TextEditingController();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      _user = await UserRepository.instance.getUser();
      if (_user != null) {
        _workspaces = await WorkspaceRepository.instance.getWorkspacesForUser(
          _user!.id,
        );
        if (_workspaces.isNotEmpty) {
          if (_user!.currentWorkspaceId != null) {
            _selectedWorkspace = _workspaces.firstWhere(
              (w) => w.id == _user!.currentWorkspaceId,
              orElse: () => _workspaces.first,
            );
          } else {
            _selectedWorkspace = _workspaces.first;
          }
          await _loadSubjectsForWorkspace(_selectedWorkspace!.id);
        }
      }
    } catch (e, st) {
      AppLogger.error('SaveSharedPdfDialog._loadInitialData', e, st);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSubjectsForWorkspace(int workspaceId) async {
    final list = await SubjectRepository.instance.getSubjectsForWorkspace(
      workspaceId,
    );
    setState(() {
      _subjects = list;
      _selectedSubject = list.isNotEmpty ? list.first : null;
    });
  }

  bool get _isAssignmentCategory => _selectedCategory == 'Assignment';

  Future<void> _pickDueDate() async {
    AppLogger.click(
      'SaveSharedPdfDialog.DatePicker',
      'Opening calendar date picker',
    );
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final initialDate = _dueDate.isBefore(today) ? today : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        _dueDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
      });
      AppLogger.info(
        'SaveSharedPdfDialog',
        'Selected Due Date: ${_dueDate.toLocal()}',
      );
    }
  }

  Future<void> _saveSharedFile() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a title");
      return;
    }

    if (_selectedWorkspace == null) {
      Fluttertoast.showToast(msg: "Please select a workspace");
      return;
    }

    if (_selectedSubject == null) {
      Fluttertoast.showToast(msg: "Please select a subject");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      AppLogger.click(
        'SaveSharedPdfDialog.SaveButton',
        'Importing file "$title" to Subject: ${_selectedSubject!.name}',
      );

      // 1. Copy shared PDF file to app local storage
      final appDir = await getApplicationDocumentsDirectory();
      final materialsDir = Directory('${appDir.path}/materials');

      print("Documents Dir: ${appDir.path}");
      if (!await materialsDir.exists()) {
        await materialsDir.create(recursive: true);
      }

      final sourceFile = File(widget.sharedFilePath);
      final sanitizedFileName =
          '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(RegExp(r'[^\w.-]'), '_')}.pdf';
      final destinationPath = '${materialsDir.path}/$sanitizedFileName';

      int fileSize = 0;
      if (await sourceFile.exists()) {
        fileSize = await sourceFile.length();
        await sourceFile.copy(destinationPath);
      }

      AppLogger.db(
        'SaveSharedPdfDialog',
        'Copied shared file to: $destinationPath (Size: $fileSize bytes)',
      );

      // 2. Persist in Isar DB
      if (_isAssignmentCategory) {
        final assignment = await AssignmentRepository.instance.createAssignment(
          subjectId: _selectedSubject!.id,
          title: title,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : 'Attached PDF: $sanitizedFileName',
          dueDate: _dueDate,
          priority: _priority,
        );

        await NoteRepository.instance.createNote(
          subjectId: _selectedSubject!.id,
          title: '$title (Attached PDF)',
          type: NoteType.assignment,
          filePath: destinationPath,
          fileSize: fileSize,
        );

        AppLogger.action(
          'IMPORT_SUCCESS',
          'Created Assignment ID ${assignment.id} due on ${_dueDate.toLocal()}',
        );
      } else {
        NoteType noteType = NoteType.assignment;
        if (_selectedCategory == 'Note') noteType = NoteType.note;
        if (_selectedCategory == 'PYQ') noteType = NoteType.pyq;
        if (_selectedCategory == 'Lab Manual') noteType = NoteType.lab;

        final note = await NoteRepository.instance.createNote(
          subjectId: _selectedSubject!.id,
          title: title,
          type: noteType,
          filePath: destinationPath,
          fileSize: fileSize,
        );
        AppLogger.action(
          'IMPORT_SUCCESS',
          'Created Note ID ${note.id} under Subject: ${_selectedSubject!.name}',
        );
      }

      if (mounted) {
        try {
          context.read<HomeProvider>().reload();
        } catch (_) {}
        try {
          context.read<SubjectProvider>().reload();
        } catch (_) {}
      }

      Fluttertoast.showToast(
        msg: "Saved in ${_selectedWorkspace!.name} → ${_selectedSubject!.name}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e, st) {
      AppLogger.error('SaveSharedPdfDialog._saveSharedFile', e, st);
      Fluttertoast.showToast(msg: "Failed to import file: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row matching app font
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6750A4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: Color(0xFF6750A4),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Import Shared File',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF6750A4)),
                  ),
                )
              else ...[
                // File Title Label & Field
                Text(
                  'File Title',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    hintText: 'Enter title for PDF/Note',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF9CA3AF),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6750A4),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Workspace Dropdown
                Text(
                  'Workspace',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Workspace>(
                      value: _selectedWorkspace,
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                      items: _workspaces.map((w) {
                        return DropdownMenuItem<Workspace>(
                          value: w,
                          child: Text(w.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedWorkspace = val;
                          });
                          _loadSubjectsForWorkspace(val.id);
                          AppLogger.click(
                            'SaveSharedPdfDialog.WorkspaceDropdown',
                            'Switched workspace: ${val.name}',
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Subject Dropdown
                Text(
                  'Subject',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Subject>(
                      value: _selectedSubject,
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      hint: Text(
                        'No subjects available',
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                      items: _subjects.map((s) {
                        return DropdownMenuItem<Subject>(
                          value: s,
                          child: Text(s.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSubject = val;
                          });
                          AppLogger.click(
                            'SaveSharedPdfDialog.SubjectDropdown',
                            'Selected subject: ${val.name}',
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                Text(
                  'Category / Material Type',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                          AppLogger.click(
                            'SaveSharedPdfDialog.CategoryDropdown',
                            'Selected category: $val',
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Conditional Deadline Section for Assignment / Homework
                if (_isAssignmentCategory) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6750A4).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.event,
                              color: Color(0xFF6750A4),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Assignment Deadline & Priority',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Date Picker Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Due: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _pickDueDate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6750A4),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.calendar_month,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Select Date',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Priority Level Choice Chips
                        Text(
                          'Priority Level',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: AssignmentPriority.values.map((p) {
                            final isSelected = _priority == p;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  p.name.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF374151),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF6750A4),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF6750A4)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _priority = p;
                                    });
                                    AppLogger.click(
                                      'SaveSharedPdfDialog.PriorityChip',
                                      'Set priority: ${p.name}',
                                    );
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Main Action Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSharedFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6750A4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save to Stuvio',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
