import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/folder_contact.dart';
import '../models/shared_file_item.dart';
import '../services/file_opener_service.dart';
import '../services/folder_config_service.dart';
import '../theme/app_theme.dart';
import '../widgets/folder_avatar.dart';
import '../widgets/folder_avatar_picker_dialog.dart';
import 'chat_media_screen.dart';
import 'share_overlay_screen.dart';

class FolderChatScreen extends StatefulWidget {
  final FolderContact folder;
  final Function(FolderContact)? onFolderUpdated;

  const FolderChatScreen({
    super.key,
    required this.folder,
    this.onFolderUpdated,
  });

  @override
  State<FolderChatScreen> createState() => _FolderChatScreenState();
}

class _FolderChatScreenState extends State<FolderChatScreen> {
  final TextEditingController _noteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FolderConfigService _configService = FolderConfigService();

  @override
  void initState() {
    super.initState();
    widget.folder.unreadOrNewCount = 0;
    _configService.saveFolders();
    // WhatsApp style: open chat view scrolled to bottom where recent messages are
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(maxScroll);
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addQuickUserNote() {
    final raw = _noteController.text;
    if (raw.trim().isEmpty) return;
    final sanitized = SharedFileItem.formatMultilineText(raw);
    _noteController.clear();

    final lines = sanitized.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final firstLine = lines.isNotEmpty ? lines.first.trim() : 'Note';
    final title = firstLine.length <= 40 ? firstLine : '${firstLine.substring(0, 37)}...';

    setState(() {
      widget.folder.files.add(
        SharedFileItem(
          id: 'note_${DateTime.now().millisecondsSinceEpoch}',
          fileName: title,
          filePath: null,
          fileSizeBytes: sanitized.codeUnits.length,
          mimeType: 'text/plain',
          sharedAt: DateTime.now(),
          category: FileCategory.document,
          note: sanitized,
          rawContent: sanitized,
        ),
      );
      widget.folder.lastTimestamp = widget.folder.formattedLastTimestamp;
    });

    _configService.sortFoldersByRecentActivity();
    _configService.saveFolders();
    _scrollToBottom(animate: true);
  }

  /// Level 3 & 6: Paste copied text from Facebook, AI, or clipboard preserving formatting
  Future<void> _pasteAiTextAsMarkdown() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final rawText = clipboardData?.text;

    if (rawText == null || rawText.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard is empty! Copy text from Facebook, ChatGPT, Claude, or Gemini first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final text = SharedFileItem.formatMultilineText(rawText);
    if (!mounted) return;

    // Show preview dialog to confirm or edit title
    final autoFile = SharedFileItem.createMarkdownFromAiText(text: text);
    final titleController = TextEditingController(text: autoFile.fileName.replaceAll('.md', ''));

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? WhatsAppTheme.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.content_paste_rounded, color: WhatsAppTheme.accentGreen),
              SizedBox(width: 10),
              Text('Save Copied Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Copied text detected! Save directly as a formatted text message bubble or export as a Markdown (.md) file.',
                  style: TextStyle(fontSize: 12.5, color: WhatsAppTheme.darkTextSecondary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(maxHeight: 140),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141E24) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A3942) : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isDark ? WhatsAppTheme.darkTextPrimary : const Color(0xFF111B21),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${text.length} characters • ${text.split(RegExp(r'\s+')).length} words • ${text.split('\n').length} paragraphs',
                  style: const TextStyle(fontSize: 11, color: WhatsAppTheme.darkTextSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Document Name (for .md export)',
                    suffixText: '.md',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: WhatsAppTheme.darkTextSecondary)),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: WhatsAppTheme.accentGreen,
                side: const BorderSide(color: WhatsAppTheme.accentGreen),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
                final firstLine = lines.isNotEmpty ? lines.first.trim() : 'Note';
                final noteTitle = firstLine.length <= 40 ? firstLine : '${firstLine.substring(0, 37)}...';

                final noteFile = SharedFileItem(
                  id: 'note_${DateTime.now().millisecondsSinceEpoch}',
                  fileName: noteTitle,
                  filePath: null,
                  fileSizeBytes: text.codeUnits.length,
                  mimeType: 'text/plain',
                  sharedAt: DateTime.now(),
                  category: FileCategory.document,
                  note: text,
                  rawContent: text,
                );

