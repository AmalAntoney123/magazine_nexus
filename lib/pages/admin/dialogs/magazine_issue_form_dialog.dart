import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../models/magazine_issue.dart';
import '../../../services/appwrite_service.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../widgets/common/bottom_modal.dart';

class MagazineIssueFormDialog extends StatefulWidget {
  final String magazineId;
  final DateTime publishDate;
  final int issueNumber;
  final MagazineIssue? existingIssue;

  const MagazineIssueFormDialog({
    super.key,
    required this.magazineId,
    required this.publishDate,
    required this.issueNumber,
    this.existingIssue,
  });

  @override
  State<MagazineIssueFormDialog> createState() =>
      _MagazineIssueFormDialogState();
}

class _MagazineIssueFormDialogState extends State<MagazineIssueFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _coverImage;
  File? _pdfFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingIssue != null) {
      _titleController.text = widget.existingIssue!.title;
      _descriptionController.text = widget.existingIssue!.description;
    }
  }

  Future<void> _saveMagazineIssue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pdfFile == null && widget.existingIssue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String coverFileId = widget.existingIssue?.coverUrl ?? '';
      String pdfFileId = widget.existingIssue?.pdfFileId ?? '';

      // Handle file uploads similar to the original magazine form
      if (_coverImage != null) {
        if (coverFileId.isNotEmpty) {
          await AppwriteService.deleteFile(
            bucketId: '67718720002aaa542f4d',
            fileId: coverFileId,
          );
        }
        coverFileId = await AppwriteService.uploadFile(
          bucketId: '67718720002aaa542f4d',
          file: _coverImage!,
          fileName: '${widget.magazineId}_${widget.issueNumber}_cover.jpg',
        );
      }

      if (_pdfFile != null) {
        if (pdfFileId.isNotEmpty) {
          await AppwriteService.deleteFile(
            bucketId: '67718396003a69711df7',
            fileId: pdfFileId,
          );
        }
        pdfFileId = await AppwriteService.uploadFile(
          bucketId: '67718396003a69711df7',
          file: _pdfFile!,
          fileName: '${widget.magazineId}_${widget.issueNumber}.pdf',
        );
      }

      final issueData = MagazineIssue(
        id: widget.existingIssue?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        magazineId: widget.magazineId,
        title: _titleController.text,
        description: _descriptionController.text,
        coverUrl: coverFileId,
        pdfFileId: pdfFileId,
        issueNumber: widget.issueNumber,
        publishDate: widget.publishDate,
      );

      await FirebaseDatabase.instance
          .ref()
          .child('magazine_issues')
          .child(issueData.id)
          .set(issueData.toJson());

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving issue: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _coverImage = File(result.files.first.path!);
      });
    }
  }

  Future<void> _pickPDFFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pdfFile = File(result.files.first.path!);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomModal(
      title: widget.existingIssue == null ? 'Add Issue' : 'Edit Issue',
      isLoading: _isLoading,
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _saveMagazineIssue,
          child: const Text('Save'),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Input
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),

            // Description Input
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 24),

            // File Selection Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Files',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Cover Image Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Cover Image',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickCoverImage,
                        icon: const Icon(Icons.image),
                        label: Text(_coverImage == null
                            ? 'Select Image'
                            : 'Change Image'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      ),
                      if (_coverImage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Selected: ${_coverImage!.path.split('/').last}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // PDF File Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PDF File',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickPDFFile,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(
                            _pdfFile == null ? 'Select PDF' : 'Change PDF'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      ),
                      if (_pdfFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Selected: ${_pdfFile!.path.split('/').last}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
