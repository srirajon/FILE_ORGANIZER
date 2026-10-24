import 'dart:async';
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

  SharedFileItem? _latestPendingFile;
  SharedFileItem? get latestPendingFile => _latestPendingFile;

  void initialize({required Function(SharedFileItem) onIncomingFile}) {
    _sharedPayloadController.stream.listen((file) {
      _latestPendingFile = file;
      onIncomingFile(file);
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
    final file = mediaFiles.first;

    // Check if this is incoming shared text or URL from an AI app/browser
    if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
      if (file.path.trim().isNotEmpty) {
        _handleIncomingText(file.path);
      }
      return;
    }

    final name = file.path.split('/').last.split('\\').last;

    final payload = SharedFileItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: name.isNotEmpty ? name : 'shared_file_${DateTime.now().millisecondsSinceEpoch}',
      filePath: file.path,
      fileSizeBytes: 1024 * 512,
      mimeType: file.type.name,
      sharedAt: DateTime.now(),
      category: SharedFileItem.detectCategory(name, file.type.name),
    );

    _latestPendingFile = payload;
    _sharedPayloadController.add(payload);
  }

  void _handleIncomingText(String text) {
    // Automatically convert incoming shared text from AI assistants into a structured .md document
    final mdPayload = SharedFileItem.createMarkdownFromAiText(text: text);
    _latestPendingFile = mdPayload;
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

    _latestPendingFile = simulatedFile;
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
    _latestPendingFile = mdPayload;
    _sharedPayloadController.add(mdPayload);
  }

  void clearPendingFile() {
    _latestPendingFile = null;
  }

  void dispose() {
    _mediaIntentSub?.cancel();
    _sharedPayloadController.close();
  }
}
