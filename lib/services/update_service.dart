import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class UpdateCheckResult {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String? releaseTitle;
  final String? releaseNotes;
  final String? downloadUrl;
  final String? releasePageUrl;
  final String? errorMessage;
  final bool isRepoNotFound;

  UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    this.releaseTitle,
    this.releaseNotes,
    this.downloadUrl,
    this.releasePageUrl,
    this.errorMessage,
    this.isRepoNotFound = false,
  });
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String currentVersion = '1.3.0';

  // Configurable repository target
  String _githubOwner = 'srirajon';
  String _githubRepo = 'FileOrganizer';

  String get githubOwner => _githubOwner;
  String get githubRepo => _githubRepo;

  void configureRepo({required String owner, required String repo}) {
    _githubOwner = owner.trim();
    _githubRepo = repo.trim();
  }

  /// Checks GitHub Releases API for the latest published APK version
  Future<UpdateCheckResult> checkForUpdates() async {
    final url = Uri.parse('https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest');

    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'FileOrganizer-App',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawTag = data['tag_name'] as String? ?? '1.3.0';
        final latestTag = rawTag.replaceAll(RegExp(r'^[vV]'), '');
        final releaseTitle = data['name'] as String? ?? 'Version $rawTag';
        final releaseNotes = data['body'] as String? ?? 'No release notes provided.';
        final releasePageUrl = data['html_url'] as String?;

        // Find APK asset
        String? apkDownloadUrl;
        final assets = data['assets'] as List<dynamic>?;
        if (assets != null) {
          for (final asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (name.toLowerCase().endsWith('.apk')) {
              apkDownloadUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
        }
        if (apkDownloadUrl == null && assets != null && assets.isNotEmpty) {
          apkDownloadUrl = assets.first['browser_download_url'] as String?;
        }

        final isNewer = _isVersionGreater(latestTag, currentVersion);

        return UpdateCheckResult(
          hasUpdate: isNewer,
          currentVersion: currentVersion,
          latestVersion: latestTag,
          releaseTitle: releaseTitle,
          releaseNotes: releaseNotes,
          downloadUrl: apkDownloadUrl,
          releasePageUrl: releasePageUrl,
        );
      } else if (response.statusCode == 404) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          isRepoNotFound: true,
          errorMessage: 'No releases found on GitHub repository: $_githubOwner/$_githubRepo',
        );
      } else {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          errorMessage: 'GitHub API responded with status ${response.statusCode}',
        );
      }
    } catch (e) {
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        errorMessage: 'Network error checking for updates: $e',
      );
    }
  }

  /// Compares semantic versions (e.g. "1.4.0" > "1.3.0")
  bool _isVersionGreater(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      final len = parts1.length > parts2.length ? parts1.length : parts2.length;
      for (int i = 0; i < len; i++) {
        final num1 = i < parts1.length ? parts1[i] : 0;
        final num2 = i < parts2.length ? parts2[i] : 0;
        if (num1 > num2) return true;
        if (num1 < num2) return false;
      }
      return false;
    } catch (_) {
      return v1 != v2;
    }
  }

  /// Shows the interactive update check dialog with instructions
  void showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpdateDialogWidget(service: this),
    );
  }
}

class _UpdateDialogWidget extends StatefulWidget {
  final UpdateService service;
  const _UpdateDialogWidget({required this.service});

  @override
  State<_UpdateDialogWidget> createState() => _UpdateDialogWidgetState();
}

