import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/folder_contact.dart';

class FolderAvatar extends StatelessWidget {
  final FolderContact folder;
  final double size;
  final double? fontSize;
  final VoidCallback? onTap;
  final bool showShadow;
  final Border? border;

  const FolderAvatar({
    super.key,
    required this.folder,
    this.size = 50,
    this.fontSize,
    this.onTap,
    this.showShadow = true,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;
    final customPath = folder.customImagePath;
    final hasCustomImage = customPath != null &&
        customPath.isNotEmpty &&
        !kIsWeb &&
        File(customPath).existsSync();

    if (hasCustomImage) {
      avatarWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border,
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: Image.file(
            File(customPath),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildEmojiFallback(),
          ),
        ),
      );
    } else {
      avatarWidget = _buildEmojiFallback();
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatarWidget,
      );
    }
    return avatarWidget;
  }

  Widget _buildEmojiFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: folder.avatarBgColor.withOpacity(0.92),
        border: border,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        folder.avatarEmoji,
        style: TextStyle(fontSize: fontSize ?? (size * 0.46)),
      ),
    );
  }
}

