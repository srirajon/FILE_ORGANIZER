import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:file_organizer/models/shared_file_item.dart';
import 'package:file_organizer/models/folder_contact.dart';
import 'package:file_organizer/services/folder_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Level 7 (v1.5.0) Feature & Logic Tests', () {
    test('FolderContact dynamically formats lastTimestamp according to WhatsApp rules', () {
      final now = DateTime.now();

      // Today's message
      final todayFolder = FolderContact(
        id: 'f_today',
        name: 'Today Chat',
        description: 'Test',
        avatarEmoji: '📁',
        avatarBgColor: Colors.teal,
        lastTimestamp: 'Just now',
        files: [
          SharedFileItem(
            id: 'm1',
            fileName: 'invoice.pdf',
            fileSizeBytes: 1000,
            mimeType: 'application/pdf',
            sharedAt: now.subtract(const Duration(hours: 1)),
            category: FileCategory.document,
          ),
        ],
      );
      expect(todayFolder.formattedLastTimestamp, equals(DateFormat('h:mm a').format(now.subtract(const Duration(hours: 1)))));
      expect(todayFolder.formattedLastTimestamp, isNot('Just now'));

      // Yesterday's message
      final yesterdayFolder = FolderContact(
        id: 'f_yesterday',
        name: 'Yesterday Chat',
        description: 'Test',
        avatarEmoji: '📁',
        avatarBgColor: Colors.teal,
        lastTimestamp: 'Just now',
        files: [
          SharedFileItem(
            id: 'm2',
            fileName: 'photo.jpg',
            fileSizeBytes: 1000,
            mimeType: 'image/jpeg',
            sharedAt: now.subtract(const Duration(days: 1)),
            category: FileCategory.image,
          ),
        ],
      );
      expect(yesterdayFolder.formattedLastTimestamp, equals('Yesterday'));

      // 3 days ago message
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final pastWeekFolder = FolderContact(
        id: 'f_past_week',
        name: 'Past Week Chat',
        description: 'Test',
        avatarEmoji: '📁',
        avatarBgColor: Colors.teal,
        lastTimestamp: 'Just now',
        files: [
          SharedFileItem(
            id: 'm3',
            fileName: 'report.docx',
            fileSizeBytes: 1000,
            mimeType: 'application/vnd.ms-word',
            sharedAt: threeDaysAgo,
            category: FileCategory.document,
          ),
        ],
      );
      expect(pastWeekFolder.formattedLastTimestamp, equals(DateFormat('EEEE').format(threeDaysAgo)));

      // 10 days ago message
      final tenDaysAgo = now.subtract(const Duration(days: 10));
      final olderFolder = FolderContact(
        id: 'f_older',
        name: 'Older Chat',
        description: 'Test',
        avatarEmoji: '📁',
        avatarBgColor: Colors.teal,
        lastTimestamp: 'Just now',
        files: [
          SharedFileItem(
            id: 'm4',
            fileName: 'contract.pdf',
            fileSizeBytes: 1000,
            mimeType: 'application/pdf',
            sharedAt: tenDaysAgo,
            category: FileCategory.document,
          ),
        ],
      );
      expect(olderFolder.formattedLastTimestamp, equals(DateFormat('dd/MM/yy').format(tenDaysAgo)));
    });

    test('Chatheads auto-sort according to last message date (most recent to top)', () {
      final now = DateTime.now();

      final folderOld = FolderContact(
        id: 'old_chat',
        name: 'Old Chat',
        description: 'Old',
        avatarEmoji: '💼',
        avatarBgColor: Colors.blue,
        lastTimestamp: '',
        files: [
          SharedFileItem(
            id: 'f_old',
            fileName: 'doc1.pdf',
            fileSizeBytes: 500,
            mimeType: 'application/pdf',
            sharedAt: now.subtract(const Duration(days: 4)),
            category: FileCategory.document,
          ),
        ],
      );

      final folderMid = FolderContact(
        id: 'mid_chat',
        name: 'Mid Chat',
        description: 'Mid',
        avatarEmoji: '🧾',
        avatarBgColor: Colors.green,
        lastTimestamp: '',
        files: [
          SharedFileItem(
            id: 'f_mid',
            fileName: 'doc2.pdf',
            fileSizeBytes: 500,
            mimeType: 'application/pdf',
            sharedAt: now.subtract(const Duration(hours: 5)),
            category: FileCategory.document,
          ),
        ],
      );

      final folderLatest = FolderContact(
        id: 'latest_chat',
        name: 'Latest Chat',
        description: 'Latest',
        avatarEmoji: '🤖',
        avatarBgColor: Colors.orange,
        lastTimestamp: '',
        files: [
          SharedFileItem(
            id: 'f_latest',
            fileName: 'doc3.pdf',
            fileSizeBytes: 500,
            mimeType: 'application/pdf',
            sharedAt: now.subtract(const Duration(minutes: 5)),
            category: FileCategory.document,
          ),
        ],
      );

      final list = [folderOld, folderMid, folderLatest];
      list.sort((a, b) => b.lastActivityTime.compareTo(a.lastActivityTime));

      expect(list[0].id, equals('latest_chat'));
      expect(list[1].id, equals('mid_chat'));
      expect(list[2].id, equals('old_chat'));

      // If a new message is added to folderOld, it must move to the top
      folderOld.files.add(
        SharedFileItem(
          id: 'f_new',
          fileName: 'new_active.pdf',
          fileSizeBytes: 100,
          mimeType: 'application/pdf',
          sharedAt: DateTime.now(),
          category: FileCategory.document,
        ),
      );

      list.sort((a, b) => b.lastActivityTime.compareTo(a.lastActivityTime));
      expect(list[0].id, equals('old_chat'));
    });

    test('FolderContact supports customImagePath for mobile photo avatar and persists via JSON', () {
      final folder = FolderContact(
        id: 'folder_custom_photo',
        name: 'Personal Vault',
        description: 'Photos & IDs',
        avatarEmoji: '🔒',
        avatarBgColor: const Color(0xFF00897B),
        customImagePath: '/data/user/0/com.fileorganizer/app_flutter/folder_avatars/avatar_123.jpg',
        lastTimestamp: '10:00 AM',
        files: [],
      );

      expect(folder.customImagePath, equals('/data/user/0/com.fileorganizer/app_flutter/folder_avatars/avatar_123.jpg'));

      final jsonMap = folder.toJson();
      expect(jsonMap['customImagePath'], equals('/data/user/0/com.fileorganizer/app_flutter/folder_avatars/avatar_123.jpg'));

      final reconstructed = FolderContact.fromJson(jsonMap);
      expect(reconstructed.customImagePath, equals('/data/user/0/com.fileorganizer/app_flutter/folder_avatars/avatar_123.jpg'));
      expect(reconstructed.name, equals('Personal Vault'));
    });

    test('SharedFileItem effectiveMimeType reliably resolves PDF and documents', () {
      final pdfItem1 = SharedFileItem(
        id: '1',
        fileName: 'Invoice_October_2026.pdf',
        fileSizeBytes: 2048,
        mimeType: 'application/octet-stream', // Generic fallback
        sharedAt: DateTime.now(),
        category: FileCategory.document,
      );
      expect(pdfItem1.effectiveMimeType, equals('application/pdf'));

      final pdfItem2 = SharedFileItem(
        id: '2',
        fileName: 'Medical_Report.PDF',
        fileSizeBytes: 2048,
        mimeType: 'file', // receive_sharing_intent fallback
        sharedAt: DateTime.now(),
        category: FileCategory.document,
      );
      expect(pdfItem2.effectiveMimeType, equals('application/pdf'));

      final imgItem = SharedFileItem(
        id: '3',
        fileName: 'Vacation_Photo.jpg',
        fileSizeBytes: 2048,
        mimeType: 'file',
        sharedAt: DateTime.now(),
        category: FileCategory.image,
      );
      expect(imgItem.effectiveMimeType, equals('image/jpeg'));
    });
  });
}

