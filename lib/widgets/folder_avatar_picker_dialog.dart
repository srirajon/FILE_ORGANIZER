import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/folder_contact.dart';
import '../theme/app_theme.dart';

class AvatarPickerResult {
  final String? customImagePath;
  final String avatarEmoji;
  final Color avatarBgColor;

  AvatarPickerResult({
    this.customImagePath,
    required this.avatarEmoji,
    required this.avatarBgColor,
  });
}

class FolderAvatarPickerDialog extends StatefulWidget {
  final String? initialImagePath;
  final String initialEmoji;
  final Color initialColor;
  final String title;

  const FolderAvatarPickerDialog({
    super.key,
    this.initialImagePath,
    required this.initialEmoji,
    required this.initialColor,
    this.title = 'Choose Folder Photo & Icon',
  });

  /// Static helper to show dialog and return AvatarPickerResult
  static Future<AvatarPickerResult?> show(
    BuildContext context, {
    String? initialImagePath,
    required String initialEmoji,
    required Color initialColor,
    String title = 'Choose Folder Photo & Icon',
  }) {
    return showDialog<AvatarPickerResult>(
      context: context,
      builder: (ctx) => FolderAvatarPickerDialog(
        initialImagePath: initialImagePath,
        initialEmoji: initialEmoji,
        initialColor: initialColor,
        title: title,
      ),
    );
  }

  @override
  State<FolderAvatarPickerDialog> createState() => _FolderAvatarPickerDialogState();
}

class _FolderAvatarPickerDialogState extends State<FolderAvatarPickerDialog> with SingleTickerProviderStateMixin {
  String? _customImagePath;
  late String _selectedEmoji;
  late Color _selectedColor;
  late TabController _tabController;
  final TextEditingController _customEmojiController = TextEditingController();

  static const Map<String, List<String>> _iconCategories = {
    '💼 Work': [
      '💼', '📁', '📊', '📈', '📄', '📑', '🧾', '🏢', '⚖️', '💳',
      '💰', '💵', '🪙', '🖋️', '📝', '📅', '🗂️', '📦', '📬', '🏛️'
    ],
    '🏠 Personal': [
      '🏠', '🏡', '🔑', '🛋️', '🛒', '🛍️', '🎁', '👶', '🐕', '🐈',
      '🪴', '🍽️', '🚗', '🛵', '🚲', '⛽', '🏖️', '🌴', '✈️', '🗺️'
    ],
    '🤖 Tech': [
      '💻', '📱', '🖥️', '🤖', '💡', '📸', '🎥', '🎧', '🎵', '🎙️',
      '🎮', '🕹️', '🔌', '💾', '📡', '🌐', '🚀', '⚙️', '🔧', '🎨'
    ],
    '🏥 Health': [
      '🏥', '💊', '🩺', '💉', '🧬', '🩹', '🍏', '🧘', '🏋️', '🏃',
      '🦷', '👁️', '🚑', '🥗', '❤️', '🩺'
    ],
    '📚 Study': [
      '📚', '🎓', '📖', '✏️', '📐', '🔬', '🔭', '✍️', '📌', '🏷️',
      '🔍', '🧠', '📋', '💡', '🧪', '🔖'
    ],
    '⭐ Badges': [
      '⭐', '🌟', '🔥', '⚡', '💎', '🎯', '🔒', '🛡️', '🔔', '✉️',
      '💬', '💭', '🚩', '🏆', '🎉', '✨', '👑', '🌈'
    ],
  };

