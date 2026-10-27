import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../models/shared_file_item.dart';

class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._internal();
  factory ShareIntentService() => _instance;
  ShareIntentService._internal();

  StreamSubscription? _mediaIntentSub;
  final _sharedPayloadController = StreamController<SharedFileItem>.broadcast();
  Stream<SharedFileItem> get onFileReceived => _sharedPayloadController.stream;

  final _sharedMultiplePayloadController = StreamController<List<SharedFileItem>>.broadcast();
  Stream<List<SharedFileItem>> get onFilesReceived => _sharedMultiplePayloadController.stream;

  List<SharedFileItem> _latestPendingFiles = [];
  List<SharedFileItem> get latestPendingFiles => List.unmodifiable(_latestPendingFiles);

  SharedFileItem? get latestPendingFile =>
      _latestPendingFiles.isNotEmpty ? _latestPendingFiles.first : null;

  void initialize({
    Function(List<SharedFileItem>)? onIncomingFiles,
    Function(SharedFileItem)? onIncomingFile,
  }) {
    _sharedMultiplePayloadController.stream.listen((files) {
      _latestPendingFiles = files;
      if (onIncomingFiles != null) {
        onIncomingFiles(files);
      }
      if (files.isNotEmpty && onIncomingFile != null) {
        onIncomingFile(files.first);
      }
    });

    _sharedPayloadController.stream.listen((file) {
      if (_latestPendingFiles.isEmpty) {
        _latestPendingFiles = [file];
      }
      if (onIncomingFile != null) {
        onIncomingFile(file);
      }
    });

    if (!kIsWeb) {
      try {
        // 1. Media & Text streams while app is in memory
        _mediaIntentSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
          if (value.isNotEmpty) {
            _handleMediaFiles(value);
          }
        }, onError: (err) {
          debugPrint('ReceiveSharingIntent getMediaStream error: $err');
        });

        // 2. Media & Text on cold start
        ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
          if (value.isNotEmpty) {
            _handleMediaFiles(value);
            ReceiveSharingIntent.instance.reset();
          }
        }).catchError((err) {
          debugPrint('ReceiveSharingIntent getInitialMedia error: $err');
        });
      } catch (e) {
        debugPrint('ReceiveSharingIntent initialization error: $e');
      }
    }
  }

  void _handleMediaFiles(List<SharedMediaFile> mediaFiles) {
    if (mediaFiles.isEmpty) return;

    // Check if incoming is single shared text or URL
    if (mediaFiles.length == 1 &&
        (mediaFiles.first.type == SharedMediaType.text || mediaFiles.first.type == SharedMediaType.url)) {
      if (mediaFiles.first.path.trim().isNotEmpty) {
        _handleIncomingText(mediaFiles.first.path);
      }
      return;
    }

    final items = <SharedFileItem>[];
    for (int i = 0; i < mediaFiles.length; i++) {
      final file = mediaFiles[i];
      if (file.path.trim().isEmpty) continue;

      final name = file.path.split('/').last.split('\\').last;
      int sizeBytes = 1024 * 512;
      try {
        final f = File(file.path);
        if (f.existsSync()) {
          sizeBytes = f.lengthSync();
        }
      } catch (_) {}

      items.add(
        SharedFileItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          fileName: name.isNotEmpty ? name : 'shared_file_${DateTime.now().millisecondsSinceEpoch}_$i',
          filePath: file.path,
          fileSizeBytes: sizeBytes,
          mimeType: file.type.name,
          sharedAt: DateTime.now(),
          category: SharedFileItem.detectCategory(name, file.type.name),
        ),
      );
    }

    if (items.isNotEmpty) {
      _latestPendingFiles = items;
      _sharedMultiplePayloadController.add(items);
      _sharedPayloadController.add(items.first);
    }
  }

  void _handleIncomingText(String text) {
    // Automatically convert incoming shared text into a structured .md document preserving all newlines
    final mdPayload = SharedFileItem.createMarkdownFromAiText(text: text);
    _latestPendingFiles = [mdPayload];
    _sharedMultiplePayloadController.add([mdPayload]);
    _sharedPayloadController.add(mdPayload);
  }

  /// Simulate an incoming shared file from another app
  void simulateIncomingShare({
    String fileName = 'October_Expense_Receipt.pdf',
    int sizeBytes = 345000,
    String mimeType = 'application/pdf',
    String? note,
  }) {
    final simulatedFile = SharedFileItem(
      id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      fileName: fileName,
      fileSizeBytes: sizeBytes,
      mimeType: mimeType,
      sharedAt: DateTime.now(),
      category: SharedFileItem.detectCategory(fileName, mimeType),
      note: note,
    );

    _latestPendingFiles = [simulatedFile];
    _sharedMultiplePayloadController.add([simulatedFile]);
    _sharedPayloadController.add(simulatedFile);
  }

  /// Simulate incoming AI Markdown text shared from ChatGPT/Claude/Gemini
  void simulateIncomingAiMarkdownShare({
    required String markdownContent,
    String? title,
  }) {
    final mdPayload = SharedFileItem.createMarkdownFromAiText(
      text: markdownContent,
      customTitle: title,
    );
    _latestPendingFiles = [mdPayload];
    _sharedMultiplePayloadController.add([mdPayload]);
    _sharedPayloadController.add(mdPayload);
  }

  void clearPendingFile() {
    _latestPendingFiles = [];
  }

  void clearPendingFiles() {
    _latestPendingFiles = [];
  }

  void dispose() {
    _mediaIntentSub?.cancel();
    _sharedPayloadController.close();
    _sharedMultiplePayloadController.close();
  }
}
