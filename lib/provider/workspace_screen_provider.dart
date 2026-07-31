import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';
import 'package:studyvault/repositories/user_repository.dart';
import 'package:studyvault/repositories/workspace_repository.dart';
import 'package:studyvault/repositories/subject_repository.dart';
import 'package:studyvault/screens/home_screen.dart';

class WorkspaceScreenProvider extends ChangeNotifier {
  final PageController pageController = PageController();

  /// When true: launched from Profile tab, skip user name field & user save logic
  bool fromProfile = false;

  int currentPage = 0;

  void onPageChanged(int index) {
    currentPage = index;
    AppLogger.click(
      'DetailsPage.onPageChanged',
      'Switched to page index $index',
    );
    notifyListeners();
  }

  /// Reset provider state for fresh use (called before each WorkspaceScreen open)
  void reset({bool fromProfile = false}) {
    this.fromProfile = fromProfile;
    currentPage = 0;
    nameController.clear();
    workspaceController.clear();
    courseController.clear();
    specializationController.clear();
    selectedCourse = null;
    selectedSpecialization = null;
    selectedSemester = -1;
    selectSubjects.clear();
    selectedSubjects.clear();
    showCustomSubjectField = false;
    subjectController.clear();
    // Reset subjects list to defaults
    subjects
      ..clear()
      ..addAll([
        'DBMS',
        'MERN Stack',
        'Operating System',
        'Java',
        'Computer Networks',
        'Software Engineering',
        'Discrete Math',
      ]);
    AppLogger.action(
      'WorkspaceScreenProvider',
      'Reset. fromProfile=$fromProfile',
    );
    notifyListeners();
  }

  ///--------------------------------------------Page1
  static const List<String> popularCourses = [
    'B.Arch',
    'B.Com',
    'B.Sc',
    'B.Tech',
    'BBA',
    'BCA',
    'M.Com',
    'M.Sc',
    'M.Tech',
    'MBA',
    'MCA',
    'Other',
    'Not Applicable',
  ];

  static const List<String> popularSpecializations = [
    'AI/ML',
    'Business Analytics',
    'Civil Engineering',
    'Computer Applications & IT',
    'CSE',
    'Data Science',
    'Electrical & Electronics',
    'Finance & Accounting',
    'Information Technology',
    'Mechanical Engineering',
    'Other',
    'Not Applicable',
  ];

  String? selectedCourse;
  String? selectedSpecialization;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController workspaceController = TextEditingController();
  final TextEditingController courseController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();

  void selectCourse(String? value) {
    selectedCourse = value;
    if (value == 'Not Applicable') {
      selectedSpecialization = 'Not Applicable';
      specializationController.clear();
      courseController.text = 'Not Applicable';
    } else {
      if (selectedSpecialization == 'Not Applicable') {
        selectedSpecialization = null;
      }
      if (value == 'Other') {
        courseController.clear();
      } else if (value != null) {
        courseController.text = value;
      }
    }
    notifyListeners();
  }

  void selectSpecialization(String? value) {
    selectedSpecialization = value;
    if (value == 'Other') {
      specializationController.clear();
    } else if (value != null) {
      specializationController.text = value;
    }
    notifyListeners();
  }

  ///--------------------------------------------Page2
  int selectedSemester =
      -1; // 0 = Semester 1, 7 = Semester 8, 8 = Not Applicable

  void selectSemester(int index) {
    selectedSemester = index;
    AppLogger.click(
      'DetailsPage.selectSemester',
      'Selected Semester ${index + 1}',
    );
    notifyListeners();
  }

  ///--------------------------------------------Page3
  bool showCustomSubjectField = false;

  final TextEditingController subjectController = TextEditingController();

  final List<String> subjects = [
    "DBMS",
    "MERN Stack",
    "Operating System",
    "Java",
    "Computer Networks",
    "Software Engineering",
    "Discrete Math",
  ];

  final List<int> selectSubjects = [];
  final List<String> selectedSubjects = [];

  void toggleCustomSubjectField() {
    showCustomSubjectField = !showCustomSubjectField;
    AppLogger.click(
      'DetailsPage.toggleCustomSubjectField',
      'Custom subject field visible: $showCustomSubjectField',
    );
    notifyListeners();
  }

  void toggleSubject(int index) {
    if (selectSubjects.contains(index)) {
      selectSubjects.remove(index);
      selectedSubjects.remove(subjects[index]);
      AppLogger.click(
        'DetailsPage.toggleSubject',
        'Deselected subject: ${subjects[index]}',
      );
    } else {
      selectSubjects.add(index);
      selectedSubjects.add(subjects[index]);
      AppLogger.click(
        'DetailsPage.toggleSubject',
        'Selected subject: ${subjects[index]}',
      );
    }

    notifyListeners();
  }

