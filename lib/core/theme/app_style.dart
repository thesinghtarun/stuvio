import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyle {

  static final TextStyle onboardingHeading = GoogleFonts.plusJakartaSans(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  color: const Color(0xFF111827),
  height: 1.2,
  letterSpacing: -0.3,
);

static final TextStyle onboardingSubHeading = GoogleFonts.plusJakartaSans(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: const Color(0xFF6B7280),
  height: 1.6,
);
}