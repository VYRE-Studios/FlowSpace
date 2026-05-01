import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/colors.dart';
import '../../core/theme/flo_theme.dart';
import '../../services/vault_service.dart';
import '../../services/workspace_service.dart';
import '../../state/active_workspace_state.dart';

/// Vault - backend-backed workspace file storage.
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String? _workspaceId;
  List<Map<String, dynamic>> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<String?> _resolveWorkspaceId() async {
    if (_workspaceId != null) return _workspaceId;

    final activeWorkspace = context.read<ActiveWorkspaceState>();
    if (activeWorkspace.activeWorkspaceId != null) {
      _workspaceId = activeWorkspace.activeWorkspaceId;
      return _workspaceId;
    }

    final bootstrap = await WorkspaceService.getWorkspaceBootstrap();
    final workspaces = bootstrap['workspaces'] as List? ?? const [];
    if (workspaces.isEmpty) return null;

    final workspace = Map<String, dynamic>.from(workspaces.first as Map);
    activeWorkspace.setActiveWorkspace(workspace);
    _workspaceId = workspace['id'] as String?;
    return _workspaceId;
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final workspaceId = await _resolveWorkspaceId();
      if (workspaceId == null) {
        if (!mounted) return;
        setState(() {
          _files = [];
          _error = 'No workspace is available for this account yet.';
          _loading = false;
        });
        return;
      }

      final result = await VaultService.getRecentFiles(workspaceId);
      if (!mounted) return;
      setState(() {
        _files = result.files;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load vault files.';
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final workspaceId = await _resolveWorkspaceId();
    if (workspaceId == null) return;

    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _uploading = true);
    try {
      await VaultService.uploadFile(workspaceId, File(path));
      await _loadFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    try {
      await VaultService.deleteFile(file['id'] as String);
      await _loadFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _openFile(Map<String, dynamic> file) async {
    final url = file['url'] as String?;
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open file URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(
                bottom: BorderSide(color: AppColors.borderSofter),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Text('Vault', style: FloTheme.titleMedium),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _loadFiles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(_uploading ? 'Uploading' : 'Upload'),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _VaultEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Vault unavailable',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _loadFiles,
      );
    }

    if (_files.isEmpty) {
      return _VaultEmptyState(
        icon: Icons.folder_open_outlined,
        title: 'No files yet',
        message: 'Upload files to make them available to this workspace.',
        actionLabel: 'Upload file',
        onAction: _pickAndUpload,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = _files[index];
        final name = file['name'] as String? ?? 'Untitled file';
        final size = file['size'] as int? ?? 0;
        final uploadedAt = file['uploadedAt'] as String? ?? file['uploaded_at'] as String?;
        final uploadedDate = uploadedAt?.split('T').first;
        final subtitle = '${_formatBytes(size)}${uploadedDate == null ? '' : ' - $uploadedDate'}';

        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSofter),
          ),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary),
            title: Text(name, style: FloTheme.bodyPrimary),
            subtitle: Text(
              subtitle,
              style: FloTheme.caption,
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  tooltip: 'Open',
                  icon: const Icon(Icons.open_in_new, color: AppColors.textSecondary),
                  onPressed: () => _openFile(file),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                  onPressed: () => _deleteFile(file),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(1)} GB';
  }
}

class _VaultEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _VaultEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMeta),
            const SizedBox(height: 16),
            Text(title, style: FloTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: FloTheme.bodySecondary, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
