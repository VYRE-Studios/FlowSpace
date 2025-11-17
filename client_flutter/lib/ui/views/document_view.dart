import 'package:flutter/material.dart';
import '../../services/document_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class DocumentView extends StatefulWidget {
  const DocumentView({super.key});

  @override
  State<DocumentView> createState() => _DocumentViewState();
}

class _DocumentViewState extends State<DocumentView> {
  String? _workspaceId;
  List<Map<String, dynamic>> _documents = [];
  String? _selectedDocumentId;
  List<Map<String, dynamic>> _blocks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkspaceAndDocuments();
  }

  Future<void> _loadWorkspaceAndDocuments() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) return;

      final workspaces = await DatabaseService.getUserWorkspaces(user['id'] as String);
      if (workspaces.isEmpty) return;

      final workspace = workspaces.first;
      final documents = await DocumentService.getWorkspaceDocuments(workspace['id'] as String);

      if (!mounted) return;
      setState(() {
        _workspaceId = workspace['id'] as String;
        _documents = documents;
        _loading = false;
      });

      // Auto-select first document
      if (documents.isNotEmpty) {
        await _selectDocument(documents.first['id'] as String);
      }
    } catch (e) {
      print('Document: Error loading: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _selectDocument(String documentId) async {
    final blocks = await DocumentService.getDocumentBlocks(documentId);
    if (!mounted) return;
    setState(() {
      _selectedDocumentId = documentId;
      _blocks = blocks;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        _buildDocumentSidebar(),
        const VerticalDivider(width: 1, color: Color(0x11FFFFFF)),
        Expanded(child: _buildDocumentEditor()),
      ],
    );
  }

  Widget _buildDocumentSidebar() {
    return Container(
      width: 280,
      color: const Color(0xFF111111),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documents',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _createNewDocument,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Document'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _documents.isEmpty
                ? const Center(
                    child: Text(
                      'No documents yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      final isSelected = doc['id'] == _selectedDocumentId;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: const Color(0xFF1E1E1E),
                        title: Text(
                          doc['title'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: Colors.white54,
                          onPressed: () => _deleteDocument(doc['id'] as String),
                        ),
                        onTap: () => _selectDocument(doc['id'] as String),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentEditor() {
    if (_selectedDocumentId == null) {
      return const Center(
        child: Text(
          'Select a document to edit',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final document = _documents.firstWhere((d) => d['id'] == _selectedDocumentId);

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocumentTitle(document),
          const SizedBox(height: 24),
          _buildToolbar(),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _blocks.length,
              itemBuilder: (context, index) => _buildBlock(_blocks[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTitle(Map<String, dynamic> document) {
    return TextField(
      controller: TextEditingController(text: document['title'] as String),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      decoration: const InputDecoration(
        hintText: 'Untitled Document',
        hintStyle: TextStyle(color: Colors.white38),
        border: InputBorder.none,
      ),
      onSubmitted: (value) => DocumentService.updateDocumentTitle(
        documentId: _selectedDocumentId!,
        title: value,
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        _toolbarButton(Icons.title, 'Heading', () => _addBlock('heading')),
        _toolbarButton(Icons.format_align_left, 'Paragraph', () => _addBlock('paragraph')),
        _toolbarButton(Icons.format_list_bulleted, 'List', () => _addBlock('list')),
        _toolbarButton(Icons.code, 'Code', () => _addBlock('code')),
      ],
    );
  }

  Widget _toolbarButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white70),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  Widget _buildBlock(Map<String, dynamic> block, int index) {
    final blockType = block['block_type'] as String;
    final content = block['content'] as String;
    final blockId = block['id'] as String;

    TextStyle textStyle;
    String hintText;

    switch (blockType) {
      case 'heading':
        textStyle = const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        );
        hintText = 'Heading';
        break;
      case 'list':
        textStyle = const TextStyle(color: Colors.white, fontSize: 16);
        hintText = '• List item';
        break;
      case 'code':
        textStyle = const TextStyle(
          color: Colors.greenAccent,
          fontSize: 14,
          fontFamily: 'monospace',
        );
        hintText = 'Code block';
        break;
      default: // paragraph
        textStyle = const TextStyle(color: Colors.white, fontSize: 16);
        hintText = 'Type something...';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: blockType == 'code' ? const Color(0xFF0D1117) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(text: content)..selection = TextSelection.collapsed(offset: content.length),
              style: textStyle,
              maxLines: null,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                DocumentService.updateBlockContent(
                  blockId: blockId,
                  content: value,
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.white38,
            onPressed: () => _deleteBlock(blockId),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewDocument() async {
    if (_workspaceId == null) return;

    final docId = await DocumentService.createDocument(
      workspaceId: _workspaceId!,
      title: 'New Document',
    );

    await _loadWorkspaceAndDocuments();
    await _selectDocument(docId);
  }

  Future<void> _addBlock(String blockType) async {
    if (_selectedDocumentId == null) return;

    await DocumentService.addBlock(
      documentId: _selectedDocumentId!,
      blockType: blockType,
      content: '',
      order: _blocks.length,
    );

    await _selectDocument(_selectedDocumentId!);
  }

  Future<void> _deleteBlock(String blockId) async {
    await DocumentService.deleteBlock(blockId);
    if (_selectedDocumentId != null) {
      await _selectDocument(_selectedDocumentId!);
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    await DocumentService.deleteDocument(documentId);
    setState(() {
      _documents.removeWhere((d) => d['id'] == documentId);
      if (_selectedDocumentId == documentId) {
        _selectedDocumentId = null;
        _blocks = [];
      }
    });
  }
}
