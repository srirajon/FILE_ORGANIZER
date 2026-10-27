import 'package:flutter/material.dart';
import '../models/folder_contact.dart';
import '../models/shared_file_item.dart';
import '../services/file_opener_service.dart';
import '../theme/app_theme.dart';
import 'folder_chat_screen.dart';

class ChatMediaScreen extends StatefulWidget {
  final FolderContact folder;

  const ChatMediaScreen({
    super.key,
    required this.folder,
  });

  @override
  State<ChatMediaScreen> createState() => _ChatMediaScreenState();
}

class _ChatMediaScreenState extends State<ChatMediaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchFilter = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<SharedFileItem> get _allFiles => widget.folder.files;

  List<SharedFileItem> get _mediaFiles {
    return _allFiles.where((f) {
      final matchesCategory = f.category == FileCategory.image || f.category == FileCategory.video;
      if (!matchesCategory) return false;
      if (_searchFilter.isEmpty) return true;
      return f.fileName.toLowerCase().contains(_searchFilter.toLowerCase());
    }).toList();
  }

  List<SharedFileItem> get _docFiles {
    return _allFiles.where((f) {
      if (f.isTextNote) return false;
      final matchesCategory = f.category == FileCategory.document ||
          f.category == FileCategory.archive ||
          f.category == FileCategory.audio ||
          f.category == FileCategory.other;
      if (!matchesCategory) return false;
      if (_searchFilter.isEmpty) return true;
      return f.fileName.toLowerCase().contains(_searchFilter.toLowerCase());
    }).toList();
  }

  List<SharedFileItem> get _noteFiles {
    return _allFiles.where((f) {
      final matchesCategory = f.isMarkdown || f.category == FileCategory.markdown || f.isTextNote;
      if (!matchesCategory) return false;
      if (_searchFilter.isEmpty) return true;
      final inName = f.fileName.toLowerCase().contains(_searchFilter.toLowerCase());
      final inContent = f.rawContent?.toLowerCase().contains(_searchFilter.toLowerCase()) ?? false;
      final inCaption = f.displayCaption?.toLowerCase().contains(_searchFilter.toLowerCase()) ?? false;
      return inName || inContent || inCaption;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? WhatsAppTheme.chatBgDark : WhatsAppTheme.chatBgLight,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Filter files...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchFilter = val;
                  });
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.folder.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Media, docs & notes (${_allFiles.length})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchFilter = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: WhatsAppTheme.accentGreen,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'MEDIA (${_mediaFiles.length})'),
            Tab(text: 'DOCS (${_docFiles.length})'),
            Tab(text: 'AI NOTES (${_noteFiles.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMediaGrid(isDark),
          _buildDocsList(isDark),
          _buildNotesList(isDark),
        ],
      ),
    );
  }

  // 1. Media Grid (Images / Videos)
  Widget _buildMediaGrid(bool isDark) {
    if (_mediaFiles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No media shared yet',
        subtitle: 'Photos and videos sent to "${widget.folder.name}" will appear here.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _mediaFiles.length,
      itemBuilder: (context, index) {
        final item = _mediaFiles[index];
        final isVideo = item.category == FileCategory.video;

        return InkWell(
          onTap: () => FileOpenerService.openFile(context: context, file: item),
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF263238) : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                    size: 38,
                    color: isVideo ? const Color(0xFFAB47BC) : const Color(0xFF42A5F5),
                  ),
                ),
              ),
              if (item.isPinned)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.push_pin_rounded, size: 12, color: WhatsAppTheme.accentGreen),
                  ),
                ),
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Text(
                  item.formattedSize,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. Documents List (PDFs, Office Docs, Archives)
  Widget _buildDocsList(bool isDark) {
    if (_docFiles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.description_outlined,
        title: 'No documents shared yet',
        subtitle: 'PDFs, spreadsheets, and archives sent here will be listed.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _docFiles.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 72,
        color: isDark ? Colors.white12 : Colors.black12,
      ),
      itemBuilder: (context, index) {
        final item = _docFiles[index];
        final isPdf = item.fileName.toLowerCase().endsWith('.pdf');

        return ListTile(
          onTap: () => FileOpenerService.openFile(context: context, file: item),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isPdf ? const Color(0xFFEF5350).withValues(alpha: 0.15) : WhatsAppTheme.accentGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
              color: isPdf ? const Color(0xFFEF5350) : WhatsAppTheme.accentGreen,
              size: 26,
            ),
          ),
          title: Text(
            item.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Row(
            children: [
              Text(
                item.formattedSize,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•  ${item.sharedAt.day}/${item.sharedAt.month}/${item.sharedAt.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              if (item.isPinned) ...[
                const SizedBox(width: 8),
                const Icon(Icons.push_pin_rounded, size: 12, color: WhatsAppTheme.accentGreen),
              ],
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 20, color: WhatsAppTheme.accentGreen),
            tooltip: 'Open with default app',
            onPressed: () => FileOpenerService.openFile(context: context, file: item),
          ),
        );
      },
    );
  }

  // 3. AI Notes List (.md Markdown documents)
  Widget _buildNotesList(bool isDark) {
    if (_noteFiles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.article_outlined,
        title: 'No AI Markdown notes',
        subtitle: 'Copied ChatGPT/Claude text saved as .md will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _noteFiles.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 72,
        color: isDark ? Colors.white12 : Colors.black12,
      ),
      itemBuilder: (context, index) {
        final item = _noteFiles[index];

        return ListTile(
          onTap: () {
            // Open in-app markdown reader
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: isDark ? const Color(0xFF1E2A32) : Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => MarkdownReaderSheet(file: item),
            );
          },
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF26A69A).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.article_rounded,
              color: Color(0xFF26A69A),
              size: 26,
            ),
          ),
          title: Text(
            item.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            item.rawContent?.replaceAll('\n', ' ') ?? item.formattedSize,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isPinned)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.push_pin_rounded, size: 14, color: WhatsAppTheme.accentGreen),
                ),
              IconButton(
                icon: const Icon(Icons.chrome_reader_mode_rounded, size: 20, color: Color(0xFF26A69A)),
                tooltip: 'Read Markdown',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: isDark ? const Color(0xFF1E2A32) : Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (ctx) => MarkdownReaderSheet(file: item),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
