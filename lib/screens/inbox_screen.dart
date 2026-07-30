import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/models/inbox_item.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/provider/inbox_provider.dart';
import 'package:studyvault/screens/widgets/edit_inbox_file_dialog.dart';
import 'package:studyvault/screens/widgets/file_thumbnail_widget.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  static const Color _primary = Color(0xFF5C35E8);
  static const Color _bg = Color(0xFFF9FAFB);

  Future<void> _openFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      Fluttertoast.showToast(msg: 'File not found on device');
      return;
    }

    try {
      const platform = MethodChannel('com.singhtarun.stuvio/open_file');
      final result = await platform.invokeMethod('openFile', {
        'filePath': filePath,
      });
      AppLogger.action('InboxScreen', 'Opened file: $filePath result=$result');
    } on MissingPluginException {
      Fluttertoast.showToast(msg: 'Please restart app to enable file opening');
    } catch (e, st) {
      AppLogger.error('InboxScreen._openFile', e, st);
      Fluttertoast.showToast(msg: 'Could not open file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF111827),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<InboxProvider>(
          builder: (context, provider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inbox',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  '${provider.count} file(s) pending',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Consumer<InboxProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (provider.items.isEmpty) {
            return _buildNoDataBackground(context);
          }

          return RefreshIndicator(
            color: _primary,
            onRefresh: () => provider.fetchInboxItems(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return _buildInboxItemCard(context, item, provider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<InboxProvider>().pickAndUploadFile();
        },
        backgroundColor: _primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: Text(
          'Upload File',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataBackground(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          "assets/images/no_inbox.png",
          height: 200,
          width: 200,
        ),
      ),
    );
  }

  Widget _buildInboxItemCard(
    BuildContext context,
    InboxItem item,
    InboxProvider provider,
  ) {
    final sizeStr = item.fileSize > 0
        ? item.fileSize > 1024 * 1024
              ? '${(item.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB'
              : '${(item.fileSize / 1024).toStringAsFixed(0)} KB'
        : '';

    final createdDate =
        '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail Icon with tap-to-open
          FileThumbnailWidget(
            filePath: item.filePath,
            fileType: item.fileType,
            width: 54,
            height: 68,
            onTap: () => _openFile(item.filePath),
          ),
          const SizedBox(width: 14),

          // File Info
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openFile(item.filePath),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.fileType.toUpperCase(),

                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$sizeStr • $createdDate',

                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions: Edit (Categorize) & Delete
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit & Save',
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_note, color: _primary, size: 20),
                ),
                onPressed: () {
                  EditInboxFileDialog.show(context, item);
                },
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                onPressed: () {
                  _showDeleteConfirm(context, item, provider);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    InboxItem item,
    InboxProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete File?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove "${item.title}" from your inbox?',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF374151)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteItem(item.id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
