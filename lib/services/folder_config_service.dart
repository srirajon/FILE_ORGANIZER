import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/folder_contact.dart';

class FolderConfigService {
  static final FolderConfigService _instance = FolderConfigService._internal();
  factory FolderConfigService() => _instance;
  FolderConfigService._internal();

  static const String _configFileName = 'folders_config.json';
  List<FolderContact> _folders = [];
  bool _isInitialized = false;

  List<FolderContact> get folders => _folders;

  /// Load folders from local config file, or initialize with defaults if first run
  Future<List<FolderContact>> loadFolders() async {
    if (_isInitialized && _folders.isNotEmpty) {
      return _folders;
    }

    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
        _folders = jsonList.map((item) => FolderContact.fromJson(item as Map<String, dynamic>)).toList();
        debugPrint('Loaded ${_folders.length} folders from $_configFileName');
      } else {
        _folders = FolderContact.getInitialFolders();
        await saveFolders();
      }
    } catch (e) {
      debugPrint('Error loading folders_config.json: $e. Falling back to defaults.');
      _folders = FolderContact.getInitialFolders();
    }

    _isInitialized = true;
    return _folders;
  }

  /// Save current folder state into folders_config.json
  Future<void> saveFolders() async {
    try {
      final file = await _getConfigFile();
      final jsonList = _folders.map((f) => f.toJson()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
      await file.writeAsString(jsonString);
      debugPrint('Successfully saved ${_folders.length} folders to $_configFileName');
    } catch (e) {
      debugPrint('Error saving to folders_config.json: $e');
    }
  }

  /// Add a brand new folder contact dynamically
  Future<FolderContact> addFolder({
    required String name,
    required String description,
    required String avatarEmoji,
    required Color avatarBgColor,
  }) async {
    final newFolder = FolderContact(
      id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      avatarEmoji: avatarEmoji,
      avatarBgColor: avatarBgColor,
      lastTimestamp: 'Just now',
      unreadOrNewCount: 0,
      files: [],
    );

    _folders.insert(0, newFolder);
    await saveFolders();
    return newFolder;
  }

  /// Delete a folder contact with all its contents and optional physical storage files
  Future<void> deleteFolder(String folderId, {bool deletePhysicalFiles = true}) async {
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex == -1) return;

    final targetFolder = _folders[folderIndex];

    if (deletePhysicalFiles) {
      for (final fileItem in targetFolder.files) {
        if (fileItem.filePath != null && fileItem.filePath!.isNotEmpty) {
          try {
            final f = File(fileItem.filePath!);
            if (await f.exists()) {
              await f.delete();
              debugPrint('Deleted physical file: ${fileItem.filePath}');
            }
          } catch (e) {
            debugPrint('Error deleting physical file ${fileItem.filePath}: $e');
          }
        }
      }
    }

    _folders.removeAt(folderIndex);
    await saveFolders();
  }

  /// Export the full folders_config.json content as a clean formatted JSON string
  Future<String> exportConfigJson() async {
    final jsonList = _folders.map((f) => f.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }

  /// Import custom JSON string to replace or update folders configuration
  Future<bool> importConfigJson(String jsonString) async {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      _folders = jsonList.map((item) => FolderContact.fromJson(item as Map<String, dynamic>)).toList();
      await saveFolders();
      return true;
    } catch (e) {
      debugPrint('Failed to import config JSON: $e');
      return false;
    }
  }

  Future<File> _getConfigFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_configFileName');
  }

  /// Get the absolute path of folders_config.json for external access/editing
  Future<String> getConfigFilePath() async {
    final file = await _getConfigFile();
    return file.path;
  }
}
