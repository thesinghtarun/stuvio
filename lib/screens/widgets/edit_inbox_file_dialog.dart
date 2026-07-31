import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/assignment.dart';
import 'package:studyvault/core/models/inbox_item.dart';
import 'package:studyvault/core/models/note.dart';
import 'package:studyvault/core/models/subject.dart';
import 'package:studyvault/core/models/user.dart';
import 'package:studyvault/core/models/workspace.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/provider/home_provider.dart';
import 'package:studyvault/provider/inbox_provider.dart';
import 'package:studyvault/provider/subject_provider.dart';
import 'package:studyvault/repositories/subject_repository.dart';
import 'package:studyvault/repositories/user_repository.dart';
import 'package:studyvault/repositories/workspace_repository.dart';

class EditInboxFileDialog extends StatefulWidget {
  final InboxItem item;

  const EditInboxFileDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, InboxItem item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditInboxFileDialog(item: item),
    );
  }

  @override
  State<EditInboxFileDialog> createState() => _EditInboxFileDialogState();
}

class _EditInboxFileDialogState extends State<EditInboxFileDialog> {
  late final TextEditingController _titleController;

  User? _user;
  List<Workspace> _workspaces = [];
  Workspace? _selectedWorkspace;
  List<Subject> _subjects = [];
  Subject? _selectedSubject;

  NoteType _selectedNoteType = NoteType.note;

  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  final AssignmentPriority _priority = AssignmentPriority.medium;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
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
      AppLogger.error('EditInboxFileDialog._loadInitialData', e, st);
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
    if (mounted) {
      setState(() {
        _subjects = list;
        _selectedSubject = list.isNotEmpty ? list.first : null;
      });
    }
  }

  Future<void> _pickDueDate() async {
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
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
      });
    }
  }

  Future<void> _saveFile() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a file name");
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

    setState(() => _isSaving = true);

    try {
      final success = await context
          .read<InboxProvider>()
          .saveInboxItemToSubject(
            item: widget.item,
            subjectId: _selectedSubject!.id,
            title: title,
            noteType: _selectedNoteType,
            dueDate: _selectedNoteType == NoteType.assignment ? _dueDate : null,
            priority: _priority,
          );

      if (success && mounted) {
        try {
          context.read<HomeProvider>().reload();
        } catch (_) {}
        try {
          context.read<SubjectProvider>().reload();
        } catch (_) {}
        Fluttertoast.showToast(
          msg:
              "Saved to ${_selectedWorkspace!.name} → ${_selectedSubject!.name}",
        );
        Navigator.pop(context);
      }
    } catch (e, st) {
      AppLogger.error('EditInboxFileDialog._saveFile', e, st);
      Fluttertoast.showToast(msg: "Failed to save file: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C35E8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.drive_file_rename_outline,
                      color: Color(0xFF5C35E8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit & Categorize File',
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
                    child: CircularProgressIndicator(color: Color(0xFF5C35E8)),
                  ),
                )
              else ...[
                // File Name
                Text(
                  'File Name',
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
                    hintText: 'Enter file name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF5C35E8),
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
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Material Type Choice Section (Assignment, Notes, PYQs, Labs)
                Text(
                  'Material Type',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTypeChip('Notes', NoteType.note, Icons.description),
                    _buildTypeChip(
                      'Assignment',
                      NoteType.assignment,
                      Icons.assignment,
                    ),
                    _buildTypeChip('PYQs', NoteType.pyq, Icons.quiz),
                    _buildTypeChip('Labs', NoteType.lab, Icons.science),
                  ],
                ),
                const SizedBox(height: 16),

                // Assignment details if Assignment chosen
                if (_selectedNoteType == NoteType.assignment) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF5C35E8).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Due: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF374151),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _pickDueDate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5C35E8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(
                                Icons.calendar_month,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Select Date',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C35E8),
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
                            'Save to Subject',
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

  Widget _buildTypeChip(String label, NoteType type, IconData icon) {
    final isSelected = _selectedNoteType == type;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : const Color(0xFF5C35E8),
      ),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: isSelected ? Colors.white : const Color(0xFF374151),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF5C35E8),
      backgroundColor: const Color(0xFFF3F4F6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFF5C35E8) : const Color(0xFFE5E7EB),
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedNoteType = type;
          });
        }
      },
    );
  }
}
