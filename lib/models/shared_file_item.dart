enum FileCategory {
  document,
  image,
  video,
  audio,
  archive,
  markdown,
  other,
}

class SharedFileItem {
  final String id;
  String fileName;
  final String? filePath;
  int fileSizeBytes;
  final String mimeType;
  final DateTime sharedAt;
  final FileCategory category;
  String? caption; // User-entered caption that enables future search; strictly no auto-generated text
  String? note; // Backward compatibility alias for caption
  List<String> tags; // User-defined tags (e.g. #receipt, #tax, #work)
  bool isPinned;
  String? rawContent; // Text content for .md and text files

  SharedFileItem({
    required this.id,
    required this.fileName,
    this.filePath,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.sharedAt,
    required this.category,
    this.caption,
    this.note,
    this.tags = const [],
    this.isPinned = false,
    this.rawContent,
  });

  /// Display caption or note
  String? get displayCaption => (caption != null && caption!.trim().isNotEmpty)
      ? caption!.trim()
      : (note != null && note!.trim().isNotEmpty ? note!.trim() : null);

  /// True if this item represents a text message/note rather than an external physical file
  bool get isTextNote =>
      (filePath == null || filePath!.isEmpty) &&
      (mimeType == 'text/plain' ||
       fileName == 'User Note' ||
       (rawContent != null && rawContent!.isNotEmpty && !isMarkdown));

  bool get isMarkdown =>
      fileName.toLowerCase().endsWith('.md') ||
      mimeType == 'text/markdown' ||
      category == FileCategory.markdown;

  /// Helper to normalize multiline text from Facebook, browsers, and mobile clipboards
  static String formatMultilineText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u2028', '\n')
        .replaceAll('\u2029', '\n\n')
        .trim();
  }

  /// Update caption & note safely
  void updateCaption(String? newCaption) {
    final cleaned = (newCaption != null && newCaption.trim().isNotEmpty)
        ? formatMultilineText(newCaption)
        : null;
    caption = cleaned;
    note = cleaned;
  }

  /// Update tags
  void updateTags(List<String> newTags) {
    tags = List<String>.from(newTags);
  }

  /// Update raw text content and recompute file size
  void updateRawContent(String newContent) {
    final formatted = formatMultilineText(newContent);
    rawContent = formatted;
    fileSizeBytes = formatted.codeUnits.length;
    // Keep caption in sync if this is a text note
    if (isTextNote) {
      note = formatted;
      caption = formatted;
      final lines = formatted.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isNotEmpty) {
        final firstLine = lines.first.trim();
        fileName = firstLine.length <= 40 ? firstLine : '${firstLine.substring(0, 37)}...';
      }
    }
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Resolve reliable MIME type from file extension and known types
  String get effectiveMimeType {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf') || mimeType.contains('pdf')) {
      return 'application/pdf';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.mkv')) return 'video/x-matroska';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.xlsx')) return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (lower.endsWith('.pptx')) return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    if (lower.endsWith('.md')) return 'text/markdown';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.zip')) return 'application/zip';
    if (mimeType.isNotEmpty && mimeType.contains('/')) return mimeType;
    return 'application/octet-stream';
  }

  static FileCategory detectCategory(String fileName, String mime) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.md') || mime == 'text/markdown') {
      return FileCategory.markdown;
    }
    if (mime.startsWith('image/') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return FileCategory.image;
    }
    if (mime.startsWith('video/') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv')) {
      return FileCategory.video;
    }
    if (mime.startsWith('audio/') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.wav')) {
      return FileCategory.audio;
    }
    if (mime.contains('pdf') || lower.endsWith('.pdf')) {
      return FileCategory.document;
    }
    if (lower.endsWith('.zip') || lower.endsWith('.rar') || lower.endsWith('.tar.gz')) {
      return FileCategory.archive;
    }
    return FileCategory.document;
  }

  /// Automatically format copied AI response text into a clean .md file
  static SharedFileItem createMarkdownFromAiText({
    required String text,
    String? customTitle,
    String? caption,
    List<String> tags = const [],
  }) {
    final trimmed = formatMultilineText(text);
    String docTitle;

    if (customTitle != null && customTitle.trim().isNotEmpty) {
      docTitle = customTitle.trim();
    } else {
      // Extract title from first markdown header or first line
      final lines = trimmed.split('\n');
      final firstLine = lines.isNotEmpty
          ? lines.first.replaceAll(RegExp(r'^[#*\- \t]+'), '').trim()
          : '';
      if (firstLine.isNotEmpty && firstLine.length <= 40) {
        docTitle = firstLine.replaceAll(RegExp(r'[\/:*?"<>|]'), '_');
      } else {
        final now = DateTime.now();
        docTitle =
            'AI_Note_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute.toString().padLeft(2, '0')}';
      }
    }

    if (!docTitle.toLowerCase().endsWith('.md')) {
      docTitle = '$docTitle.md';
    }

    final bytes = trimmed.codeUnits.length;

    return SharedFileItem(
      id: 'md_${DateTime.now().millisecondsSinceEpoch}',
      fileName: docTitle,
      fileSizeBytes: bytes,
      mimeType: 'text/markdown',
      sharedAt: DateTime.now(),
      category: FileCategory.markdown,
      caption: caption,
      note: caption,
      tags: tags,
      rawContent: trimmed,
      isPinned: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
      'sharedAt': sharedAt.toIso8601String(),
      'category': category.name,
      'caption': caption ?? note,
      'note': note ?? caption,
      'tags': tags,
      'isPinned': isPinned,
      'rawContent': rawContent,
    };
  }

  factory SharedFileItem.fromJson(Map<String, dynamic> json) {
    final rawCaption = json['caption'] as String? ?? json['note'] as String?;
    final rawTags = (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];

    return SharedFileItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: json['fileName'] as String? ?? 'Untitled_File',
      filePath: json['filePath'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      sharedAt: json['sharedAt'] != null
          ? DateTime.tryParse(json['sharedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: FileCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => detectCategory(json['fileName'] ?? '', json['mimeType'] ?? ''),
      ),
      caption: rawCaption,
      note: rawCaption,
      tags: rawTags,
      isPinned: json['isPinned'] as bool? ?? false,
      rawContent: json['rawContent'] as String?,
    );
  }
}