                setState(() {
                  widget.folder.files.add(noteFile);
                  widget.folder.lastTimestamp = widget.folder.formattedLastTimestamp;
                });

                _configService.sortFoldersByRecentActivity();
                _configService.saveFolders();
                _scrollToBottom(animate: true);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: WhatsAppTheme.accentGreen,
                    content: Text('✓ Saved as formatted message bubble'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save as Message'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: WhatsAppTheme.accentGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                final name = titleController.text.trim();
                final finalMdFile = SharedFileItem.createMarkdownFromAiText(
                  text: text,
                  customTitle: name.isNotEmpty ? name : null,
                );

                setState(() {
                  widget.folder.files.add(finalMdFile);
                  widget.folder.lastTimestamp = widget.folder.formattedLastTimestamp;
                });

                _configService.sortFoldersByRecentActivity();
                _configService.saveFolders();
                _scrollToBottom(animate: true);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: WhatsAppTheme.accentGreen,
                    content: Text('✓ Saved as "${finalMdFile.fileName}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Save as .md', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// Level 3: Markdown Reader Sheet to view full .md document directly
  void _openMarkdownReader(SharedFileItem file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MarkdownReaderSheet(file: file),
    );
  }

  /// Level 3: Toggle Pin status
  void _togglePin(SharedFileItem file) {
    setState(() {
      file.isPinned = !file.isPinned;
    });
    _configService.saveFolders();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: WhatsAppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        content: Text(file.isPinned ? '📌 File pinned to top' : 'Unpinned'),
      ),
    );
  }

  /// Level 3: Forward file to another folder contact
  void _forwardFile(SharedFileItem file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.90,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: ShareOverlayScreen(
              initialFile: file,
              folders: _configService.folders,
              onDismiss: () {
                Navigator.of(ctx).pop();
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  /// Message context menu on long press
  void _showMessageOptions(SharedFileItem file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? WhatsAppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded, color: WhatsAppTheme.accentGreen),
                  title: const Text('Open with App (Show All Apps)'),
                  subtitle: Text(
                    'Choose from all installed viewers (Acrobat, Drive, Office, VLC, etc.)',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    FileOpenerService.openFile(context: context, file: file);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded, color: WhatsAppTheme.accentGreen),
                  title: Text(
                    file.isTextNote
                        ? 'Edit Text Note'
                        : (file.displayCaption != null && file.displayCaption!.isNotEmpty
                            ? 'Edit Caption & Tags'
                            : 'Add Caption & Tags'),
                  ),
                  subtitle: Text(
                    file.isTextNote
                        ? 'Modify text content, paragraphs & tags'
                        : 'Edit caption & tags to enable search',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showEditCaptionDialog(file);
                  },
                ),
                ListTile(
                  leading: Icon(
                    file.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                    color: WhatsAppTheme.accentGreen,
                  ),
                  title: Text(file.isPinned ? 'Unpin from Top' : 'Pin to Top'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _togglePin(file);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.forward_rounded, color: Color(0xFF4285F4)),
                  title: const Text('Forward to Another Folder'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _forwardFile(file);
                  },
                ),
                if (file.isMarkdown)
                  ListTile(
                    leading: const Icon(Icons.chrome_reader_mode_rounded, color: Color(0xFFFB8C00)),
                    title: const Text('Read Markdown Document'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openMarkdownReader(file);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete from Folder', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      widget.folder.files.removeWhere((f) => f.id == file.id);
                    });
                    _configService.saveFolders();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Level 6 (Feature 6): Long press to edit / add caption and tags for each file or text note
  void _showEditCaptionDialog(SharedFileItem file) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final captionController = TextEditingController(
      text: file.isTextNote ? (file.rawContent ?? file.displayCaption ?? '') : (file.displayCaption ?? ''),
    );
    final tagInputController = TextEditingController();
    final localTags = List<String>.from(file.tags);
    final suggestedTags = ['#work', '#receipt', '#tax', '#important', '#bill', '#personal', '#id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setSheetState) {
            void addTag(String raw) {
              var trimmed = raw.trim();
              if (trimmed.isEmpty) return;
              if (!trimmed.startsWith('#')) trimmed = '#$trimmed';
              if (!localTags.contains(trimmed)) {
                setSheetState(() => localTags.add(trimmed));
              }
              tagInputController.clear();
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? WhatsAppTheme.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            file.isTextNote ? Icons.edit_rounded : Icons.edit_note_rounded,
                            color: WhatsAppTheme.accentGreen,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              file.isTextNote
                                  ? 'Edit Text Note'
                                  : (file.displayCaption != null && file.displayCaption!.isNotEmpty
                                      ? 'Edit Caption'
                                      : 'Add Caption'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: captionController,
                        keyboardType: TextInputType.multiline,
                        minLines: 3,
                        maxLines: 8,
                        textInputAction: TextInputAction.newline,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark ? WhatsAppTheme.darkTextPrimary : const Color(0xFF111B21),
                        ),
                        decoration: InputDecoration(
                          hintText: file.isTextNote
                              ? 'Enter or paste formatted note text...'
                              : 'Add a descriptive caption for future search...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? WhatsAppTheme.darkTextSecondary : Colors.grey.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: WhatsAppTheme.accentGreen.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: WhatsAppTheme.accentGreen, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.tag_rounded, size: 18, color: WhatsAppTheme.accentGreen),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: tagInputController,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? WhatsAppTheme.darkTextPrimary : const Color(0xFF111B21),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Add tag (e.g. #receipt, #tax)',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? WhatsAppTheme.darkTextSecondary : Colors.grey.shade600,
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: addTag,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: WhatsAppTheme.accentGreen, size: 22),
                            onPressed: () => addTag(tagInputController.text),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...localTags.map(
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
                                    onTap: () => setSheetState(() => localTags.remove(t)),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ...suggestedTags.where((s) => !localTags.contains(s)).take(4).map(
                            (s) => InkWell(
                              onTap: () => setSheetState(() => localTags.add(s)),
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
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(bottomSheetCtx).pop(),
                            child: const Text('Cancel', style: TextStyle(color: WhatsAppTheme.darkTextSecondary)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WhatsAppTheme.accentGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final newText = captionController.text.trim();
                              setState(() {
                                if (file.isTextNote) {
                                  file.updateRawContent(newText);
                                } else {
                                  file.updateCaption(newText);
                                }
                                file.updateTags(localTags);
                              });
                              _configService.saveFolders();
                              Navigator.of(bottomSheetCtx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: WhatsAppTheme.accentGreen,
                                  content: Text(file.isTextNote ? '✓ Note updated' : '✓ Caption updated'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  void _confirmDeleteFolder() {
    bool deletePhysical = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Expanded(child: Text('Delete Folder Contact?')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${widget.folder.name}" along with all its ${widget.folder.files.length} items?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: deletePhysical,
                onChanged: (val) => setDialogState(() => deletePhysical = val ?? true),
                title: const Text('Also delete files from phone storage', style: TextStyle(fontSize: 13)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                activeColor: Colors.red,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _configService.deleteFolder(
                  widget.folder.id,
                  deletePhysicalFiles: deletePhysical,
                );
                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditFolderAvatarDialog() async {
    final res = await FolderAvatarPickerDialog.show(
      context,
      initialImagePath: widget.folder.customImagePath,
      initialEmoji: widget.folder.avatarEmoji,
      initialColor: widget.folder.avatarBgColor,
      title: 'Edit "${widget.folder.name}" Photo & Icon',
    );
    if (res != null) {
      await _configService.updateFolderAvatar(
        folderId: widget.folder.id,
        customImagePath: res.customImagePath,
        avatarEmoji: res.avatarEmoji,
        avatarBgColor: res.avatarBgColor,
      );
      setState(() {});
      if (widget.onFolderUpdated != null) {
        widget.onFolderUpdated!(widget.folder);
      }
    }
  }

  bool _shouldShowDateBadge(int index, List<SharedFileItem> list) {
    if (index == 0) return true;
    final curr = list[index].sharedAt;
    final prev = list[index - 1].sharedAt;
    return curr.year != prev.year || curr.month != prev.month || curr.day != prev.day;
  }

  Widget _buildDateBadge(DateTime date, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(msgDate).inDays;

    String label;
    if (diffDays == 0) {
      label = 'Today';
    } else if (diffDays == 1) {
      label = 'Yesterday';
    } else if (diffDays < 7 && diffDays > 1) {
      label = DateFormat('EEEE').format(date);
    } else if (date.year == now.year) {
      label = DateFormat('MMMM d').format(date);
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF182229) : const Color(0xFFE9EDEF),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? WhatsAppTheme.darkTextSecondary : const Color(0xFF54656F),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinned = widget.folder.pinnedFiles;

    return Scaffold(
      backgroundColor: isDark ? WhatsAppTheme.chatBgDark : WhatsAppTheme.chatBgLight,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: InkWell(
          onTap: _showEditFolderAvatarDialog,
          child: Row(
            children: [
              FolderAvatar(
                folder: widget.folder,
                size: 38,
                fontSize: 18,
                showShadow: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.folder.name,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.folder.files.length} items • Active folder',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? WhatsAppTheme.darkTextSecondary : Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'Paste AI text as .md file',
            onPressed: _pasteAiTextAsMarkdown,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Folder options',
            onSelected: (value) {
              switch (value) {
                case 'edit_avatar':
                  _showEditFolderAvatarDialog();
                  break;
                case 'media_docs':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatMediaScreen(folder: widget.folder),
                    ),
                  );
                  break;
                case 'paste_ai':
                  _pasteAiTextAsMarkdown();
                  break;
                case 'clear_chat':
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear all files?'),
                      content: Text('Remove all ${widget.folder.files.length} items from "${widget.folder.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              widget.folder.files.clear();
                            });
                            _configService.saveFolders();
                          },
                          child: const Text('Clear', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  break;
                case 'delete_folder':
                  _confirmDeleteFolder();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit_avatar',
                child: Row(
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, size: 20, color: WhatsAppTheme.accentGreen),
                    SizedBox(width: 10),
                    Text('Edit Photo & Icon'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'media_docs',
                child: Row(
                  children: [
                    Icon(Icons.perm_media_outlined, size: 20, color: WhatsAppTheme.accentGreen),
                    SizedBox(width: 10),
                    Text('Media, docs & notes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'paste_ai',
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_outlined, size: 20, color: WhatsAppTheme.accentGreen),
                    SizedBox(width: 10),
                    Text('Paste AI text as .md'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_chat',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.orange),
                    SizedBox(width: 10),
                    Text('Clear files in chat', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_folder',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete Folder Contact', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned Banner (WhatsApp-style top pinned pill)
          if (pinned.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2A32) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: WhatsAppTheme.accentGreen.withOpacity(0.4), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.push_pin_rounded, color: WhatsAppTheme.accentGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pinned: ${pinned.first.fileName}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (pinned.first.isMarkdown) {
                        _openMarkdownReader(pinned.first);
                      } else {
                        FileOpenerService.openFile(context: context, file: pinned.first);
                      }
                    },
                    child: const Text('OPEN', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: WhatsAppTheme.accentGreen)),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _togglePin(pinned.first),
                    child: const Icon(Icons.close, size: 16, color: WhatsAppTheme.darkTextSecondary),
                  ),
                ],
              ),
            ),

          // Message bubbles list
          Expanded(
            child: widget.folder.files.isEmpty
                ? const Center(
                    child: Text(
                      'No files in this folder yet.\nShare from any app or paste AI text!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: WhatsAppTheme.darkTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      // Chronological sorting: oldest at top, recent downmost (just like WhatsApp)
                      final displayFiles = List<SharedFileItem>.from(widget.folder.files)
                        ..sort((a, b) => a.sharedAt.compareTo(b.sharedAt));

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: false,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        itemCount: displayFiles.length,
                        itemBuilder: (context, index) {
                          final file = displayFiles[index];
                          final showDateHeader = _shouldShowDateBadge(index, displayFiles);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDateHeader)
                                _buildDateBadge(file.sharedAt, isDark),
                              Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onLongPress: () => _showMessageOptions(file),
                          onTap: () {
                            if (file.isMarkdown) {
                              _openMarkdownReader(file);
                            } else {
                              FileOpenerService.openFile(context: context, file: file);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.84,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? WhatsAppTheme.outgoingBubble
                                  : const Color(0xFFD9FDD3),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pinned indicator tag
                                if (file.isPinned) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.push_pin_rounded, size: 13, color: Color(0xFFFFD54F)),
                                      SizedBox(width: 4),
                                      Text(
                                        'PINNED',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFFD54F)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],

                                // Pure Text Message (Copied Facebook post, AI note, or user message)
                                if (file.isTextNote) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
                                    child: SelectableText(
                                      file.rawContent ?? file.displayCaption ?? file.fileName,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        height: 1.45,
                                        color: isDark ? WhatsAppTheme.darkTextPrimary : const Color(0xFF111B21),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // File attachment box
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF0C3832)
                                          : const Color(0xFFC4ECC0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: WhatsAppTheme.accentGreen.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            _getFileIcon(file.category),
                                            color: isDark ? Colors.white : WhatsAppTheme.darkTeal,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                file.fileName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF111B21),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                file.isMarkdown
                                                    ? '${file.formattedSize} • MARKDOWN (Tap to read)'
                                                    : '${file.formattedSize} • ${file.mimeType.split('/').last.toUpperCase()}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (file.isMarkdown)
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: WhatsAppTheme.accentGreen),
                                      ],
                                    ),
                                  ),

                                  // Markdown Content Preview (if markdown has content, show formatted snippet)
                                  if (file.isMarkdown && file.rawContent != null && file.rawContent!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF141E24) : const Color(0xFFF0F4F2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        file.rawContent!,
                                        maxLines: 6,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: isDark ? WhatsAppTheme.darkTextPrimary : const Color(0xFF111B21),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // User Caption if present (Level 5 v1.3)
                                  if (file.displayCaption != null && file.displayCaption!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: SelectableText(
                                        file.displayCaption!,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white : const Color(0xFF111B21),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],

                                // Tags if present (Level 5 v1.3)
                                if (file.tags.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: file.tags.map((tag) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0C3832) : const Color(0xFFD0F0DB),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? WhatsAppTheme.accentGreen : const Color(0xFF1B5E20),
                                          ),
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 4),

                                // Footer: Time, Pin, Checkmark
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Spacer(),
                                    Text(
                                      DateFormat('h:mm a').format(file.sharedAt),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? Colors.white60 : Colors.black45,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.done_all,
                                      size: 15,
                                      color: WhatsAppTheme.blueCheck,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),

          // Bottom Bar with "Paste AI Text as .md" button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: isDark ? WhatsAppTheme.darkSurface : const Color(0xFFF0F2F5),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.content_paste_rounded, color: WhatsAppTheme.accentGreen),
                    tooltip: 'Paste copied text or AI response',
                    onPressed: _pasteAiTextAsMarkdown,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A3942) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _noteController,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 6,
                        textInputAction: TextInputAction.newline,
                        style: TextStyle(
                          color: isDark ? WhatsAppTheme.darkTextPrimary : const Color(0xFF111B21),
                          fontSize: 14.5,
                          height: 1.35,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type message, note, or paste text...',
                          hintStyle: TextStyle(
                            color: WhatsAppTheme.darkTextSecondary,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor: WhatsAppTheme.accentGreen,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _addQuickUserNote,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarkdownReaderSheet extends StatelessWidget {
  final SharedFileItem file;

  const MarkdownReaderSheet({
    super.key,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? WhatsAppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF26A69A).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MD',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF26A69A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          file.fileName,
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  tooltip: 'Open with default app',
                  onPressed: () {
                    FileOpenerService.openFile(context: context, file: file);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy full Markdown',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: file.rawContent ?? file.fileName));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Markdown copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  file.rawContent ?? '# ${file.fileName}\n\n*(Empty document or external file)*',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: isDark ? WhatsAppTheme.darkTextPrimary : const Color(0xFF111B21),
                    fontFamily: file.rawContent != null ? null : 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
