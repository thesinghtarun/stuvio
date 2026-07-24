import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:studyvault/provider/onboarding_provider.dart';
import 'package:studyvault/screens/onboarding/page1.dart';
import 'package:studyvault/screens/onboarding/page2.dart';
import 'package:studyvault/screens/onboarding/page3.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Consumer<OnboardingProvider>(
          builder: (context, provider, child) {
            return PageView(
              controller: provider.pageController,
              onPageChanged: provider.onPageChanged,
              children: const [Page1(), Page2(), Page3()],
            );
          },
        ),
      ),
      bottomSheet: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SmoothPageIndicator(
                  controller: provider.pageController,
                  count: 3,
                  effect: WormEffect(
                    activeDotColor: Colors.indigo,
                    dotColor: Colors.grey.shade300,
                    dotHeight: 13,
                    dotWidth: 13,
                    spacing: 8,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: provider.skip,
                      child: Text(
                        "Skip",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    InkWell(
                      onTap:()=> provider.nextPage(context),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.chevron_right_sharp,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
