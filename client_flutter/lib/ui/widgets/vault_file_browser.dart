import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class VaultFileBrowser extends StatefulWidget {
  final String projectPath;
  final Function(File)? onFileSelected;
  
  const VaultFileBrowser({
    super.key,
    required this.projectPath,
    this.onFileSelected,
  });

  @override
  State<VaultFileBrowser> createState() => _VaultFileBrowserState();
}

class _VaultFileBrowserState extends State<VaultFileBrowser> {
  List<FileSystemEntity> _items = [];
  String _currentPath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.projectPath;
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    
    try {
      final dir = Directory(_currentPath);
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        entities.sort((a, b) {
          // Folders first, then files, alphabetical
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          return path.basename(a.path).toLowerCase().compareTo(
            path.basename(b.path).toLowerCase()
          );
        });
        setState(() {
          _items = entities;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('FlowSpace: Error loading vault files: $e');
      setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(FileSystemEntity entity) {
    if (entity is Directory) {
      return Icons.folder;
    }
    
    final ext = path.extension(entity.path).toLowerCase();
    switch (ext) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.folder_zip;
      case '.txt':
      case '.md':
        return Icons.article;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _onItemTap(FileSystemEntity entity) async {
    if (entity is Directory) {
      setState(() {
        _currentPath = entity.path;
      });
      await _loadItems();
    } else if (entity is File) {
      widget.onFileSelected?.call(entity);
    }
  }

  void _navigateUp() {
    final parent = Directory(_currentPath).parent;
    // Don't go above project root
    if (parent.path.startsWith(widget.projectPath)) {
      setState(() {
        _currentPath = parent.path;
      });
      _loadItems();
    }
  }

  String _getRelativePath() {
    if (_currentPath == widget.projectPath) {
      return '/';
    }
    return _currentPath.substring(widget.projectPath.length);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Breadcrumb / Path bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
          ),
          child: Row(
            children: [
              if (_currentPath != widget.projectPath)
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: _navigateUp,
                  tooltip: 'Go up',
                ),
              Expanded(
                child: Text(
                  _getRelativePath(),
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _loadItems,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        
        // File list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text(
                            'No files yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final name = path.basename(item.path);
                        final isDir = item is Directory;
                        
                        return ListTile(
                          leading: Icon(_getIcon(item)),
                          title: Text(name),
                          subtitle: !isDir
                              ? FutureBuilder<FileStat>(
                                  future: item.stat(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return const SizedBox();
                                    final size = snapshot.data!.size;
                                    return Text(_formatBytes(size));
                                  },
                                )
                              : null,
                          trailing: isDir ? const Icon(Icons.chevron_right) : null,
                          onTap: () => _onItemTap(item),
                          onLongPress: () => _showContextMenu(context, item),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showContextMenu(BuildContext context, FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(path.basename(entity.path)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Properties'),
              onTap: () {
                Navigator.pop(context);
                _showProperties(context, entity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, entity);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProperties(BuildContext context, FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Properties'),
        content: FutureBuilder<FileStat>(
          future: entity.stat(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            final stat = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${path.basename(entity.path)}'),
                const SizedBox(height: 8),
                Text('Type: ${entity is Directory ? 'Folder' : 'File'}'),
                const SizedBox(height: 8),
                if (entity is File) Text('Size: ${_formatBytes(stat.size)}'),
                const SizedBox(height: 8),
                Text('Modified: ${stat.modified}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Are you sure you want to delete "${path.basename(entity.path)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (entity is Directory) {
                  await entity.delete(recursive: true);
                } else {
                  await entity.delete();
                }
                _loadItems();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
