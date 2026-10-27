import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/folder_contact.dart';
import '../models/shared_file_item.dart';
import '../services/backup_service.dart';
import '../services/folder_config_service.dart';
import '../services/share_intent_service.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/whatsapp_contact_tile.dart';
import 'central_search_screen.dart';
import 'folder_chat_screen.dart';
import 'share_overlay_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FolderContact> _folders = [];
  bool _isLoading = true;
  final FolderConfigService _configService = FolderConfigService();
  final BackupService _backupService = BackupService();
  final ShareIntentService _shareService = ShareIntentService();
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);

    _loadConfiguredFolders();

    // Initialize Share Intent Service
    _shareService.initialize(
      onIncomingFiles: (files) {
        _openShareOverlayForFiles(files);
      },
      onIncomingFile: (sharedFile) {
        _openShareOverlay(sharedFile);
      },
    );
  }

  Future<void> _loadConfiguredFolders() async {
    final loaded = await _configService.loadFolders();
    setState(() {
      _folders = loaded;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openShareOverlay(SharedFileItem file) {
    _openShareOverlayForFiles([file]);
  }

  void _openShareOverlayForFiles(List<SharedFileItem> files) {
    if (files.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.90,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: ShareOverlayScreen(
              initialFiles: files,
              folders: _folders,
              onDismiss: () {
                Navigator.of(context).pop();
                _shareService.clearPendingFiles();
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  /// Level 5 (v1.3): Top action picks real files from device storage to sort into folders
  Future<void> _pickFilesFromStorage() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isNotEmpty) {
        final items = <SharedFileItem>[];
        for (int i = 0; i < files.length; i++) {
          final platformFile = files[i];
          if (platformFile.path != null) {
            int sizeBytes = platformFile.lengthSync() ?? 0;
            if (sizeBytes == 0) {
              try {
                sizeBytes = File(platformFile.path!).lengthSync();
              } catch (_) {}
            }
            final category = SharedFileItem.detectCategory(platformFile.name, '');
            items.add(
              SharedFileItem(
                id: 'file_${DateTime.now().millisecondsSinceEpoch}_$i',
                fileName: platformFile.name,
                filePath: platformFile.path,
                fileSizeBytes: sizeBytes,
                mimeType: 'application/octet-stream',
                sharedAt: DateTime.now(),
                category: category,
              ),
            );
          }
        }
        if (items.isNotEmpty && mounted) {
          _openShareOverlayForFiles(items);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file from storage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _triggerSimulatedShare() {
    final sampleFiles = [
      {'name': 'Monthly_Payslip_DESCO.pdf', 'size': 420000, 'mime': 'application/pdf'},
      {'name': 'Site_Inspection_Photo_01.jpg', 'size': 3200000, 'mime': 'image/jpeg'},
      {'name': 'Project_Budget_2026.xlsx', 'size': 780000, 'mime': 'application/vnd.ms-excel'},
      {'name': 'Client_Meeting_Audio.m4a', 'size': 2100000, 'mime': 'audio/mp4'},
    ];
    final sample = sampleFiles[(DateTime.now().second) % sampleFiles.length];

    _shareService.simulateIncomingShare(
      fileName: sample['name'] as String,
      sizeBytes: sample['size'] as int,
      mimeType: sample['mime'] as String,
      note: null,
    );
  }

  void _showNewFolderDialog() {
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
              title: const Text('Add New Folder Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                        hintText: 'e.g. Electric Vehicle, Project Alpha',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g. Invoices, documents, notes',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Choose Icon:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

                    final newF = await _configService.addFolder(
                      name: name,
                      description: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : 'Custom folder',
                      avatarEmoji: selectedEmoji,
                      avatarBgColor: selectedColor,
                    );

                    setState(() {
                      _folders = _configService.folders;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: WhatsAppTheme.accentGreen,
                        content: Text('Folder "${newF.name}" created & saved to folders_config.json'),
                      ),
                    );
                  },
                  child: const Text('Create Folder', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Level 5 (v1.3): Long press options to delete folder contact and contents
  void _showFolderLongPressOptions(FolderContact folder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: folder.avatarBgColor,
                  child: Text(folder.avatarEmoji, style: const TextStyle(fontSize: 18)),
                ),
                title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${folder.files.length} items • ${folder.description}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded, color: WhatsAppTheme.accentGreen),
                title: const Text('Open Folder Chat'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FolderChatScreen(folder: folder)),
                  ).then((_) => setState(() {}));
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload_outlined, color: WhatsAppTheme.accentGreen),
                title: const Text('Add Files to this Folder'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFilesFromStorage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: const Text('Delete Folder Contact & Contents', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                subtitle: const Text('Deletes chat head, config entry, and all files'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteFolder(folder);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Confirmation dialog for deleting folder contact and its files
  void _confirmDeleteFolder(FolderContact folder) {
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
                'Are you sure you want to delete "${folder.name}" along with all its ${folder.files.length} items?',
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
                await _configService.deleteFolder(folder.id, deletePhysicalFiles: deletePhysical);
                setState(() {
                  _folders = _configService.folders;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red.shade700,
                      content: Text('Deleted "${folder.name}" and all contents.'),
                    ),
                  );
                }
              },
              child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Level 5 (v1.3): Google Account Selector Dialog
  void _showSwitchGoogleAccountDialog() {
    final customAccountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? WhatsAppTheme.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.account_circle_rounded, color: Color(0xFF4285F4)),
                SizedBox(width: 8),
                Expanded(child: Text('Google Drive Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select which Google account this app uses for cloud backup and restoring files:',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
                  ..._backupService.availableGoogleAccounts.map((acc) {
                    final isSel = _backupService.selectedGoogleAccount == acc;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isSel ? const Color(0xFF4285F4) : Colors.grey.shade400,
                        child: Text(
                          acc.isNotEmpty ? acc[0].toUpperCase() : 'G',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        acc,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? const Color(0xFF4285F4) : null,
                        ),
                      ),
                      trailing: isSel ? const Icon(Icons.check_circle, color: Color(0xFF4285F4), size: 20) : null,
                      onTap: () {
                        setState(() {
                          _backupService.setGoogleAccount(acc);
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF4285F4),
                            content: Text('Active Google Drive account: $acc'),
                          ),
                        );
                      },
                    );
                  }),
                  const Divider(height: 16),
                  const Text('Or enter another Google account email:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customAccountCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. user@gmail.com',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4285F4), foregroundColor: Colors.white),
                        onPressed: () {
                          final newAcc = customAccountCtrl.text.trim();
                          if (newAcc.isNotEmpty) {
                            setState(() {
                              _backupService.setGoogleAccount(newAcc);
                            });
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Use'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConfigEditorModal() async {
    final jsonStr = await _configService.exportConfigJson();
    final textController = TextEditingController(text: jsonStr);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('folders_config.json', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: TextField(
              controller: textController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'JSON configuration...',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: WhatsAppTheme.accentGreen),
              onPressed: () async {
                final success = await _configService.importConfigJson(textController.text);
                Navigator.of(ctx).pop();
                if (success) {
                  setState(() {
                    _folders = _configService.folders;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: WhatsAppTheme.accentGreen,
                      content: Text('✓ folders_config.json updated successfully'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Invalid JSON formatting'),
                    ),
                  );
                }
              },
              child: const Text('Save & Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Organizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search all files, notes & tags',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CentralSearchScreen(
                    folders: _folders,
                    onFolderUpdated: (updated) {
                      setState(() {
                        _folders = _configService.folders;
                      });
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Pick files from storage',
            onPressed: _pickFilesFromStorage,
          ),
          IconButton(
            icon: const Icon(Icons.system_update_rounded),
            tooltip: 'Check for Updates',
            onPressed: () => _updateService.showUpdateDialog(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'pick_files') _pickFilesFromStorage();
              if (value == 'update') _updateService.showUpdateDialog(context);
              if (value == 'new_folder') _showNewFolderDialog();
              if (value == 'account') _showSwitchGoogleAccountDialog();
              if (value == 'simulate') _triggerSimulatedShare();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pick_files',
                child: Row(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 20, color: WhatsAppTheme.accentGreen),
                    SizedBox(width: 8),
                    Text('Pick Files from Storage'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'update',
                child: Row(
                  children: [
                    Icon(Icons.system_update_rounded, size: 20, color: WhatsAppTheme.accentGreen),
                    SizedBox(width: 8),
                    Text('Check for Updates (v1.3)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new_folder',
                child: Row(
                  children: [
                    Icon(Icons.create_new_folder_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Add Folder Contact'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'account',
                child: Row(
                  children: [
                    Icon(Icons.cloud_outlined, size: 20, color: Color(0xFF4285F4)),
                    SizedBox(width: 8),
                    Text('Google Drive Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'simulate',
                child: Row(
                  children: [
                    Icon(Icons.share_arrival_time_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Simulate Incoming Share'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: WhatsAppTheme.accentGreen,
          indicatorWeight: 3.5,
          labelColor: WhatsAppTheme.accentGreen,
          unselectedLabelColor: WhatsAppTheme.darkTextSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(text: 'FOLDERS'),
            Tab(text: 'RECENT FILES'),
            Tab(text: 'CLOUD & BACKUP'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: WhatsAppTheme.accentGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Folders Tab (WhatsApp Contact List)
                Column(
                  children: [
                    // Top Action Banner: Pick Files from Storage
                    Container(
                      color: isDark ? const Color(0xFF1B2730) : const Color(0xFFE8F5E9),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.file_upload_outlined, color: WhatsAppTheme.accentGreen, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pick files from phone storage to sort into folders.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? WhatsAppTheme.darkTextPrimary : const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickFilesFromStorage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WhatsAppTheme.accentGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 1,
                            ),
                            icon: const Icon(Icons.folder_open_rounded, size: 16),
                            label: const Text('PICK FILES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                          ),
                        ],
                      ),
                    ),

                    // Contact Folders List
                    Expanded(
                      child: ListView.separated(
                        itemCount: _folders.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 0.8,
                          indent: 82,
                          color: isDark ? const Color(0xFF222D34) : const Color(0xFFE9EDEF),
                        ),
                        itemBuilder: (context, index) {
                          final folder = _folders[index];
                          return WhatsAppContactTile(
                            folder: folder,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FolderChatScreen(folder: folder),
                                ),
                              ).then((_) => setState(() {
                                    _folders = _configService.folders;
                                  }));
                            },
                            onLongPress: () => _showFolderLongPressOptions(folder),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // 2. Recent Files Tab
                _buildRecentFilesTab(isDark),

                // 3. Cloud & Backup Tab (Level 5 v1.3 Enhanced)
                _buildCloudAndBackupTab(isDark),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewFolderDialog,
        backgroundColor: WhatsAppTheme.accentGreen,
        tooltip: 'Add new folder contact',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRecentFilesTab(bool isDark) {
    final allFiles = <Map<String, dynamic>>[];
    for (final folder in _folders) {
      for (final file in folder.files) {
        allFiles.add({'file': file, 'folder': folder});
      }
    }
    allFiles.sort((a, b) => (b['file'] as SharedFileItem).sharedAt.compareTo((a['file'] as SharedFileItem).sharedAt));

    if (allFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inbox_outlined, size: 48, color: WhatsAppTheme.darkTextSecondary),
            SizedBox(height: 12),
            Text('No files shared yet', style: TextStyle(color: WhatsAppTheme.darkTextSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: allFiles.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: isDark ? const Color(0xFF222D34) : const Color(0xFFE9EDEF),
      ),
      itemBuilder: (context, index) {
        final file = allFiles[index]['file'] as SharedFileItem;
        final folder = allFiles[index]['folder'] as FolderContact;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: folder.avatarBgColor.withOpacity(0.2),
            child: Text(folder.avatarEmoji, style: const TextStyle(fontSize: 18)),
          ),
          title: Text(file.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('Folder: ${folder.name} • ${file.formattedSize}'),
          trailing: file.isPinned ? const Icon(Icons.push_pin_rounded, size: 16, color: WhatsAppTheme.accentGreen) : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FolderChatScreen(folder: folder)),
            ).then((_) => setState(() {}));
          },
        );
      },
    );
  }

  Widget _buildCloudAndBackupTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Active Google Drive Account Card (Level 5 v1.3: Item 5)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2A32) : const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.4), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_done_rounded, color: Color(0xFF4285F4), size: 22),
                        SizedBox(width: 8),
                        Text('ACTIVE GOOGLE DRIVE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.5, color: Color(0xFF4285F4))),
                      ],
                    ),
                    InkWell(
                      onTap: _showSwitchGoogleAccountDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4285F4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('SWITCH', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _backupService.selectedGoogleAccount,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cloud Location: ${_backupService.cloudVaultPath}',
                  style: TextStyle(fontSize: 11.5, color: isDark ? WhatsAppTheme.darkTextSecondary : Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Import Everything from Google Drive (Level 5 v1.3: Item 4)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2730) : const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WhatsAppTheme.accentGreen.withOpacity(0.4), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.cloud_download_rounded, color: WhatsAppTheme.accentGreen, size: 22),
                    SizedBox(width: 8),
                    Text('IMPORT FROM GOOGLE DRIVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: WhatsAppTheme.accentGreen)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Restore all folder contacts, shared files, captions, and tags when migrating to a new phone.',
                  style: TextStyle(fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WhatsAppTheme.accentGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  icon: const Icon(Icons.download_for_offline_rounded, size: 20),
                  label: const Text('Import Everything from Google Drive', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Restoring vault from ${_backupService.selectedGoogleAccount}...')),
                    );
                    final success = await _backupService.importEverythingFromGoogleDrive();
                    if (mounted) {
                      setState(() {
                        _folders = _configService.folders;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: success ? WhatsAppTheme.accentGreen : Colors.red,
                          content: Text(success ? '✓ Google Drive Restore Completed successfully!' : 'Failed to import from Drive'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  icon: const Icon(Icons.file_open_outlined, size: 18),
                  label: const Text('Pick Backup File / JSON from Drive / Storage'),
                  onPressed: () async {
                    final success = await _backupService.pickAndImportFromDriveOrStorage();
                    if (mounted) {
                      setState(() {
                        _folders = _configService.folders;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: success ? WhatsAppTheme.accentGreen : Colors.red,
                          content: Text(success ? '✓ Backup file imported successfully!' : 'No valid backup selected'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Cloud Sync & Local Backup Actions
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
            ),
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('Save / Sync Vault to Google Drive', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compressing all files and launching Save to Google Drive...')),
              );
              final success = await _backupService.syncWithGoogleDrive();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? WhatsAppTheme.accentGreen : Colors.red,
                    content: Text(success ? '✓ Ready in Google Drive / Share' : 'Sync error'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: WhatsAppTheme.accentGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
            ),
            icon: const Icon(Icons.archive_rounded),
            label: const Text('Export Overwriteable Vault (.zip)'),
            onPressed: () async {
              final backup = await _backupService.createExportArchive();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: WhatsAppTheme.accentGreen,
                    content: Text('Master vault updated: ${backup.path.split('/').last.split('\\').last} (Overwritten in Downloads/FileOrganizer)'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
            ),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Edit folders_config.json'),
            onPressed: _showConfigEditorModal,
          ),
          const SizedBox(height: 20),

          // 4. Software Update via GitHub Card (Level 5 v1.3: Item 2)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2A32) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: WhatsAppTheme.accentGreen.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_rounded, color: WhatsAppTheme.accentGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('File Organizer v1.3.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        'Repo: ${_updateService.githubOwner}/${_updateService.githubRepo}',
                        style: const TextStyle(fontSize: 11, color: WhatsAppTheme.darkTextSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WhatsAppTheme.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => _updateService.showUpdateDialog(context),
                  child: const Text('Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
