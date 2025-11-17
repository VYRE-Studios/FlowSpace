import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/vault_service.dart';
import '../../services/workspace_service.dart';

class VaultView extends StatefulWidget {
  const VaultView({super.key});

  @override
  State<VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends State<VaultView> {
  bool _loading = true;
  bool _bootstrapLoading = true;

  String? _error;
  String? _workspaceId;
  List<Map<String, dynamic>> _files = [];
  Map<String, dynamic>? _selectedFile;
  Set<String> _expandedFolders = {'shared'}; // Default to showing shared folder

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _bootstrapLoading = true;
      _error = null;
    });

    try {
      // Load from local storage
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _error = 'No user found';
          _bootstrapLoading = false;
          _loading = false;
        });
        return;
      }

      final userId = user['id'] as String;
      final workspaces = await DatabaseService.getUserWorkspaces(userId);

      if (!mounted) return;

      setState(() {
        _workspaceId = workspaces.isNotEmpty ? workspaces.first['id'] as String : null;
        _bootstrapLoading = false;
      });

      // Load vault from local storage
      await _fetchFiles();
    } catch (e) {
      print('Vault: Error loading: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load vault';
        _bootstrapLoading = false;
        _loading = false;
      });
    }
  }

  Future<void> _fetchFiles() async {
    final workspaceId = _workspaceId;
    
    setState(() {
      _loading = true;
      _error = null;
    });

    // If no workspace, show empty vault
    if (workspaceId == null) {
      if (!mounted) return;
      setState(() {
        _files = const [];
        _selectedFile = null;
        _loading = false;
      });
      return;
    }

    try {
      // Load vault files from SQLite
      final filesList = await DatabaseService.getWorkspaceVaultFiles(workspaceId);

      if (!mounted) return;
      setState(() {
        _files = filesList;
        _selectedFile = _files.isNotEmpty ? _files.first : null;
        _loading = false;
      });
    } catch (e) {
      print('Vault: Error loading files: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load vault files';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 380,
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  border: Border(right: BorderSide(color: Color(0x22FFFFFF))),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _handleUpload,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Upload File'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: _buildFileList()),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.04),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _buildPreview(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildFileList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState(_error!, _fetchFiles);
    }

    if (_files.isEmpty) {
      return _buildGhostState(Icons.folder_open);
    }

    // Organize files by folder and subfolder structure
    final Map<String, Map<String, List<Map<String, dynamic>>>> folderStructure = {};
    
    for (final file in _files) {
      final folder = file['folder'] as String? ?? 'shared';
      final filePath = file['file_path'] as String? ?? '';
      
      // Parse path for nested folders (e.g., "folder1/subfolder/file.txt")
      final pathParts = filePath.split('/').where((p) => p.isNotEmpty).toList();
      String currentPath = folder;
      
      // If file is in a subfolder, organize by folder/subfolder
      if (pathParts.length > 1) {
        // Remove filename, keep folder path
        final folderPath = pathParts.sublist(0, pathParts.length - 1).join('/');
        currentPath = '$folder/$folderPath';
      }
      
      // Initialize folder structure
      if (!folderStructure.containsKey(folder)) {
        folderStructure[folder] = {};
      }
      
      // Add file to appropriate subfolder
      final subfolder = pathParts.length > 1 
          ? pathParts.sublist(0, pathParts.length - 1).join('/')
          : '';
      
      folderStructure[folder]!.putIfAbsent(subfolder, () => []).add(file);
    }

    // Build tree structure - flatten for now, but organized by folder
    final folders = folderStructure.keys.toList()..sort();
    
    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, folderIndex) {
        final folder = folders[folderIndex];
        final subfolders = folderStructure[folder]!;
        final isExpanded = _expandedFolders.contains(folder);
        
        // Count total files in folder (including subfolders)
        final totalFiles = subfolders.values.fold<int>(0, (sum, files) => sum + files.length);
        
        return Column(
          children: [
            // Folder header
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedFolders.remove(folder);
                  } else {
                    _expandedFolders.add(folder);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.folder_open : Icons.folder,
                      color: const Color(0xFF0066FF),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        folder.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '$totalFiles',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            // Files in folder (including subfolders)
            if (isExpanded)
              ...subfolders.entries.expand((entry) {
                final subfolder = entry.key;
                final folderFiles = entry.value;
                
                // If subfolder is empty (root of folder), just show files
                if (subfolder.isEmpty) {
                  return folderFiles.map((file) => _buildFileItem(file));
                }
                
                // Otherwise show subfolder with files
                final subfolderKey = '$folder/$subfolder';
                final isSubfolderExpanded = _expandedFolders.contains(subfolderKey);
                
                return [
                  // Subfolder header
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isSubfolderExpanded) {
                          _expandedFolders.remove(subfolderKey);
                        } else {
                          _expandedFolders.add(subfolderKey);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.only(left: 50, right: 18, top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSubfolderExpanded ? Icons.folder_open : Icons.folder,
                            color: const Color(0xFF0066FF).withValues(alpha: 0.7),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subfolder,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            '${folderFiles.length}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isSubfolderExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Files in subfolder
                  if (isSubfolderExpanded)
                    ...folderFiles.map((file) => _buildFileItem(file, indent: 80)),
                ];
              }),
          ],
        );
      },
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file, {double indent = 50}) {
    final selected = identical(file, _selectedFile);
    final name = file['name'] as String? ?? 'Untitled';
    
    return InkWell(
      onTap: () => setState(() => _selectedFile = file),
      child: Container(
        padding: EdgeInsets.only(left: indent, right: 18, top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0066FF).withValues(alpha: 0.15)
              : null,
          border: Border(
            left: BorderSide(
              color: selected
                  ? const Color(0xFF0066FF)
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.white54, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatSize(file['size'] as int? ?? 0)} • ${_formatDate(file['uploaded_at'] as String?)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _selectedFile == null) {
      return _buildGhostState(Icons.description_outlined);
    }

    final file = _selectedFile!;
    final name = file['name'] as String? ?? 'Untitled';
    final url = file['url'] as String? ?? '';
    final contentType = file['contentType'] as String? ?? 'application/octet-stream';

    return Padding(
      key: ValueKey(file['id'] ?? name),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Type: $contentType',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'Size: ${_formatSize(file['size'] as int? ?? 0)}',
            style: const TextStyle(color: Colors.white54),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: FilledButton.icon(
              onPressed: url.isEmpty ? null : () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text('Download'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGhostState(IconData icon) {
    return Center(
      child: Opacity(
        opacity: 0.35,
        child: Icon(icon, size: 64, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState(String message, Future<void> Function() onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: 0.5,
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    return '${local.month}/${local.day}/${local.year} ${TimeOfDay.fromDateTime(local).format(context)}';
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '';
    return '${parsed.month}/${parsed.day}/${parsed.year}';
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  void _handleUpload() async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No workspace selected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;

    final file = File(filePath);

    try {
      await VaultService.uploadFile(workspaceId, file);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File uploaded!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      await _fetchFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
