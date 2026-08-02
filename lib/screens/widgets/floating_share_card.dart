import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/provider/share_overlay_provider.dart';

class FloatingShareCard extends StatelessWidget {
  const FloatingShareCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShareOverlayProvider>(
      builder: (context, provider, child) {
        if (!provider.isSharing || provider.currentNote == null) {
          return const SizedBox.shrink();
        }

        final note = provider.currentNote!;
        final finger = provider.fingerPosition;
        final size = provider.cardSize;

        return IgnorePointer(
          child: Stack(
            children: [
              // Background blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(.18)),
                ),
              ),

              // Floating card
              AnimatedPositioned(
                duration: const Duration(milliseconds: 16),
                curve: Curves.linear,
                left: finger.dx - size.width / 2,
                top: finger.dy - size.height / 2,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0.9,
                    end: provider.isOverShareTarget ? 1.18 : 1.08,
                  ),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  builder: (_, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Material(
                    color: Colors.transparent,
                    elevation: 0,
                    child: Container(
                      width: size.width,
                      height: size.height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.25),
                            blurRadius: 28,
                            spreadRadius: 4,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6750A4).withOpacity(.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf_rounded,
                                color: Color(0xFF6750A4),
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    note.filePath.split("/").last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
