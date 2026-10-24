import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import '../models/shared_file_item.dart';
import '../theme/app_theme.dart';

class FileOpenerService {
  static const MethodChannel _channel = MethodChannel('com.fileorganizer/app_chooser');

  /// Opens a shared file using the Android System App Chooser showing ALL relevant apps
  /// (e.g., Adobe Acrobat, Google Drive, Office, VLC, Gallery, etc.)
  static Future<void> openFile({
    required BuildContext context,
    required SharedFileItem file,
  }) async {
    // Web environment handling
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🌐 Web Preview: "${file.fileName}" (${file.formattedSize})',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: WhatsAppTheme.darkTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final filePath = file.filePath;
    if (filePath == null || filePath.isEmpty) {
      _showErrorSnackBar(context, 'No file path found for "${file.fileName}"');
      return;
    }

    final fileOnDisk = File(filePath);
    if (!await fileOnDisk.exists()) {
      if (!context.mounted) return;
      // If it's a simulated file from demo mode or temp cache
      _showInfoDialog(
        context,
        title: 'Demo / Cached File',
        content:
            'File: ${file.fileName}\nSize: ${file.formattedSize}\nType: ${file.mimeType}\n\n'
            'Target Path: $filePath\n\n'
            '(On physical Android devices, real files will open in your installed apps like Acrobat, Google Drive, Gallery, VLC, etc.)',
      );
      return;
    }

    // On Android, use native Intent.createChooser so ALL apps capable of opening the file are displayed
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final success = await _channel.invokeMethod<bool>('openWithChooser', {
          'filePath': filePath,
          'mimeType': file.mimeType,
          'title': 'Open "${file.fileName}" with...',
        });
        if (success == true) {
          return;
        }
      } catch (e) {
        debugPrint('Android App Chooser MethodChannel fallback: $e');
      }
    }

    // Fallback to open_filex
    try {
      final result = await OpenFilex.open(filePath, type: file.mimeType);

      if (result.type != ResultType.done) {
        String errorMsg;
        switch (result.type) {
          case ResultType.fileNotFound:
            errorMsg = 'File not found on device storage.';
            break;
          case ResultType.noAppToOpen:
            errorMsg = 'No application installed to open ${file.fileName}.';
            break;
          case ResultType.permissionDenied:
            errorMsg = 'Storage permission denied to open this file.';
            break;
          default:
            errorMsg = result.message;
        }
        if (context.mounted) {
          _showErrorSnackBar(context, errorMsg);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Error opening file: $e');
      }
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: WhatsAppTheme.accentGreen),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: WhatsAppTheme.accentGreen)),
          ),
        ],
      ),
    );
  }
}
