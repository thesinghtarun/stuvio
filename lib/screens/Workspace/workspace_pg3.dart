import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/const/constant.dart';
import 'package:studyvault/core/theme/app_style.dart';
import 'package:studyvault/provider/workspace_screen_provider.dart';

class WorkspacePg3 extends StatelessWidget {
  const WorkspacePg3({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Column(
      children: [
        Text(pg3dt1, style: AppStyle.onboardingHeading),
        Text(pg3dt2, style: AppStyle.onboardingHeading),
        SizedBox(height: height * .09),

        Expanded(
          child: Consumer<WorkspaceScreenProvider>(
            builder: (context, provider, child) {
              return ListView(
                children: [
                  ...List.generate(provider.subjects.length, (index) {
                    final selected = provider.selectSubjects.contains(index);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => provider.toggleSubject(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: selected ? Colors.indigo : Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  provider.subjects[index],
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : Colors.indigo,
                                  ),
                                ),
                              ),

                              if (selected)
                                const Icon(Icons.check, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  Visibility(
                    visible: provider.showCustomSubjectField,
                    child: TextField(
                      controller: provider.subjectController,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        hintText: "Subject Name",
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => provider.addCustomSubject(),
                          icon: Icon(Icons.add),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Visibility(
                    visible: !provider.showCustomSubjectField,
                    child: InkWell(
                      onTap: () {
                        provider.toggleCustomSubjectField();
                      },
                      child: Container(
                        height: 60,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          "+ Add Custom Subject",
                          style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),

                  InkWell(
                    onTap: () => print("LISTSUB: ${provider.selectedSubjects}"),
                    child: Text("data"),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