  static const List<Color> _colorPalette = [
    Color(0xFF00897B), // Teal (WhatsApp style)
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFB8C00), // Amber
    Color(0xFFE53935), // Red
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
    Color(0xFF3949AB), // Indigo
    Color(0xFFD81B60), // Pink
    Color(0xFFF4511E), // Deep Orange
    Color(0xFF546E7A), // Blue Grey
    Color(0xFF263238), // Dark Slate
  ];

  @override
  void initState() {
    super.initState();
    _customImagePath = widget.initialImagePath;
    _selectedEmoji = widget.initialEmoji;
    _selectedColor = widget.initialColor;
    _tabController = TabController(length: _iconCategories.keys.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customEmojiController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotoFromMobile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final sourceFile = File(result.files.first.path!);
        if (await sourceFile.exists()) {
          // Persist photo safely into app's local document directory
          final docsDir = await getApplicationDocumentsDirectory();
          final avatarsDir = Directory('${docsDir.path}/folder_avatars');
          if (!await avatarsDir.exists()) {
            await avatarsDir.create(recursive: true);
          }
          final ext = sourceFile.path.split('.').last;
          final targetPath = '${avatarsDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
          await sourceFile.copy(targetPath);

          setState(() {
            _customImagePath = targetPath;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking mobile photo for folder avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load photo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _customImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = _customImagePath != null &&
        _customImagePath!.isNotEmpty &&
        !kIsWeb &&
        File(_customImagePath!).existsSync();

    return AlertDialog(
      backgroundColor: isDark ? WhatsAppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Row(
        children: [
          const Icon(Icons.add_photo_alternate_rounded, color: WhatsAppTheme.accentGreen, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Live Preview Circle
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedColor.withOpacity(0.9),
                        border: Border.all(color: WhatsAppTheme.accentGreen, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: hasPhoto
                          ? ClipOval(
                              child: Image.file(
                                File(_customImagePath!),
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                _selectedEmoji,
                                style: const TextStyle(fontSize: 34),
                              ),
                            ),
                    ),
                    if (hasPhoto)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: WhatsAppTheme.accentGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Mobile Photo Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WhatsAppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: Text(
                      hasPhoto ? 'Change Mobile Photo' : 'Choose Mobile Photo',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _pickPhotoFromMobile,
                  ),
                  if (hasPhoto) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Remove Photo', style: TextStyle(fontSize: 11.5)),
                      onPressed: _removePhoto,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Or choose from extensive icon catalog
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  hasPhoto
                      ? 'Fallback Icon & Background Color:'
                      : 'Choose From Icon Library:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),

              // Category Tabs
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2A32) : const Color(0xFFE9EDEF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: WhatsAppTheme.accentGreen,
                  unselectedLabelColor: WhatsAppTheme.darkTextSecondary,
                  indicatorColor: WhatsAppTheme.accentGreen,
                  indicatorWeight: 2.5,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                  tabs: _iconCategories.keys
                      .map((cat) => Tab(text: cat))
                      .toList(),
                ),
              ),

              const SizedBox(height: 8),

              // Category Emojis Grid
              SizedBox(
                height: 140,
                child: TabBarView(
                  controller: _tabController,
                  children: _iconCategories.values.map((emojis) {
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: emojis.length,
                      itemBuilder: (ctx, idx) {
                        final e = emojis[idx];
                        final isSel = (!hasPhoto && _selectedEmoji == e);
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              _selectedEmoji = e;
                              _customImagePath = null; // Reverting to icon
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSel
                                  ? WhatsAppTheme.accentGreen.withOpacity(0.25)
                                  : (isDark ? const Color(0xFF182229) : const Color(0xFFF0F2F5)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? WhatsAppTheme.accentGreen : Colors.transparent,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // Custom emoji / keyboard text input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customEmojiController,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        isDense: true,
                        counterText: '',
                        hintText: 'Type any custom emoji (e.g. 🏎️)',
                        hintStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() {
                            _selectedEmoji = val.trim();
                            _customImagePath = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Choose Background Color
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Avatar Background Color:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorPalette.map((c) {
                  final isSel = _selectedColor == c;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: c.withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: isSel
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: WhatsAppTheme.accentGreen,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(
              context,
              AvatarPickerResult(
                customImagePath: _customImagePath,
                avatarEmoji: _selectedEmoji,
                avatarBgColor: _selectedColor,
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

