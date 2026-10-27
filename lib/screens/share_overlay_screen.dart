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
  final List<SharedFileItem> initialFiles;
  final List<FolderContact> folders;
  final VoidCallback onDismiss;

  ShareOverlayScreen({
    super.key,
    List<SharedFileItem>? initialFiles,
    SharedFileItem? initialFile,
    required this.folders,
    required this.onDismiss,
  }) : initialFiles = initialFiles ?? (initialFile != null ? [initialFile] : []);

  SharedFileItem get initialFile => initialFiles.isNotEmpty
      ? initialFiles.first
      : SharedFileItem(
          id: 'empty',
          fileName: 'Shared File',
          fileSizeBytes: 0,
          mimeType: 'application/octet-stream',
          sharedAt: DateTime.now(),
          category: FileCategory.other,
        );

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

    // If initial files already had captions or tags (e.g. forwarded or markdown)
    for (final f in widget.initialFiles) {
      if (f.caption != null && f.caption!.isNotEmpty && _captionController.text.isEmpty) {
        _captionController.text = f.caption!;
      }
      for (final t in f.tags) {
        if (!_tags.contains(t)) _tags.add(t);
      }
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
        ? SharedFileItem.formatMultilineText(_captionController.text.trim())
        : null;

    final cleanFiles = <SharedFileItem>[];

    for (int i = 0; i < widget.initialFiles.length; i++) {
      final sourceFile = widget.initialFiles[i];
      // Persist physical file / Markdown note into public phone vault:
      // Internal Storage > Download > FileOrganizer > [FolderName] > [FileName]
      String persistedPath = sourceFile.filePath ?? '';
      try {
        persistedPath = await BackupService().persistFileToFolder(
          folderName: _selectedFolder!.name,
          fileName: sourceFile.fileName,
          sourcePath: sourceFile.filePath,
          rawContent: sourceFile.rawContent,
        );
      } catch (_) {}

      cleanFiles.add(
        SharedFileItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          fileName: sourceFile.fileName,
          filePath: persistedPath.isNotEmpty ? persistedPath : sourceFile.filePath,
          fileSizeBytes: sourceFile.fileSizeBytes,
          mimeType: sourceFile.mimeType,
          sharedAt: DateTime.now(),
          category: sourceFile.category,
          caption: customCaption,
          note: customCaption,
          tags: List<String>.from(_tags),
          rawContent: sourceFile.rawContent,
          isPinned: false,
        ),
      );
    }

    setState(() {
      _selectedFolder!.files.insertAll(0, cleanFiles);
      _selectedFolder!.unreadOrNewCount += cleanFiles.length;
      _selectedFolder!.lastTimestamp = 'Just now';
    });

    // Save to folders_config.json
    await _configService.saveFolders();

    if (!mounted) return;

    final msg = cleanFiles.length == 1
        ? 'File sorted into "${_selectedFolder!.name}"'
        : '${cleanFiles.length} files sorted into "${_selectedFolder!.name}"';

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
                msg,
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
                      if (!widget.folders.contains(created)) {
                        widget.folders.insert(0, created);
                      }
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
              // Intercepted File Preview Bar: Single file or Multi-file carousel
              if (widget.initialFiles.length <= 1)
                InterceptedFileCard(
                  file: widget.initialFile,
                  onDismiss: widget.onDismiss,
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2A32) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: WhatsAppTheme.accentGreen.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: WhatsAppTheme.accentGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${widget.initialFiles.length} FILES SELECTED',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: WhatsAppTheme.accentGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTotalSize(widget.initialFiles),
                            style: const TextStyle(fontSize: 11.5, color: WhatsAppTheme.darkTextSecondary),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: WhatsAppTheme.darkTextSecondary,
                            onPressed: widget.onDismiss,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Cancel share',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.initialFiles.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final f = widget.initialFiles[i];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2A3942) : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF374248) : const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getFileIcon(f.category), size: 16, color: WhatsAppTheme.accentGreen),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 130),
                                    child: Text(
                                      f.fileName,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Level 5 (v1.3): Tagging & Caption Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2A32) : const Color(0xFFF7F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: WhatsAppTheme.accentGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Caption Field (Enables Future Search, preserves newlines)
                    TextField(
                      controller: _captionController,
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
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

  String _formatTotalSize(List<SharedFileItem> files) {
    int total = 0;
    for (final f in files) {
      total += f.fileSizeBytes;
    }
    if (total < 1024) return '$total B';
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(1)} KB';
    return '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(FileCategory category) {
    switch (category) {
      case FileCategory.markdown:
        return Icons.article_rounded;
      case FileCategory.document:
        return Icons.picture_as_pdf_rounded;
      case FileCategory.image:
        return Icons.photo_library_rounded;
      case FileCategory.video:
        return Icons.videocam_rounded;
      case FileCategory.audio:
        return Icons.mic_rounded;
      case FileCategory.archive:
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
