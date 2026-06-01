import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/book_api.dart';
import '../../api/bookshelf_api.dart';
import '../../api/upload_api.dart';
import '../../config/app_colors.dart';
import '../../widgets/wr_card.dart';
import '../../widgets/wr_text_field.dart';

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
      allowedExtensions: ['txt', 'epub'],
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  String _inferFileType(String extension) {
    switch (extension.toLowerCase()) {
      case 'epub':
        return 'EPUB';
      case 'txt':
        return 'TXT';
      default:
        return 'EPUB';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
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

      final result = await BookApi.createBook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        fileUrl: fileUrl,
        fileType: fileType,
        fileSizeBytes: fileSize,
        description: _descController.text.trim().isNotEmpty
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('导入书籍'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilePicker(),
            if (_isUploading && _uploadProgress > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.searchBg,
                  color: AppColors.primary,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '上传中 ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
            WrCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  WrTextField(
                    controller: _titleController,
                    hint: '书名 *',
                    icon: Icons.menu_book_outlined,
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 12),
                  WrTextField(
                    controller: _authorController,
                    hint: '作者 *',
                    icon: Icons.person_outline,
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 12),
                  WrTextField(
                    controller: _descController,
                    hint: '简介（可选）',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                    enabled: !_isUploading,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '支持 TXT、EPUB 格式',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: AppColors.iconCoral)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isUploading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '导入到书架',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    final selected = _selectedFile;

    return GestureDetector(
      onTap: _isUploading ? null : _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected != null ? AppColors.primary : AppColors.border,
            width: selected != null ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected != null ? Icons.description_outlined : Icons.upload_file,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              selected?.name ?? '点击选择电子书文件',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              selected != null
                  ? _formatSize(selected.size)
                  : 'TXT / EPUB',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
