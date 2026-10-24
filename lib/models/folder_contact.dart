import 'package:flutter/material.dart';
import 'shared_file_item.dart';

class FolderContact {
  final String id;
  String name;
  String description;
  String avatarEmoji;
  Color avatarBgColor;
  String lastTimestamp;
  int unreadOrNewCount;
  final List<SharedFileItem> files;

  FolderContact({
    required this.id,
    required this.name,
    required this.description,
    required this.avatarEmoji,
    required this.avatarBgColor,
    required this.lastTimestamp,
    this.unreadOrNewCount = 0,
    required this.files,
  });

  String get fileCountLabel => '${files.length} items';
  List<SharedFileItem> get pinnedFiles => files.where((f) => f.isPinned).toList();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatarEmoji': avatarEmoji,
      'avatarBgColor': avatarBgColor.value.toRadixString(16).padLeft(8, '0'),
      'lastTimestamp': lastTimestamp,
      'unreadOrNewCount': unreadOrNewCount,
      'files': files.map((f) => f.toJson()).toList(),
    };
  }

  factory FolderContact.fromJson(Map<String, dynamic> json) {
    Color parsedColor = const Color(0xFF1E88E5);
    if (json['avatarBgColor'] != null) {
      try {
        parsedColor = Color(int.parse(json['avatarBgColor'] as String, radix: 16));
      } catch (_) {}
    }

    final rawFiles = json['files'] as List<dynamic>? ?? [];
    final parsedFiles = rawFiles
        .map((f) => SharedFileItem.fromJson(f as Map<String, dynamic>))
        .toList();

    return FolderContact(
      id: json['id'] as String? ?? 'folder_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'New Folder',
      description: json['description'] as String? ?? '',
      avatarEmoji: json['avatarEmoji'] as String? ?? '📁',
      avatarBgColor: parsedColor,
      lastTimestamp: json['lastTimestamp'] as String? ?? 'Just now',
      unreadOrNewCount: json['unreadOrNewCount'] as int? ?? 0,
      files: parsedFiles,
    );
  }

  /// Initial default folders loaded if no config file exists yet
  static List<FolderContact> getInitialFolders() {
    return [
      FolderContact(
        id: 'work_docs',
        name: 'Work Documents',
        description: 'Quarterly reports, NDA agreements & contracts',
        avatarEmoji: '💼',
        avatarBgColor: const Color(0xFF1E88E5),
        lastTimestamp: '11:42 AM',
        unreadOrNewCount: 0,
        files: [
          SharedFileItem(
            id: 'f1',
            fileName: 'Q3_Financial_Analysis.pdf',
            fileSizeBytes: 2450000,
            mimeType: 'application/pdf',
            sharedAt: DateTime.now().subtract(const Duration(minutes: 45)),
            category: FileCategory.document,
          ),
          SharedFileItem(
            id: 'f2',
            fileName: 'Vendor_Contract_DESCO.pdf',
            fileSizeBytes: 1200000,
            mimeType: 'application/pdf',
            sharedAt: DateTime.now().subtract(const Duration(hours: 3)),
            category: FileCategory.document,
          ),
          SharedFileItem(
            id: 'f3',
            fileName: 'Team_Sprint_Goals.docx',
            fileSizeBytes: 450000,
            mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            sharedAt: DateTime.now().subtract(const Duration(days: 1)),
            category: FileCategory.document,
          ),
        ],
      ),
      FolderContact(
        id: 'receipts',
        name: 'Receipts & Invoices',
        description: 'Tax deductions, utility bills & shopping receipts',
        avatarEmoji: '🧾',
        avatarBgColor: const Color(0xFF43A047),
        lastTimestamp: 'Yesterday',
        unreadOrNewCount: 0,
        files: [
          SharedFileItem(
            id: 'f4',
            fileName: 'Grocery_Store_TaxInvoice.jpg',
            fileSizeBytes: 850000,
            mimeType: 'image/jpeg',
            sharedAt: DateTime.now().subtract(const Duration(days: 1)),
            category: FileCategory.image,
          ),
          SharedFileItem(
            id: 'f5',
            fileName: 'Electricity_Bill_Oct2026.pdf',
            fileSizeBytes: 310000,
            mimeType: 'application/pdf',
            sharedAt: DateTime.now().subtract(const Duration(days: 2)),
            category: FileCategory.document,
          ),
        ],
      ),
      FolderContact(
        id: 'family_photos',
        name: 'Family Photos',
        description: 'Vacation memories, birthdays & family weekend',
        avatarEmoji: '📸',
        avatarBgColor: const Color(0xFFE53935),
        lastTimestamp: 'Tuesday',
        unreadOrNewCount: 0,
        files: [
          SharedFileItem(
            id: 'f6',
            fileName: 'Beach_Sunset_2026.jpg',
            fileSizeBytes: 3800000,
            mimeType: 'image/jpeg',
            sharedAt: DateTime.now().subtract(const Duration(days: 3)),
            category: FileCategory.image,
          ),
          SharedFileItem(
            id: 'f7',
            fileName: 'Kids_Graduation.mp4',
            fileSizeBytes: 14500000,
            mimeType: 'video/mp4',
            sharedAt: DateTime.now().subtract(const Duration(days: 5)),
            category: FileCategory.video,
          ),
        ],
      ),
      FolderContact(
        id: 'ideas_notes',
        name: 'Ideas & Notes',
        description: 'Quick voice memos, whiteboard sketches & clips',
        avatarEmoji: '💡',
        avatarBgColor: const Color(0xFFFB8C00),
        lastTimestamp: 'Sunday',
        unreadOrNewCount: 0,
        files: [
          SharedFileItem(
            id: 'f8',
            fileName: 'App_Architecture_Diagram.png',
            fileSizeBytes: 1400000,
            mimeType: 'image/png',
            sharedAt: DateTime.now().subtract(const Duration(days: 4)),
            category: FileCategory.image,
          ),
          SharedFileItem(
            id: 'f_md1',
            fileName: 'AI_Architecture_Brainstorm.md',
            fileSizeBytes: 2450,
            mimeType: 'text/markdown',
            sharedAt: DateTime.now().subtract(const Duration(days: 5)),
            category: FileCategory.markdown,
            isPinned: true,
            rawContent: '# AI Brainstorm: Conversational File Organizer\n\n## Core Concept\n- Bypasses nested folder navigation by representing directories as WhatsApp contacts.\n- Sharing a file looks like sending a WhatsApp message.\n\n## Key Advantages\n1. Zero friction sorting.\n2. Built-in Markdown reader for LLM text responses.\n3. Complete cross-device migration via Google Drive and backup archives.',
          ),
          SharedFileItem(
            id: 'f9',
            fileName: 'Voice_Note_003.m4a',
            fileSizeBytes: 890000,
            mimeType: 'audio/mp4',
            sharedAt: DateTime.now().subtract(const Duration(days: 6)),
            category: FileCategory.audio,
          ),
        ],
      ),
      FolderContact(
        id: 'medical',
        name: 'Medical & Health',
        description: 'Doctor prescriptions, blood tests & health insurance',
        avatarEmoji: '🏥',
        avatarBgColor: const Color(0xFF8E24AA),
        lastTimestamp: '10/12/26',
        unreadOrNewCount: 0,
        files: [
          SharedFileItem(
            id: 'f10',
            fileName: 'Annual_Checkup_Lab_Results.pdf',
            fileSizeBytes: 980000,
            mimeType: 'application/pdf',
            sharedAt: DateTime.now().subtract(const Duration(days: 11)),
            category: FileCategory.document,
          ),
          SharedFileItem(
            id: 'f11',
            fileName: 'Health_Insurance_Policy.pdf',
            fileSizeBytes: 1850000,
            mimeType: 'application/pdf',
            sharedAt: DateTime.now().subtract(const Duration(days: 20)),
            category: FileCategory.document,
          ),
        ],
      ),
    ];
  }
}
