import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/book_api.dart';
import '../../api/bookshelf_api.dart';
import '../../api/upload_api.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descController = TextEditingController();

  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'epub', 'pdf', 'mobi'],
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  String _inferFileType(String extension) {
    switch (extension.toLowerCase()) {
      case 'epub':
        return 'EPUB';
      case 'pdf':
        return 'PDF';
      case 'txt':
        return 'TXT';
      case 'mobi':
        return 'MOBI';
      default:
        return 'EPUB';
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null) {
      setState(() => _error = '请先选择文件');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = '请输入书名');
      return;
    }
    if (_authorController.text.trim().isEmpty) {
      setState(() => _error = '请输入作者');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
      _uploadProgress = 0;
    });

    try {
      // 1. Upload file
      final uploadResult = await UploadApi.uploadFile(
        _selectedFile!.path!,
        _selectedFile!.name,
        onProgress: (sent, total) {
          if (total > 0) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );

      if (!mounted) return;

      if (uploadResult['success'] != true) {
        setState(() {
          _error = uploadResult['message'] as String? ?? '上传失败';
          _isUploading = false;
        });
        return;
      }

      final fileUrl = uploadResult['fileUrl'] as String;
      final fileSize = (uploadResult['fileSize'] as num).toDouble();
      final ext = _selectedFile!.name.split('.').last;
      final fileType = _inferFileType(ext);

      // 2. Create book via GraphQL
      final result = await BookApi.createBook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        fileUrl: fileUrl,
        fileType: fileType,
        fileSizeBytes: fileSize,
        description:
            _descController.text.trim().isNotEmpty
                ? _descController.text.trim()
                : null,
      );

      if (!mounted) return;

      if (result.hasException) {
        setState(() {
          _error = result.exception?.graphqlErrors.first.message ?? '创建图书失败';
          _isUploading = false;
        });
        return;
      }

      // 3. Auto-add to bookshelf
      final bookId = result.data?['createBook']?['id'] as String?;
      if (bookId != null) {
        await BookshelfApi.addToBookshelf(bookId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('添加成功，已加入书架')),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '操作失败: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('添加图书')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File picker
            InkWell(
              onTap: _isUploading ? null : _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerLow,
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.insert_drive_file
                          : Icons.upload_file,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile?.name ?? '点击选择电子书文件',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(1)} MB',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_isUploading && _uploadProgress > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 4),
              Text(
                '上传中 ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '书名 *',
                prefixIcon: Icon(Icons.title),
              ),
              enabled: !_isUploading,
            ),
            const SizedBox(height: 16),

            // Author
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: '作者 *',
                prefixIcon: Icon(Icons.person),
              ),
              enabled: !_isUploading,
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: '简介（可选）',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              enabled: !_isUploading,
            ),
            const SizedBox(height: 24),

            // Error
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
            ],

            // Submit
            FilledButton(
              onPressed: _isUploading ? null : _submit,
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('添加图书'),
            ),
          ],
        ),
      ),
    );
  }
}
