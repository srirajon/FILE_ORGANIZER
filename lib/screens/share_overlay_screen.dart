import 'package:flutter/material.dart';
import '../models/folder_contact.dart';
import '../models/shared_file_item.dart';
import '../services/backup_service.dart';
import '../services/folder_config_service.dart';
import '../theme/app_theme.dart';
import '../widgets/whatsapp_contact_tile.dart';
import '../widgets/intercepted_file_card.dart';
import 'folder_chat_screen.dart';

class ShareOverlayScreen extends StatefulWidget {
  final SharedFileItem initialFile;
  final List<FolderContact> folders;
  final VoidCallback onDismiss;

  const ShareOverlayScreen({
    super.key,
    required this.initialFile,
    required this.folders,
    required this.onDismiss,
  });

  @override
  State<ShareOverlayScreen> createState() => _ShareOverlayScreenState();
}

class _ShareOverlayScreenState extends State<ShareOverlayScreen> with SingleTickerProviderStateMixin {
  FolderContact? _selectedFolder;
  String _searchQuery = '';
  late AnimationController _sendAnimController;
  late Animation<double> _scaleAnimation;
  bool _isSending = false;
  final FolderConfigService _configService = FolderConfigService();

  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagInputController = TextEditingController();
  final List<String> _tags = [];
  final List<String> _suggestedTags = ['#work', '#receipt', '#tax', '#important', '#bill', '#personal', '#id'];

  @override
  void initState() {
    super.initState();
    _sendAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _sendAnimController,
      curve: Curves.easeOutBack,
    );

