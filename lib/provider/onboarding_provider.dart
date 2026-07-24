import 'package:flutter/material.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/screens/Workspace/workspace_screen.dart';

class OnboardingProvider extends ChangeNotifier {
  final PageController pageController = PageController();

  int currentPage = 0;

  void onPageChanged(int index) {
    currentPage = index;
    AppLogger.click('Onboarding.onPageChanged', 'Onboarding slide index: $index');
    notifyListeners();
  }

  void nextPage(BuildContext context) {
    AppLogger.click('Onboarding.nextButton', 'Click on slide index: $currentPage');
    if (currentPage < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      AppLogger.nav('OnboardingScreen', 'DetailsScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WorkspaceScreen()),
      );
    }
  }

  void skip() {
    AppLogger.click('Onboarding.skipButton', 'Skipped onboarding to final slide');
    pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
