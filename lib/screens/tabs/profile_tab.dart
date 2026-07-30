import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/workspace.dart';
import 'package:studyvault/core/utils/icon_helper.dart';
import 'package:studyvault/provider/profile_provider.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';
import 'package:studyvault/provider/workspace_screen_provider.dart';
import 'package:studyvault/screens/Workspace/workspace_screen.dart';
import 'package:studyvault/screens/about_app_screen.dart';
import 'package:studyvault/screens/privacy_policy_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ProfileTab
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().load();
    });
  }

  // ── Palette (consistent with app deepPurple/indigo) ────────────────────────
  static const Color _primary = Color(0xFF5C35E8);
  static const Color _primaryLight = Color(0xFF7C5FF8);
  static const Color _accent = Color(0xFF00D4AA);
  static const Color _bg = Color(0xFFF9FAFB);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMid = Color(0xFF374151);
  static const Color _textLight = Color(0xFF6B7280);

  // ── Pick image from gallery ────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null && mounted) {
      await context.read<ProfileProvider>().setAvatarPath(picked.path);
    }
  }

  // ── Edit username bottom sheet ─────────────────────────────────────────────
  void _showEditNameSheet(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Edit Name',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This name appears on your home greeting.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _textLight,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: _textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: GoogleFonts.plusJakartaSans(color: _textLight),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(sheetCtx);
                      await context.read<ProfileProvider>().updateUserName(
                        newName: name,
                        workspaceProvider: context
                            .read<WorkspaceCounterProvider>(),
                      );
                    },
                    child: Text(
                      'Save',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Open WorkspaceScreen for adding a new workspace ────────────────────────
  Future<void> _openAddWorkspace(BuildContext context) async {
    // Reset provider with fromProfile = true
    context.read<WorkspaceScreenProvider>().reset(fromProfile: true);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkspaceScreen()),
    );

    // Refresh profile stats after returning
    if (mounted) {
      await context.read<ProfileProvider>().load();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer2<WorkspaceCounterProvider, ProfileProvider>(
      builder: (context, workspaceProvider, profileProvider, _) {
        final userName = workspaceProvider.userName;
        final workspaces = workspaceProvider.workspaces;
        final activeWorkspace = workspaceProvider.selectedWorkspace;

        return Scaffold(
          backgroundColor: _bg,
          body: CustomScrollView(
            slivers: [
              // ── Hero App Bar ───────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: _primary,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroBanner(
                    userName: userName,
                    avatarPath: profileProvider.avatarPath,
                    memberSince: profileProvider.memberSince,
                    onPickImage: _pickImage,
                    onEditName: () => _showEditNameSheet(context, userName),
                  ),
                ),
              ),

              // ── Stats Row ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _StatsRow(
                    workspaceCount: profileProvider.workspaceCount,
                    subjectCount: profileProvider.subjectCount,
                    assignmentCount: profileProvider.assignmentCount,
                    isLoading: profileProvider.isLoading,
                  ),
                ),
              ),

              // ── Workspaces Section ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'My Workspaces',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const Spacer(),
                      _AddButton(onTap: () => _openAddWorkspace(context)),
                    ],
                  ),
                ),
              ),

              // ── Workspace Cards ───────────────────────────────────────────
              if (workspaces.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: _EmptyWorkspaceCard(
                      onAdd: () => _openAddWorkspace(context),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WorkspaceCard(
                          workspace: workspaces[i],
                          isActive: activeWorkspace?.id == workspaces[i].id,
                          onTap: () =>
                              workspaceProvider.selectWorkspace(workspaces[i]),
                        ),
                      ),
                      childCount: workspaces.length,
                    ),
                  ),
                ),

              // ── Settings Section ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Text(
                    'App Info',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: _SettingsCard(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Hero Banner
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.userName,
    required this.avatarPath,
    required this.memberSince,
    required this.onPickImage,
    required this.onEditName,
  });

  final String userName;
  final String? avatarPath;
  final DateTime? memberSince;
  final VoidCallback onPickImage;
  final VoidCallback onEditName;

  static const Color _primary = Color(0xFF5C35E8);
  static const Color _primaryLight = Color(0xFF7C5FF8);

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _memberSinceLabel(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Member since ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3D1FC8), _primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // ── Avatar ──────────────────────────────────────────────────────
            Stack(
              children: [
                // Avatar circle
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: avatarPath != null
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFB39DFF), Color(0xFF7C5FF8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    image: avatarPath != null
                        ? DecorationImage(
                            image: FileImage(File(avatarPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: avatarPath == null
                      ? Center(
                          child: Text(
                            _initials(userName),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),

                // Camera FAB
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onPickImage,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: _primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Name + pencil ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onEditName,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Member since ─────────────────────────────────────────────────
            Text(
              _memberSinceLabel(memberSince),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Stats Row
// ═══════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.workspaceCount,
    required this.subjectCount,
    required this.assignmentCount,
    required this.isLoading,
  });

  final int workspaceCount;
  final int subjectCount;
  final int assignmentCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatChip(
            icon: Icons.workspaces_rounded,
            label: 'Workspaces',
            value: isLoading ? '-' : '$workspaceCount',
            color: const Color(0xFF5C35E8),
          ),
          _Divider(),
          _StatChip(
            icon: Icons.menu_book_rounded,
            label: 'Subjects',
            value: isLoading ? '-' : '$subjectCount',
            color: const Color(0xFF0EA5E9),
          ),
          _Divider(),
          _StatChip(
            icon: Icons.assignment_rounded,
            label: 'Pending',
            value: isLoading ? '-' : '$assignmentCount',
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: const Color(0xFFE5E7EB));
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Add Button
// ═══════════════════════════════════════════════════════════════════════════════

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5C35E8), Color(0xFF7C5FF8)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5C35E8).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'New',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Workspace Card
// ═══════════════════════════════════════════════════════════════════════════════

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.workspace,
    required this.isActive,
    required this.onTap,
  });

  final Workspace workspace;
  final bool isActive;
  final VoidCallback onTap;

  String _typeLabel(WorkspaceType type) {
    switch (type) {
      case WorkspaceType.college:
        return 'College';
      case WorkspaceType.placement:
        return 'Placement';
      case WorkspaceType.personal:
        return 'Personal';
      case WorkspaceType.office:
        return 'Office';
      case WorkspaceType.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(workspace.color);
    final iconData = iconFromCode(workspace.icon);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? const Color(0xFF5C35E8) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? const Color(0xFF5C35E8).withOpacity(0.12)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(iconData, color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Name + type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workspace.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _TypeBadge(label: _typeLabel(workspace.type)),
                      if (workspace.isPinned) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Active indicator
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C35E8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Active',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C35E8),
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD1D5DB),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Empty Workspace Card
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyWorkspaceCard extends StatelessWidget {
  const _EmptyWorkspaceCard({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF5C35E8).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: const Color(0xFF5C35E8).withOpacity(0.6),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Create your first workspace',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5C35E8).withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Settings Card
// ═══════════════════════════════════════════════════════════════════════════════

class _SettingsCard extends StatefulWidget {
  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  String _version = '—';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF5C35E8),
            title: 'App Version',
            subtitle: _version,
            isFirst: true,
          ),
          _Separator(),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen(),
              ),
            ),
            child: _SettingsTile(
              icon: Icons.privacy_tip_rounded,
              iconColor: const Color.fromARGB(255, 216, 79, 29),
              title: 'Privacy Policy',
              subtitle: '2026 - STUVIO',
            ),
          ),
          _Separator(),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutAppScreen()),
            ),
            child: _SettingsTile(
              icon: Icons.auto_stories_rounded,
              iconColor: const Color(0xFF0EA5E9),
              title: 'About STUVIO',
              subtitle: 'Notes • PDFs • Organize • Study Smart',
              isLast: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
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

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      endIndent: 0,
      color: Color(0xFFF3F4F6),
    );
  }
}
