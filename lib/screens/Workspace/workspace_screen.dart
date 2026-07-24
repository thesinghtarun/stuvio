import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:studyvault/provider/workspace_screen_provider.dart';
import 'package:studyvault/screens/Workspace/workspace_pg1.dart';
import 'package:studyvault/screens/Workspace/workspace_pg2.dart';
import 'package:studyvault/screens/Workspace/workspace_pg3.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Consumer<WorkspaceScreenProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: provider.pageController,
                    count: 3,
                    effect: WormEffect(
                      activeDotColor: Colors.indigo,
                      dotColor: Colors.grey.shade300,
                      dotHeight: 8,
                      dotWidth: 90,
                      spacing: 8,
                    ),
                  ),
                  SizedBox(height: height * 0.05),
                  Expanded(
                    child: PageView(
                      controller: provider.pageController,
                      onPageChanged: provider.onPageChanged,
                      children: [WorkspacePg1(), WorkspacePg2(), WorkspacePg3()],
                    ),
                  ),
                  InkWell(
                    onTap: () => provider.nextPage(context),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.indigo,
                      ),
                      child: Center(
                        child: Text(
                          "Continue",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
