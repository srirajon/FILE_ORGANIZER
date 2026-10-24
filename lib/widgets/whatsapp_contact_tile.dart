import 'package:flutter/material.dart';
import '../models/folder_contact.dart';
import '../theme/app_theme.dart';

class WhatsAppContactTile extends StatelessWidget {
  final FolderContact folder;
  final bool isSelected;
  final bool isSelectable;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const WhatsAppContactTile({
    super.key,
    required this.folder,
    this.isSelected = false,
    this.isSelectable = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isSelected
          ? (isDark ? const Color(0xFF2A3942) : const Color(0xFFE7FCE3))
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: WhatsAppTheme.accentGreen.withOpacity(0.15),
        highlightColor: WhatsAppTheme.accentGreen.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: folder.avatarBgColor.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      folder.avatarEmoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: WhatsAppTheme.accentGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Title and preview text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            folder.name,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? WhatsAppTheme.darkTextPrimary
                                  : const Color(0xFF111B21),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          folder.lastTimestamp,
                          style: TextStyle(
                            fontSize: 12,
                            color: folder.unreadOrNewCount > 0
                                ? WhatsAppTheme.badgeGreen
                                : WhatsAppTheme.darkTextSecondary,
                            fontWeight: folder.unreadOrNewCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.done_all,
                                size: 16,
                                color: folder.unreadOrNewCount > 0
                                    ? WhatsAppTheme.darkTextSecondary
                                    : WhatsAppTheme.blueCheck,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  folder.description,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: WhatsAppTheme.darkTextSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // WhatsApp Green Badge with Item Count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: folder.unreadOrNewCount > 0
                                ? WhatsAppTheme.badgeGreen
                                : (isDark
                                    ? const Color(0xFF222E35)
                                    : const Color(0xFFE9EDEF)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${folder.files.length}',
                            style: TextStyle(
                              color: folder.unreadOrNewCount > 0
                                  ? Colors.black87
                                  : WhatsAppTheme.darkTextSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