  void addCustomSubject() {
    final text = subjectController.text.trim();
    AppLogger.click(
      'DetailsPage.addCustomSubject',
      'Attempting to add custom subject: "$text"',
    );

    if (text.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a subject name");
      return;
    }

    final exists = subjects.any(
      (subject) => subject.toLowerCase() == text.toLowerCase(),
    );

    if (exists) {
      Fluttertoast.showToast(msg: "Subject already exists");
      return;
    }

    subjects.add(text);

    final index = subjects.length - 1;
    selectSubjects.add(index);
    selectedSubjects.add(text);

    subjectController.clear();
    showCustomSubjectField = false;

    AppLogger.info(
      'DetailsProvider',
      'Added custom subject "$text" successfully.',
    );
    notifyListeners();
  }

  Future<void> nextPage(BuildContext context) async {
    final workspaceProvider = context.read<WorkspaceCounterProvider>();
    AppLogger.click(
      'DetailsPage.nextPageButton',
      'Triggered on Page $currentPage',
    );
    switch (currentPage) {
      case 0:
        // Skip name validation when launched from profile (user already exists)
        if (!fromProfile && nameController.text.trim().isEmpty) {
          Fluttertoast.showToast(msg: "Please enter your name");
          return;
        }

        final workspaceNameInput = workspaceController.text.trim();
        if (workspaceNameInput.isEmpty) {
          Fluttertoast.showToast(msg: "Please enter your workspace");
          return;
        }

        // 1. Check if workspace name is already in use by the user
        final existingUser = await UserRepository.instance.getUser();
        if (existingUser != null) {
          final workspaces = await WorkspaceRepository.instance
              .getWorkspacesForUser(existingUser.id);
          final isDuplicate = workspaces.any(
            (w) => w.name.toLowerCase() == workspaceNameInput.toLowerCase(),
          );
          if (isDuplicate) {
            Fluttertoast.showToast(
              msg:
                  "You are already using the workspace name '$workspaceNameInput'. Please try a different one for your clarity in the future.",
              toastLength: Toast.LENGTH_LONG,
            );
            return;
          }
        }

        // 2. Validate course selection/input
        if (selectedCourse == null) {
          Fluttertoast.showToast(msg: "Please select your course");
          return;
        }
        if (selectedCourse == 'Other' && courseController.text.trim().isEmpty) {
          Fluttertoast.showToast(msg: "Please enter your custom course");
          return;
        }

        // 3. Validate specialization selection/input
        if (selectedCourse != 'Not Applicable') {
          if (selectedSpecialization == null) {
            Fluttertoast.showToast(msg: "Please select your specialization");
            return;
          }
          if (selectedSpecialization == 'Other' &&
              specializationController.text.trim().isEmpty) {
            Fluttertoast.showToast(
              msg: "Please enter your custom specialization",
            );
            return;
          }
        }

        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;

      case 1:
        if (selectedSemester == -1) {
          Fluttertoast.showToast(msg: "Please select a semester");
          return;
        }

        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;

      case 2:
        if (selectedSubjects.isEmpty) {
          Fluttertoast.showToast(msg: "Please select at least one subject");
          return;
        }

        final workspaceName = workspaceController.text.trim();

        // Only used for new onboarding flow (not fromProfile)
        final userNameInput = nameController.text.trim();

        AppLogger.action(
          'ONBOARDING_FINISH',
          'fromProfile=$fromProfile, Workspace: $workspaceName, Subjects: $selectedSubjects',
        );

        var user = await UserRepository.instance.getUser();

        if (!fromProfile) {
          // Onboarding: create or update user
          if (user == null) {
            await UserRepository.instance.createUser(userNameInput);
            user = await UserRepository.instance.getUser();
          } else {
            user.name = userNameInput;
            await UserRepository.instance.updateUser(user);
          }
        }

        if (user != null) {
          final courseValue = selectedCourse == 'Not Applicable'
              ? 'Not Applicable'
              : (selectedCourse == 'Other'
                    ? courseController.text.trim()
                    : selectedCourse);

          final specializationValue =
              (selectedCourse == 'Not Applicable' ||
                  selectedSpecialization == 'Not Applicable')
              ? 'Not Applicable'
              : (selectedSpecialization == 'Other'
                    ? specializationController.text.trim()
                    : selectedSpecialization);

          final semesterValue = selectedSemester == 8
              ? 'Not Applicable'
              : (selectedSemester >= 0 && selectedSemester <= 7
                    ? 'Semester ${selectedSemester + 1}'
                    : 'Not Applicable');

          // Save workspace for user in Isar
          final workspace = await WorkspaceRepository.instance.createWorkspace(
            userId: user.id,
            name: workspaceName,
            course: courseValue,
            specialization: specializationValue,
            semester: semesterValue,
          );

          // Update active workspace link in user
          await UserRepository.instance.updateCurrentWorkspace(workspace.id);

          // Save subjects under workspace in Isar
          for (final subjectName in selectedSubjects) {
            await SubjectRepository.instance.createSubject(
              workspaceId: workspace.id,
              name: subjectName,
            );
          }
        }

        await workspaceProvider.refresh();
        if (!context.mounted) return;
        if (fromProfile) {
          AppLogger.nav('DetailsScreen', 'Back to Profile (fromProfile=true)');
          Navigator.pop(context);
        } else {
          AppLogger.nav('DetailsScreen', 'HomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
        break;
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
