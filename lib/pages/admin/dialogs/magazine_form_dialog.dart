import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../models/magazine.dart';
import '../../../services/appwrite_service.dart';

class MagazineFormDialog extends StatefulWidget {
  final Magazine? magazine;

  const MagazineFormDialog({super.key, this.magazine});

  @override
  State<MagazineFormDialog> createState() => _MagazineFormDialogState();
}

class _MagazineFormDialogState extends State<MagazineFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  File? _coverImage;
  String _frequency = 'monthly';
  String _category = 'general';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.magazine != null) {
      _titleController.text = widget.magazine!.title;
      _descriptionController.text = widget.magazine!.description;
      _priceController.text = widget.magazine!.price.toString();
      _frequency = widget.magazine!.frequency;
      _category = widget.magazine!.category;
    }
  }

  Future<void> _pickCoverImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _coverImage = File(result.files.single.path!);
      });
    }
  }

  Future<void> _saveMagazine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String coverFileId = widget.magazine?.coverUrl ?? '';

      // Upload cover image if selected
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
          fileName: '${_titleController.text}_cover.jpg',
        );
      }

      // Create magazine data
      final magazineData = Magazine(
        id: widget.magazine?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        coverUrl: coverFileId,
        price: double.parse(_priceController.text),
        frequency: _frequency,
        category: _category,
        isActive: true,
        nextIssueDate: _calculateNextIssueDate(_frequency, DateTime.now()),
      );

      await FirebaseDatabase.instance
          .ref()
          .child('magazines')
          .child(magazineData.id)
          .set(magazineData.toJson());

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving magazine: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  DateTime _calculateNextIssueDate(String frequency, DateTime startDate) {
    switch (frequency) {
      case 'weekly':
        return startDate.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case 'quarterly':
        return DateTime(startDate.year, startDate.month + 3, startDate.day);
      default:
        return startDate.add(const Duration(days: 7));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.magazine == null ? 'Add Magazine' : 'Edit Magazine'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter a description'
                    : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a price' : null,
              ),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: ['weekly', 'monthly', 'quarterly']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (value) => setState(() => _frequency = value!),
              ),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  'general',
                  'sports',
                  'technology',
                  'lifestyle',
                  'business'
                ]
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickCoverImage,
                child: Text(_coverImage == null
                    ? 'Select Cover Image'
                    : 'Change Cover Image'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveMagazine,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