    // If initialFile already had a caption or tags (e.g. forwarded or markdown)
    if (widget.initialFile.caption != null) {
      _captionController.text = widget.initialFile.caption!;
    }
    if (widget.initialFile.tags.isNotEmpty) {
      _tags.addAll(widget.initialFile.tags);
    }
  }

  @override
  void dispose() {
    _sendAnimController.dispose();
    _captionController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag(String rawTag) {
    var trimmed = rawTag.trim();
    if (trimmed.isEmpty) return;
    if (!trimmed.startsWith('#')) {
      trimmed = '#$trimmed';
    }
    if (!_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
      });
    }
    _tagInputController.clear();
  }

  void _onFolderTapped(FolderContact folder) {
    setState(() {
      if (_selectedFolder?.id == folder.id) {
        _selectedFolder = null;
        _sendAnimController.reverse();
      } else {
        _selectedFolder = folder;
        _sendAnimController.forward();
      }
    });
  }

  Future<void> _sendToSelectedFolder() async {
    if (_selectedFolder == null || _isSending) return;

    setState(() {
      _isSending = true;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    final customCaption = _captionController.text.trim().isNotEmpty
        ? _captionController.text.trim()
        : null;

    // Persist physical file / Markdown note into public phone vault:
    // Internal Storage > Download > FileOrganizer > [FolderName] > [FileName]
    String persistedPath = widget.initialFile.filePath ?? '';
    try {
      persistedPath = await BackupService().persistFileToFolder(
        folderName: _selectedFolder!.name,
        fileName: widget.initialFile.fileName,
        sourcePath: widget.initialFile.filePath,
        rawContent: widget.initialFile.rawContent,
      );
    } catch (_) {}

    // File with user caption and tags; strictly no auto-text
    final cleanFile = SharedFileItem(
      id: widget.initialFile.id,
      fileName: widget.initialFile.fileName,
      filePath: persistedPath.isNotEmpty ? persistedPath : widget.initialFile.filePath,
      fileSizeBytes: widget.initialFile.fileSizeBytes,
      mimeType: widget.initialFile.mimeType,
      sharedAt: DateTime.now(),
      category: widget.initialFile.category,
      caption: customCaption,
      note: customCaption,
      tags: List<String>.from(_tags),
      rawContent: widget.initialFile.rawContent,
      isPinned: false,
    );

    setState(() {
      _selectedFolder!.files.insert(0, cleanFile);
      _selectedFolder!.unreadOrNewCount += 1;
      _selectedFolder!.lastTimestamp = 'Just now';
    });

    // Save to folders_config.json
    await _configService.saveFolders();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: WhatsAppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'File sorted into "${_selectedFolder!.name}"',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    final targetFolder = _selectedFolder!;
    widget.onDismiss();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FolderChatScreen(folder: targetFolder),
      ),
    );
  }

  void _showCreateFolderDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedEmoji = '📁';
    Color selectedColor = const Color(0xFF1E88E5);

    final emojiList = ['📁', '💼', '🧾', '📸', '💡', '🏥', '🏢', '🚗', '🎓', '💰', '🛒', '✈️', '📄', '⚡'];
    final colorList = [
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF43A047), // Green
      const Color(0xFFE53935), // Red
      const Color(0xFFFB8C00), // Amber
      const Color(0xFF8E24AA), // Purple
      const Color(0xFF00ACC1), // Cyan
      const Color(0xFF5E35B1), // Indigo
      const Color(0xFFD81B60), // Pink
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? WhatsAppTheme.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('New Folder Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Folder Name',
                        hintText: 'e.g. Utility Bills, Client X',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'e.g. Monthly invoices & statements',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Choose Icon / Emoji:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: emojiList.map((e) {
                        final isSel = selectedEmoji == e;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedEmoji = e),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSel ? WhatsAppTheme.accentGreen.withOpacity(0.25) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? WhatsAppTheme.accentGreen : Colors.grey.withOpacity(0.3),
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(e, style: const TextStyle(fontSize: 18)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('Choose Color:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: colorList.map((c) {
                        final isSel = selectedColor == c;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: isSel ? Border.all(color: Colors.white, width: 3) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: WhatsAppTheme.darkTextSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WhatsAppTheme.accentGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    Navigator.of(ctx).pop();

                    final created = await _configService.addFolder(
                      name: name,
                      description: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : 'Custom folder',
                      avatarEmoji: selectedEmoji,
                      avatarBgColor: selectedColor,
                    );

                    setState(() {
                      widget.folders.insert(0, created);
                      _selectedFolder = created;
                      _sendAnimController.forward();
                    });
                  },
                  child: const Text('Create & Select', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredFolders = widget.folders.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onDismiss,
          tooltip: 'Cancel share',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send to...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'Select a Folder Contact',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? WhatsAppTheme.darkTextSecondary : Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Add new folder contact',
            onPressed: _showCreateFolderDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Intercepted File Preview Bar
              InterceptedFileCard(
                file: widget.initialFile,
                onDismiss: widget.onDismiss,
              ),

              // Level 5 (v1.3): Tagging & Caption Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2A32) : const Color(0xFFF7F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: WhatsAppTheme.accentGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Caption Field (Enables Future Search)
                    TextField(
                      controller: _captionController,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? WhatsAppTheme.darkTextPrimary : const Color(0xFF111B21),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: WhatsAppTheme.accentGreen),
                        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 20),
                        hintText: 'Add a caption... (enables future search)',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? WhatsAppTheme.darkTextSecondary : Colors.grey.shade600,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                    const Divider(height: 10, thickness: 0.5),

                    // Tag Input Field
                    Row(
                      children: [
                        const Icon(Icons.tag_rounded, size: 18, color: WhatsAppTheme.accentGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _tagInputController,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? WhatsAppTheme.darkTextPrimary : const Color(0xFF111B21),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Add tag (e.g. #receipt, #taxes)',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: isDark ? WhatsAppTheme.darkTextSecondary : Colors.grey.shade600,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            onSubmitted: _addTag,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: WhatsAppTheme.accentGreen, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _addTag(_tagInputController.text),
                          tooltip: 'Add tag',
                        ),
                      ],
                    ),

                    // Tag Chips & Suggested Presets
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Active user-selected tags
                        ..._tags.map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: WhatsAppTheme.accentGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  t,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => setState(() => _tags.remove(t)),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Suggested quick tags
                        ..._suggestedTags.where((s) => !_tags.contains(s)).take(5).map(
                          (s) => InkWell(
                            onTap: () => setState(() => _tags.add(s)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2A3942) : const Color(0xFFE9EDEF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? WhatsAppTheme.darkTextSecondary : const Color(0xFF54656F),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // "+ New Folder" Quick Action Row right above the list
              InkWell(
                onTap: _showCreateFolderDialog,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: WhatsAppTheme.accentGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'New Folder Contact',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: WhatsAppTheme.accentGreen,
                              ),
                            ),
                            Text(
                              'Create a new destination folder for this file',
                              style: TextStyle(
                                fontSize: 12,
                                color: WhatsAppTheme.darkTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Divider(
                height: 1,
                thickness: 0.8,
                color: isDark ? const Color(0xFF222D34) : const Color(0xFFE9EDEF),
              ),

              // Section Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EXISTING FOLDERS',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark ? WhatsAppTheme.darkTextSecondary : const Color(0xFF54656F),
                      ),
                    ),
                    Text(
                      '${filteredFolders.length} contacts',
                      style: const TextStyle(
                        fontSize: 12,
                        color: WhatsAppTheme.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // WhatsApp Contact List
              Expanded(
                child: ListView.separated(
                  itemCount: filteredFolders.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.8,
                    indent: 82,
                    color: isDark ? const Color(0xFF222D34) : const Color(0xFFE9EDEF),
                  ),
                  itemBuilder: (context, index) {
                    final folder = filteredFolders[index];
                    final isSelected = _selectedFolder?.id == folder.id;

                    return WhatsAppContactTile(
                      folder: folder,
                      isSelected: isSelected,
                      isSelectable: true,
                      onTap: () => _onFolderTapped(folder),
                    );
                  },
                ),
              ),
            ],
          ),

          // Floating WhatsApp Send Button when a folder is selected
          Positioned(
            right: 20,
            bottom: 24,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FloatingActionButton.extended(
                onPressed: _isSending ? null : _sendToSelectedFolder,
                backgroundColor: WhatsAppTheme.accentGreen,
                elevation: 4,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  _selectedFolder != null ? 'Save to ${_selectedFolder!.name}' : 'Send',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
