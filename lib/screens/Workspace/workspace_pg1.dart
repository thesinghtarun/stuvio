import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/const/constant.dart';
import 'package:studyvault/core/theme/app_style.dart';
import 'package:studyvault/provider/workspace_screen_provider.dart';

class WorkspacePg1 extends StatelessWidget {
  const WorkspacePg1({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Consumer<WorkspaceScreenProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pg1dt1, style: AppStyle.onboardingHeading),
              Text(pg1dt2, style: AppStyle.onboardingHeading),
              SizedBox(height: height * .08),

              // ─── Name field: hidden when creating workspace from profile ───
              if (!provider.fromProfile) ...[
                Text(
                  "Name",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: provider.nameController,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    hintText: "First Name",
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              Text(
                "Workspace Name",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: provider.workspaceController,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  hintText: "My Workspace",
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Course",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: provider.courseController,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  hintText: "Enter your Course",
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }
}
