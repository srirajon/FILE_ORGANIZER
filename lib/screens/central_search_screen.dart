import 'package:flutter/material.dart';
import '../models/folder_contact.dart';
import '../models/shared_file_item.dart';
import '../services/file_opener_service.dart';
import '../theme/app_theme.dart';
import '../widgets/folder_avatar.dart';
import 'folder_chat_screen.dart';

class CentralSearchResult {
  final FolderContact folder;
  final SharedFileItem file;
  final String? matchedSnippet;

  CentralSearchResult({
    required this.folder,
    required this.file,
    this.matchedSnippet,
  });
}

class CentralSearchScreen extends StatefulWidget {
  final List<FolderContact> folders;
  final Function(FolderContact)? onFolderUpdated;

  const CentralSearchScreen({
    super.key,
    required this.folders,
    this.onFolderUpdated,
  });

  @override
  State<CentralSearchScreen> createState() => _CentralSearchScreenState();
}

class _CentralSearchScreenState extends State<CentralSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter = 'All'; // All, Docs, Media, Notes, Pinned

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CentralSearchResult> get _filteredResults {
    final results = <CentralSearchResult>[];
    final q = _query.trim().toLowerCase();

    for (final folder in widget.folders) {
      for (final file in folder.files) {
        // Category filter check
        if (_selectedFilter == 'Docs') {
          if (file.isTextNote) continue;
          if (file.category != FileCategory.document &&
              file.category != FileCategory.archive &&
              file.category != FileCategory.other) {
            continue;
          }
        } else if (_selectedFilter == 'Media') {
          if (file.category != FileCategory.image && file.category != FileCategory.video) {
            continue;
          }
        } else if (_selectedFilter == 'Notes') {
          if (!file.isMarkdown && file.category != FileCategory.markdown && !file.isTextNote) {
            continue;
          }
        } else if (_selectedFilter == 'Tags') {
          if (file.tags.isEmpty) continue;
        } else if (_selectedFilter == 'Pinned') {
          if (!file.isPinned) continue;
        }

        // Query search
        if (q.isEmpty) {
          // If query is empty but filter is active (e.g. Pinned or Docs), show all matching that filter
          if (_selectedFilter != 'All') {
            results.add(CentralSearchResult(folder: folder, file: file));
          }
        } else {
          final inFileName = file.fileName.toLowerCase().contains(q);
          final inFolderName = folder.name.toLowerCase().contains(q);
          final inMime = file.mimeType.toLowerCase().contains(q);
          final inTags = file.tags.any((t) =>
              t.toLowerCase().contains(q) ||
              t.toLowerCase().replaceAll('#', '').contains(q));
          final inCaption = file.displayCaption != null &&
              file.displayCaption!.toLowerCase().contains(q);

          String? snippet;
          if (file.rawContent != null && file.rawContent!.toLowerCase().contains(q)) {
            final raw = file.rawContent!;
            final idx = raw.toLowerCase().indexOf(q);
            final start = (idx - 20) < 0 ? 0 : (idx - 20);
            final end = (idx + q.length + 40) > raw.length ? raw.length : (idx + q.length + 40);
            snippet = '...${raw.substring(start, end).replaceAll('\n', ' ')}...';
          } else if (inCaption) {
            snippet = 'Caption: ${file.displayCaption}';
          } else if (inTags) {
            final matchedTags = file.tags
                .where((t) =>
                    t.toLowerCase().contains(q) ||
                    t.toLowerCase().replaceAll('#', '').contains(q))
                .join(', ');
            snippet = 'Tag: $matchedTags';
          }

          if (inFileName || inFolderName || inMime || inTags || inCaption || snippet != null) {
            results.add(CentralSearchResult(
              folder: folder,
              file: file,
              matchedSnippet: snippet,
            ));
          }
        }
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = _filteredResults;

    return Scaffold(
      backgroundColor: isDark ? WhatsAppTheme.chatBgDark : WhatsAppTheme.chatBgLight,
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: WhatsAppTheme.accentGreen,
          decoration: const InputDecoration(
            hintText: 'Search all files, notes, chats...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() {
              _query = val;
            });
          },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _query = '';
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark ? const Color(0xFF1E2A32) : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', Icons.apps_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('Docs', Icons.description_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('Media', Icons.image_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('Notes', Icons.article_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('Tags', Icons.tag_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pinned', Icons.push_pin_rounded),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Results Count Bar
          if (_query.isNotEmpty || _selectedFilter != 'All')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                'Found ${results.length} item${results.length == 1 ? '' : 's'} across ${widget.folders.length} folder chats',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),

          // Search Results List
          Expanded(
            child: results.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 72,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return _buildSearchResultTile(item, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : WhatsAppTheme.accentGreen,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: WhatsAppTheme.accentGreen,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
    );
  }

  Widget _buildSearchResultTile(CentralSearchResult item, bool isDark) {
    final file = item.file;
    final folder = item.folder;

    IconData icon;
    Color iconColor;

    switch (file.category) {
      case FileCategory.document:
        icon = Icons.picture_as_pdf_rounded;
        iconColor = const Color(0xFFEF5350);
        break;
      case FileCategory.image:
        icon = Icons.image_rounded;
        iconColor = const Color(0xFF42A5F5);
        break;
      case FileCategory.video:
        icon = Icons.videocam_rounded;
        iconColor = const Color(0xFFAB47BC);
        break;
      case FileCategory.audio:
        icon = Icons.audiotrack_rounded;
        iconColor = const Color(0xFFFFA726);
        break;
      case FileCategory.archive:
        icon = Icons.folder_zip_rounded;
        iconColor = const Color(0xFF78909C);
        break;
      case FileCategory.markdown:
        icon = Icons.article_rounded;
        iconColor = const Color(0xFF26A69A);
        break;
      case FileCategory.other:
        icon = Icons.insert_drive_file_rounded;
        iconColor = WhatsAppTheme.accentGreen;
        break;
    }

    return InkWell(
      onTap: () {
        // Navigate directly into that folder's chat head!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FolderChatScreen(
              folder: folder,
              onFolderUpdated: widget.onFolderUpdated,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),

            // Content Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          file.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      if (file.isPinned) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: WhatsAppTheme.accentGreen.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.push_pin_rounded, size: 10, color: WhatsAppTheme.accentGreen),
                              SizedBox(width: 3),
                              Text(
                                'PINNED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: WhatsAppTheme.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Location chip: which folder contact it's in!
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF263238) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FolderAvatar(folder: folder, size: 14, fontSize: 10, showShadow: false),
                            const SizedBox(width: 4),
                            Text(
                              folder.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${file.formattedSize} • ${file.sharedAt.day}/${file.sharedAt.month}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  // Tag badges (Level 5 v1.3)
                  if (file.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: file.tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: WhatsAppTheme.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: WhatsAppTheme.accentGreen,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],

                  // Matched text snippet if found in notes or markdown
                  if (item.matchedSnippet != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      item.matchedSnippet!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: WhatsAppTheme.accentGreen.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Open Button
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              tooltip: 'Open with default app',
              color: isDark ? Colors.white60 : Colors.black54,
              onPressed: () {
                FileOpenerService.openFile(context: context, file: file);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final hasCriteria = _query.isNotEmpty || _selectedFilter != 'All';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasCriteria ? Icons.search_off_rounded : Icons.search_rounded,
              size: 56,
              color: Colors.grey.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasCriteria ? 'No matching files found' : 'Central Chat Search',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasCriteria
                  ? 'Try searching by file name, keyword inside notes, or switch filters.'
                  : 'Search across all files, photos, receipts, and AI notes from every folder contact.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
