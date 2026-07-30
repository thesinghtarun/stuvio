import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // ── Palette (matches app-wide theme) ─────────────────────────────────────
  static const Color _primary = Color(0xFF5C35E8);
  static const Color _primaryLight = Color(0xFF7C5FF8);
  static const Color _bg = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textLight = Color(0xFF6B7280);
  static const Color _cardBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            elevation: 0,
            expandedHeight: 220,
            backgroundColor: _primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3D1FC8), _primary, _primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Privacy Policy',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your privacy is important to us.',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Privacy First Hero Card ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3D1FC8), _primary, _primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Privacy First',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'STUVIO is designed with privacy in mind. Your academic data belongs to you, and we never sell your personal information.',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.85),
                          height: 1.6,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Last Updated • July 2026',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Policy Sections ────────────────────────────────────────
                _section(
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFF5C35E8),
                  title: 'Information We Collect',
                  content:
                      'STUVIO stores only the information required to provide its features, including your profile details, workspaces, subjects, PDFs, notes, assignments, reminders within the user device only.',
                ),

                _section(
                  icon: Icons.folder_copy_outlined,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Files & Documents',
                  content:
                      'Your study materials remain yours. Imported PDFs, notes, and other academic resources are stored locally on your device unless you explicitly enable cloud synchronization in a future version.',
                ),

                _section(
                  icon: Icons.cloud_done_outlined,
                  iconColor: const Color(0xFF10B981),
                  title: 'Cloud Sync',
                  content:
                      'When cloud backup becomes available, only authenticated users will be able to access their own files. We do not access, modify, or share your documents.',
                ),

                _section(
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Data Security',
                  content:
                      'We implement industry-standard security measures to help protect your information. While no system is completely secure, we continuously improve our security practices.',
                ),

                _section(
                  icon: Icons.notifications_active_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Permissions',
                  content:
                      'STUVIO may request access to storage for importing PDFs, notifications for assignment reminders, and camera access for document scanning. These permissions are only used for their intended functionality.',
                ),

                _section(
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF5C35E8),
                  title: 'Your Rights',
                  content:
                      'You can edit or remove your information at any time. Future updates will also include options for exporting your data and permanently deleting your account.',
                ),

                _section(
                  icon: Icons.update_rounded,
                  iconColor: const Color(0xFF7C5FF8),
                  title: 'Policy Updates',
                  content:
                      'Our Privacy Policy may be updated occasionally to reflect improvements or legal requirements. Significant changes will be communicated within the application.',
                ),

                const SizedBox(height: 4),

                // ── Contact Card ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          size: 26,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Need Help?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you have any questions regarding this Privacy Policy, feel free to contact us.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: _textLight,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.mail_rounded, size: 18),
                          label: Text(
                            'Contact Support',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _section({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: GoogleFonts.plusJakartaSans(
                      color: _textLight,
                      height: 1.6,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
