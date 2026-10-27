import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_organizer/models/shared_file_item.dart';
import 'package:file_organizer/models/folder_contact.dart';
import 'package:file_organizer/services/folder_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Level 6 Problem Fixes and Feature Tests', () {
    test('Multiline text sanitization preserves paragraphs and converts CRLF to LF', () {
      const facebookPost = 'Paragraph 1: Breaking news!\r\n\r\nParagraph 2: Detailed analysis here.\n• Point A\n• Point B\r\n\r\nFinal thought!';
      final formatted = SharedFileItem.formatMultilineText(facebookPost);

      expect(formatted.contains('\r'), isFalse);
      expect(formatted.contains('Paragraph 1: Breaking news!\n\nParagraph 2: Detailed analysis here.'), isTrue);
      expect(formatted.contains('• Point A\n• Point B'), isTrue);
      expect(formatted.split('\n').length, greaterThanOrEqualTo(5));
    });

    test('SharedFileItem accurately detects isTextNote and updates caption/content', () {
      final note = SharedFileItem(
        id: 'test_note_1',
        fileName: 'Note',
        fileSizeBytes: 100,
        mimeType: 'text/plain',
        sharedAt: DateTime.now(),
        category: FileCategory.document,
        rawContent: 'Line 1\nLine 2',
        note: 'Line 1\nLine 2',
      );

      expect(note.isTextNote, isTrue);
      expect(note.isMarkdown, isFalse);

      // Test Caption edit
      note.updateCaption('Updated Caption With\nNewline');
      expect(note.caption, equals('Updated Caption With\nNewline'));
      expect(note.displayCaption, equals('Updated Caption With\nNewline'));

      // Test Raw Content edit
      note.updateRawContent('New Header\n\nNew paragraph content.');
      expect(note.rawContent, equals('New Header\n\nNew paragraph content.'));
      expect(note.fileName, equals('New Header'));
    });

    test('FolderContact and FolderConfigService prevent duplicate folders with identical name', () async {
      final service = FolderConfigService();
      
      final folder1 = await service.addFolder(
        name: 'Work Invoices',
        description: 'Monthly receipts',
        avatarEmoji: '💼',
        avatarBgColor: Colors.blue,
      );

      final folder2 = await service.addFolder(
        name: 'Work Invoices',
        description: 'Monthly receipts copy',
        avatarEmoji: '💼',
        avatarBgColor: Colors.blue,
      );

      // Must return identical folder instance or same ID, never a duplicate entry
      expect(folder1.id, equals(folder2.id));
      final count = service.folders.where((f) => f.name.toLowerCase() == 'work invoices').length;
      expect(count, equals(1));
    });
  });
}
