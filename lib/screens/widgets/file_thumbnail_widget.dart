import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfx/pdfx.dart';

class FileThumbnailWidget extends StatefulWidget {
  final String filePath;
  final String fileType;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const FileThumbnailWidget({
    super.key,
    required this.filePath,
    required this.fileType,
    this.width = 60,
    this.height = 76,
    this.onTap,
  });

  @override
  State<FileThumbnailWidget> createState() => _FileThumbnailWidgetState();
}

class _FileThumbnailWidgetState extends State<FileThumbnailWidget> {
  Uint8List? _pdfThumbnailBytes;
  bool _isLoadingPdf = false;

  @override
  void initState() {
    super.initState();
    if (_isPdf) {
      _renderPdfThumbnail();
    }
  }

  @override
  void didUpdateWidget(covariant FileThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      if (_isPdf) {
        _renderPdfThumbnail();
      }
    }
  }

  bool get _isPdf =>
      widget.fileType == 'pdf' || widget.filePath.toLowerCase().endsWith('.pdf');

  bool get _isImage =>
      widget.fileType == 'image' ||
      ['.jpg', '.jpeg', '.png', '.webp', '.gif'].any(
        (ext) => widget.filePath.toLowerCase().endsWith(ext),
      );

  Future<void> _renderPdfThumbnail() async {
    final file = File(widget.filePath);
    if (!await file.exists()) {
      return;
    }

    try {
      if (mounted) setState(() => _isLoadingPdf = true);
      final pdfDoc = await PdfDocument.openFile(widget.filePath);
      final page = await pdfDoc.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      await pdfDoc.close();

      if (mounted && pageImage != null) {
        setState(() {
          _pdfThumbnailBytes = pageImage.bytes;
          _isLoadingPdf = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: _buildContent()),
            // Thumbnail Badge / Overlay Icon
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getExtBadgeText(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getExtBadgeText() {
    if (widget.filePath.contains('.')) {
      return widget.filePath.split('.').last.toUpperCase();
    }
    return widget.fileType.toUpperCase();
  }

  Widget _buildContent() {
    if (_isImage) {
      final file = File(widget.filePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(Icons.image),
        );
      }
      return _buildFallbackIcon(Icons.image);
    }

    if (_isPdf) {
      if (_isLoadingPdf) {
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5C35E8)),
          ),
        );
      }
      if (_pdfThumbnailBytes != null) {
        return Image.memory(
          _pdfThumbnailBytes!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(Icons.picture_as_pdf),
        );
      }
      return _buildFallbackIcon(Icons.picture_as_pdf, color: Colors.redAccent);
    }

    // DOC / Other preview
    return _buildDocFirstPagePreview();
  }

  Widget _buildDocFirstPagePreview() {
    final fileName = widget.filePath.split(Platform.pathSeparator).last;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, size: 14, color: Color(0xFF5C35E8)),
              const SizedBox(width: 2),
              Expanded(
                child: Container(
                  height: 3,
                  color: const Color(0xFFE5E7EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const Spacer(),
          Container(height: 2, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 2),
          Container(height: 2, width: 28, color: const Color(0xFFE5E7EB)),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(IconData icon, {Color color = const Color(0xFF5C35E8)}) {
    return Center(
      child: Icon(icon, color: color, size: 26),
    );
  }
}