class _UpdateDialogWidgetState extends State<_UpdateDialogWidget> {
  bool _isLoading = true;
  UpdateCheckResult? _result;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _isLoading = true);
    final res = await widget.service.checkForUpdates();
    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
    }
  }

  void _showRepoConfigDialog() {
    final ownerCtrl = TextEditingController(text: widget.service.githubOwner);
    final repoCtrl = TextEditingController(text: widget.service.githubRepo);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure GitHub Repo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Specify your personal GitHub username and repository name where you upload new APK releases.',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ownerCtrl,
              decoration: const InputDecoration(
                labelText: 'GitHub Username / Owner',
                hintText: 'e.g. srirajon',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: repoCtrl,
              decoration: const InputDecoration(
                labelText: 'Repository Name',
                hintText: 'e.g. FileOrganizer',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: WhatsAppTheme.accentGreen, foregroundColor: Colors.white),
            onPressed: () {
              widget.service.configureRepo(owner: ownerCtrl.text, repo: repoCtrl.text);
              Navigator.pop(ctx);
              _check();
            },
            child: const Text('Save & Check'),
          ),
        ],
      ),
    );
  }

  void _showHowToPublishGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.help_outline_rounded, color: WhatsAppTheme.accentGreen),
                      SizedBox(width: 8),
                      Text('How to Upload APK to GitHub', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: const [
                    _GuideStep(
                      step: '1',
                      title: 'Create Repository on GitHub',
                      desc: 'Go to github.com -> Click "+" -> "New repository". Set name to "FileOrganizer", choose Public (or Private), and click "Create repository".',
                    ),
                    _GuideStep(
                      step: '2',
                      title: 'Open Releases Page',
                      desc: 'On your GitHub repository page, look on the right sidebar and click "Releases", then click "Draft a new release".',
                    ),
                    _GuideStep(
                      step: '3',
                      title: 'Choose Tag & Title',
                      desc: 'In "Choose a tag", type v1.3.0 (or v1.4.0 for new updates). In Release title, type "File Organizer v1.3.0".',
                    ),
                    _GuideStep(
                      step: '4',
                      title: 'Attach the .APK File',
                      desc: 'Drag & drop the "FileOrganizer_v1.3.apk" file into the box that says "Attach binaries by dropping them here or selecting them".',
                    ),
                    _GuideStep(
                      step: '5',
                      title: 'Click "Publish Release"',
                      desc: 'Hit "Publish release"! The app will now automatically detect new releases whenever you tap "Check for Updates"!',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? WhatsAppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: WhatsAppTheme.accentGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.system_update_rounded, color: WhatsAppTheme.accentGreen, size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Software Update',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: WhatsAppTheme.accentGreen),
                  SizedBox(height: 14),
                  Text('Checking GitHub releases...', style: TextStyle(fontSize: 13)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Version Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Installed: v${UpdateService.currentVersion}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      InkWell(
                        onTap: _showRepoConfigDialog,
                        child: Row(
                          children: [
                            Text(
                              '${widget.service.githubOwner}/${widget.service.githubRepo}',
                              style: const TextStyle(fontSize: 11, color: WhatsAppTheme.accentGreen),
                            ),
                            const Icon(Icons.edit, size: 12, color: WhatsAppTheme.accentGreen),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  if (_result != null && _result!.hasUpdate) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: WhatsAppTheme.accentGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.new_releases_rounded, color: WhatsAppTheme.accentGreen, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Version Available: v${_result!.latestVersion}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                if (_result!.releaseTitle != null)
                                  Text(
                                    _result!.releaseTitle!,
                                    style: const TextStyle(fontSize: 11.5, color: WhatsAppTheme.darkTextSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('What\'s New:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141E24) : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _result!.releaseNotes ?? 'Maintenance and improvements.',
                          style: const TextStyle(fontSize: 11.5, height: 1.3),
                        ),
                      ),
                    ),
                  ] else if (_result != null && _result!.isRepoNotFound) ...[
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No releases found on GitHub yet.',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can easily upload your APK to your personal GitHub repository so your phone can update with 1 click.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.help_outline_rounded, size: 16),
                      label: const Text('How to upload APK to GitHub', style: TextStyle(fontSize: 12)),
                      onPressed: _showHowToPublishGuide,
                    ),
                  ] else ...[
                    Row(
                      children: const [
                        Icon(Icons.check_circle_rounded, color: WhatsAppTheme.accentGreen, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'File Organizer is Up to Date!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You are using the latest version (v${UpdateService.currentVersion}).',
                      style: const TextStyle(fontSize: 12.5, color: WhatsAppTheme.darkTextSecondary),
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        if (_result != null && _result!.isRepoNotFound)
          TextButton(
            onPressed: _showRepoConfigDialog,
            child: const Text('Change Repo', style: TextStyle(color: WhatsAppTheme.accentGreen)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_result != null && _result!.hasUpdate && _result!.downloadUrl != null)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: WhatsAppTheme.accentGreen,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download APK', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              final uri = Uri.parse(_result!.downloadUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String step;
  final String title;
  final String desc;

  const _GuideStep({required this.step, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: WhatsAppTheme.accentGreen,
            child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(fontSize: 12.5, color: WhatsAppTheme.darkTextSecondary, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
