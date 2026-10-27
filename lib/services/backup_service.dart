import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'folder_config_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final FolderConfigService _configService = FolderConfigService();
  static const MethodChannel _platformChannel = MethodChannel('com.fileorganizer/app_chooser');

  SyncStatus _googleDriveStatus = SyncStatus.idle;
  SyncStatus get googleDriveStatus => _googleDriveStatus;
  DateTime? _lastGoogleDriveSync;
  DateTime? get lastGoogleDriveSync => _lastGoogleDriveSync;

  // Level 5 (v1.3): Explicit Google Account Selection
  String _selectedGoogleAccount = 'raisul.public@gmail.com';
  final List<String> _availableGoogleAccounts = [
    'raisul.public@gmail.com',
    'raisul.public2@gmail.com',
    'srirajon93@gmail.com',
  ];

  String get selectedGoogleAccount => _selectedGoogleAccount;
  List<String> get availableGoogleAccounts => List.unmodifiable(_availableGoogleAccounts);
  String get cloudVaultPath => 'Google Drive > My Drive > FileOrganizer_Vault.zip';

  void setGoogleAccount(String account) {
    if (account.trim().isNotEmpty) {
      _selectedGoogleAccount = account.trim();
      if (!_availableGoogleAccounts.contains(_selectedGoogleAccount)) {
        _availableGoogleAccounts.add(_selectedGoogleAccount);
      }
      debugPrint('Active Google Drive Account set to: $_selectedGoogleAccount');
    }
  }

  void addGoogleAccount(String newAccount) {
    final trimmed = newAccount.trim();
    if (trimmed.isNotEmpty && !_availableGoogleAccounts.contains(trimmed)) {
      _availableGoogleAccounts.add(trimmed);
      _selectedGoogleAccount = trimmed;
    }
  }

  /// Get the public phone storage vault directory:
  /// Primary target: /storage/emulated/0/Download/FileOrganizer
  /// This allows user to easily see their folders in phone's Files / My Files app
  Future<Directory> getPublicVaultDirectory() async {
    // 1. Check primary Android public Download folder
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final vaultDir = Directory('${downloadDir.path}/FileOrganizer');
        if (!await vaultDir.exists()) {
          await vaultDir.create(recursive: true);
        }
        return vaultDir;
      }
    } catch (e) {
      debugPrint('Primary download dir access check: $e');
    }

    // 2. Check getDownloadsDirectory() from path_provider
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final vaultDir = Directory('${downloadsDir.path}/FileOrganizer');
        if (!await vaultDir.exists()) {
          await vaultDir.create(recursive: true);
        }
        return vaultDir;
      }
    } catch (e) {
      debugPrint('PathProvider getDownloadsDirectory check: $e');
    }

    // 3. Fallback to app documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final fallbackVault = Directory('${appDocDir.path}/FileOrganizer');
    if (!await fallbackVault.exists()) {
      await fallbackVault.create(recursive: true);
    }
    return fallbackVault;
  }

  /// Persists a physical file or AI Markdown note into its folder directory on the phone:
  /// e.g. Internal Storage > Download > FileOrganizer > [FolderName] > [FileName]
  Future<String> persistFileToFolder({
    required String folderName,
    required String fileName,
    String? sourcePath,
    String? rawContent,
  }) async {
    try {
      final vaultDir = await getPublicVaultDirectory();
      final sanitizedFolder = folderName.replaceAll(RegExp(r'[\/:*?"<>|]'), '_').trim();
      final folderDir = Directory('${vaultDir.path}/$sanitizedFolder');
      if (!await folderDir.exists()) {
        await folderDir.create(recursive: true);
      }

      final sanitizedFile = fileName.replaceAll(RegExp(r'[\/:*?"<>|]'), '_').trim();
      final destFile = File('${folderDir.path}/$sanitizedFile');

      if (sourcePath != null && sourcePath.isNotEmpty && sourcePath != destFile.path) {
        final src = File(sourcePath);
        if (await src.exists()) {
          // Copy and overwrite existing file
          await src.copy(destFile.path);
          debugPrint('Copied physical file to vault: ${destFile.path}');
        }
      } else if (rawContent != null && rawContent.isNotEmpty) {
        // Write markdown text content
        await destFile.writeAsString(rawContent);
        debugPrint('Saved Markdown file to vault: ${destFile.path}');
      }

      return destFile.path;
    } catch (e) {
      debugPrint('Error persisting file to folder: $e');
      return sourcePath ?? '';
    }
  }

  /// Creates a single, complete, overwriteable ZIP archive of the entire vault:
  /// Includes ALL physical files (PDFs, images, notes) organized in folders + folders_config.json.
  /// Overwrites Download/FileOrganizer/FileOrganizer_Vault.zip (preserving a .bak safety file).
  Future<File> createExportArchive() async {
    final vaultDir = await getPublicVaultDirectory();

    // 1. Always save latest folders_config.json into vault root
    final configJson = await _configService.exportConfigJson();
    final configFile = File('${vaultDir.path}/folders_config.json');
    await configFile.writeAsString(configJson);

    // 2. Package all folders, actual files, and config into Archive
    final archive = Archive();

    // Add folders_config.json
    final configBytes = utf8.encode(configJson);
    archive.addFile(ArchiveFile('folders_config.json', configBytes.length, configBytes));

    // Recursively collect all actual media, docs, and notes from folder subdirectories
    await for (final entity in vaultDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final fileName = entity.path.split('/').last.split('\\').last;
        // Skip existing zip archives from being zipped into themselves
        if (fileName.toLowerCase().endsWith('.zip') || fileName.toLowerCase().endsWith('.bak')) {
          continue;
        }

        try {
          final relativePath = entity.path.substring(vaultDir.path.length + 1).replaceAll('\\', '/');
          if (relativePath != 'folders_config.json') {
            final fileBytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(relativePath, fileBytes.length, fileBytes));
          }
        } catch (e) {
          debugPrint('Error adding ${entity.path} to zip: $e');
        }
      }
    }

    // 3. Encode into ZIP format
    final zipEncoder = ZipEncoder();
    final encodedZip = zipEncoder.encode(archive);
    if (encodedZip == null) {
      throw Exception('Failed to encode ZIP archive');
    }

    // 4. Overwrite master zip with single .bak safety backup
    final masterZip = File('${vaultDir.path}/FileOrganizer_Vault.zip');
    final backupZip = File('${vaultDir.path}/FileOrganizer_Vault.zip.bak');

    if (await masterZip.exists()) {
      try {
        await masterZip.copy(backupZip.path);
      } catch (e) {
        debugPrint('Backup safety copy error: $e');
      }
    }

    await masterZip.writeAsBytes(encodedZip, flush: true);
    debugPrint('Overwrote master vault archive at: ${masterZip.path} (${encodedZip.length} bytes)');
    return masterZip;
  }

  /// Trigger Option A: Google Drive Upload via Native Android System Chooser
  /// Compresses all actual files and invokes Android system share sheet with "Save to Drive"
  Future<bool> syncWithGoogleDrive() async {
    _googleDriveStatus = SyncStatus.syncing;
    try {
      // 1. Build or overwrite the complete master vault ZIP containing all real files
      final masterZip = await createExportArchive();

      // 2. Share directly with Android Chooser (allowing user to tap "Save to Google Drive")
      if (!kIsWeb) {
        await _platformChannel.invokeMethod('shareFileWithChooser', {
          'filePath': masterZip.path,
          'title': 'Save Vault to Google Drive / Share',
          'mimeType': 'application/zip',
        });
      }

      _lastGoogleDriveSync = DateTime.now();
      _googleDriveStatus = SyncStatus.success;
      return true;
    } catch (e) {
      debugPrint('Google Drive Sync error: $e');
      _googleDriveStatus = SyncStatus.error;
      return false;
    }
  }

  /// Restore everything from an export archive (supports .zip, .fo_backup, or .json)
  Future<bool> restoreFromArchive(File backupFile) async {
    try {
      final ext = backupFile.path.toLowerCase();
      final vaultDir = await getPublicVaultDirectory();

      if (ext.endsWith('.zip')) {
        // Unzip all files, folders, and config back into place
        final bytes = await backupFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        String? restoredConfigJson;

        for (final file in archive) {
          if (file.isFile) {
            final data = file.content as List<int>;
            if (file.name == 'folders_config.json') {
              restoredConfigJson = utf8.decode(data);
            }
            final outFile = File('${vaultDir.path}/${file.name}');
            await outFile.parent.create(recursive: true);
            await outFile.writeAsBytes(data, flush: true);
          }
        }

        if (restoredConfigJson != null && restoredConfigJson.isNotEmpty) {
          await _configService.importConfigJson(restoredConfigJson);
          return true;
        }
      } else {
        // JSON or legacy .fo_backup
        final content = await backupFile.readAsString();
        final dynamic decoded = jsonDecode(content);

        if (decoded is List) {
          return await _configService.importConfigJson(content);
        } else if (decoded is Map<String, dynamic> && decoded.containsKey('config')) {
          final configList = decoded['config'];
          return await _configService.importConfigJson(jsonEncode(configList));
        }
      }

      return false;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  /// Pick and import backup file directly from Google Drive or local device
  Future<bool> pickAndImportFromDriveOrStorage() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isNotEmpty && files.first.path != null) {
        final pickedFile = File(files.first.path!);
        final ext = files.first.name.toLowerCase();

        if (ext.endsWith('.zip') || ext.endsWith('.fo_backup') || ext.endsWith('.json')) {
          return await restoreFromArchive(pickedFile);
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return false;
    }
  }

  /// Full Import everything from Google Drive (Option A: opens file picker to choose from Drive)
  Future<bool> importEverythingFromGoogleDrive() async {
    return await pickAndImportFromDriveOrStorage();
  }
}
