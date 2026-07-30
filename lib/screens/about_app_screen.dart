import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  // ── Palette (matches app-wide theme) ─────────────────────────────────────
  static const Color _primary = Color(0xFF5C35E8);
  static const Color _primaryLight = Color(0xFF7C5FF8);
  static const Color _bg = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMid = Color(0xFF374151);
  static const Color _textLight = Color(0xFF6B7280);
  static const Color _cardBg = Colors.white;

  String _version = '—';

  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = info.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: _primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final top = MediaQuery.of(context).padding.top;
                final collapsed =
                    constraints.biggest.height <= kToolbarHeight + top + 20;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3D1FC8), _primary, _primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                    // Hero Content
                    SafeArea(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: collapsed
                              ? const SizedBox.shrink()
                              : Padding(
                                  key: const ValueKey('hero'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 20,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: 84,
                                        width: 84,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Image.asset(
                                            "assets/images/splash_logo.png",
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'STUVIO',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Text(
                                          'Version $_version',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Student Virtual Organizer\nYour Smart Academic Companion',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Collapsed Title
                    AnimatedOpacity(
                      opacity: collapsed ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: SafeArea(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: kToolbarHeight,
                            child: Center(
                              child: Text(
                                'About App',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Feature Grid ──────────────────────────────────────────
                _sectionTitle('What STUVIO Offers'),
                const SizedBox(height: 16),

                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: const [
                    _FeatureCard(
                      icon: Icons.picture_as_pdf_rounded,
                      title: 'PDF\nManagement',
                      color: Color(0xFF5C35E8),
                    ),
                    _FeatureCard(
                      icon: Icons.assignment_rounded,
                      title: 'Assignments',
                      color: Color(0xFFEF4444),
                    ),
                    _FeatureCard(
                      icon: Icons.folder_special_rounded,
                      title: 'Subjects',
                      color: Color(0xFF0EA5E9),
                    ),
                    _FeatureCard(
                      icon: Icons.notifications_active_rounded,
                      title: 'Reminders',
                      color: Color(0xFF10B981),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Info Cards ────────────────────────────────────────────
                _infoCard(
                  Icons.flag_rounded,
                  'Our Mission',
                  'STUVIO helps students organize their academic life by bringing notes, PDFs, assignments, reminders, and subjects together into one beautiful workspace.',
                  const Color(0xFF5C35E8),
                ),

                _infoCard(
                  Icons.auto_awesome_rounded,
                  'Why STUVIO?',
                  'Managing study material across multiple messaging apps and folders can be overwhelming. STUVIO keeps everything organized so you can focus on learning instead of searching.',
                  const Color(0xFF0EA5E9),
                ),

                // ── Current Features ──────────────────────────────────────
                _sectionTitle('Current Features'),
                const SizedBox(height: 14),

                _featureTile(
                  Icons.check_circle_rounded,
                  'Organize PDFs by Subject',
                  const Color(0xFF5C35E8),
                ),
                _featureTile(
                  Icons.check_circle_rounded,
                  'Assignment Deadline Tracking',
                  const Color(0xFF5C35E8),
                ),
                _featureTile(
                  Icons.check_circle_rounded,
                  'Workspace Management',
                  const Color(0xFF5C35E8),
                ),
                _featureTile(
                  Icons.check_circle_rounded,
                  'Semester Organization',
                  const Color(0xFF5C35E8),
                ),
                _featureTile(
                  Icons.check_circle_rounded,
                  'Quick Search',
                  const Color(0xFF5C35E8),
                ),
                _featureTile(
                  Icons.check_circle_rounded,
                  'Study Reminder Notifications',
                  const Color(0xFF5C35E8),
                ),

                const SizedBox(height: 24),

                // ── Coming Soon ───────────────────────────────────────────
                _sectionTitle('Coming Soon'),
                const SizedBox(height: 14),

                _featureTile(
                  Icons.auto_awesome_rounded,
                  'AI Study Assistant',
                  const Color(0xFF7C5FF8),
                ),
                _featureTile(
                  Icons.cloud_done_rounded,
                  'Cloud Backup & Sync',
                  const Color(0xFF7C5FF8),
                ),
                _featureTile(
                  Icons.groups_rounded,
                  'Collaborative Workspaces',
                  const Color(0xFF7C5FF8),
                ),
                _featureTile(
                  Icons.insights_rounded,
                  'Study Analytics',
                  const Color(0xFF7C5FF8),
                ),

                const SizedBox(height: 28),

                // ── Built With ────────────────────────────────────────────
                _infoCard(
                  Icons.code_rounded,
                  'Built With',
                  'Flutter  •  Provider  •  Isar Database\nMaterial 3  •  Google Fonts',
                  const Color(0xFF10B981),
                ),

                _infoCard(
                  Icons.favorite_rounded,
                  'Made for Students',
                  'STUVIO is designed to make academic life simpler, cleaner, and more productive for every student.',
                  const Color(0xFFEF4444),
                ),

                // ── Thank You Card ────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 22,
                  ),
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
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Thank You',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Thank you for choosing STUVIO.\nWe hope it helps make your academic journey easier and more organized.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.85),
                          height: 1.6,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: _textDark,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _featureTile(IconData icon, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _textMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    color: _textLight,
                    height: 1.6,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Feature Card
// ═══════════════════════════════════════════════════════════════════════════════

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
