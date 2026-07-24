import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/const/constant.dart';
import 'package:studyvault/core/theme/app_style.dart';
import 'package:studyvault/provider/workspace_screen_provider.dart';

class WorkspacePg2 extends StatelessWidget {
  const WorkspacePg2({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(pg2dt1, style: AppStyle.onboardingHeading),
        Text(pg2dt2, style: AppStyle.onboardingHeading),
        SizedBox(height: height * .1),

        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: List.generate(
            8,
            (index) => SemesterWidget(semester: "${index + 1}", index: index),
          ),
        ),
      ],
    );
  }
}

class SemesterWidget extends StatelessWidget {
  const SemesterWidget({
    super.key,
    required this.semester,
    required this.index,
  });

  final String semester;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceScreenProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.selectedSemester == index;

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => provider.selectSemester(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xff6C63FF) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? const Color(0xff6C63FF)
                    : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                semester,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xff4A5568),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
