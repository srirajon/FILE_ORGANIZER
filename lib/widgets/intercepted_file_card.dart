import 'package:flutter/material.dart';
import '../models/shared_file_item.dart';
import '../theme/app_theme.dart';

class InterceptedFileCard extends StatelessWidget {
  final SharedFileItem file;
  final VoidCallback? onDismiss;

  const InterceptedFileCard({
    super.key,
    required this.file,
    this.onDismiss,
  });

  IconData _getFileIcon() {
    switch (file.category) {
      case FileCategory.document:
        return Icons.picture_as_pdf_rounded;
      case FileCategory.image:
        return Icons.image_rounded;
      case FileCategory.video:
        return Icons.videocam_rounded;
      case FileCategory.audio:
        return Icons.audiotrack_rounded;
      case FileCategory.archive:
        return Icons.folder_zip_rounded;
      case FileCategory.markdown:
        return Icons.article_rounded;
      case FileCategory.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor() {
    switch (file.category) {
      case FileCategory.document:
        return const Color(0xFFEF5350); // Red for PDF/Doc
      case FileCategory.image:
        return const Color(0xFF42A5F5); // Blue for image
      case FileCategory.video:
        return const Color(0xFFAB47BC); // Purple for video
      case FileCategory.audio:
        return const Color(0xFFFFA726); // Orange for audio
      case FileCategory.markdown:
        return const Color(0xFF26A69A); // Teal for markdown notes
      default:
        return WhatsAppTheme.accentGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A32) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WhatsAppTheme.accentGreen.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // File Icon thumbnail
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getFileColor().withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(),
              color: _getFileColor(),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),

          // File details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: WhatsAppTheme.accentGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SHARED FILE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: WhatsAppTheme.accentGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      file.formattedSize,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: WhatsAppTheme.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  file.fileName,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? WhatsAppTheme.darkTextPrimary : const Color(0xFF111B21),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: WhatsAppTheme.darkTextSecondary,
              onPressed: onDismiss,
              tooltip: 'Cancel share',
            ),
        ],
      ),
    );
  }
}
