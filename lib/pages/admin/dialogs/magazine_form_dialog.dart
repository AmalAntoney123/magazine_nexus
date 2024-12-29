import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
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
  final _issueNumberController = TextEditingController();

  File? _coverImage;
  File? _pdfFile;
  String _frequency = 'monthly';
  String _category = 'general';
  DateTime _publishDate = DateTime.now();
  bool _isLoading = false;

  final Client client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('676fc20b003ccf154826');
  late final Storage storage;

  @override
  void initState() {
    super.initState();
    storage = Storage(client);
    if (widget.magazine != null) {
      _titleController.text = widget.magazine!.title;
      _descriptionController.text = widget.magazine!.description;
      _priceController.text = widget.magazine!.price.toString();
      _issueNumberController.text = widget.magazine!.issueNumber.toString();
      _frequency = widget.magazine!.frequency;
      _category = widget.magazine!.category;
      _publishDate = widget.magazine!.publishDate;
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

  Future<void> _pickPDFFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _saveMagazine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pdfFile == null && widget.magazine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String coverFileId = widget.magazine?.coverUrl ?? '';
      String pdfFileId = widget.magazine?.pdfFileId ?? '';

      print("Starting magazine save process...");
      print("Initial PDF ID: $pdfFileId");
      print("PDF File selected: ${_pdfFile?.path}");

      // Upload cover image if selected
      if (_coverImage != null) {
        // Delete old cover if exists
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

      // Upload PDF file if selected
      if (_pdfFile != null) {
        try {
          print("PDF file exists check passed");
          if (pdfFileId.isNotEmpty) {
            print("Attempting to delete old PDF: $pdfFileId");
            await AppwriteService.deleteFile(
              bucketId: '67718396003a69711df7',
              fileId: pdfFileId,
            );
            print("Old PDF deleted successfully");
          }

          print("Starting PDF upload...");
          print("PDF file size: ${await _pdfFile!.length()} bytes");
          pdfFileId = await AppwriteService.uploadFile(
            bucketId: '67718396003a69711df7',
            file: _pdfFile!,
            fileName: '${_titleController.text}.pdf',
          );
          print("PDF uploaded successfully with ID: $pdfFileId");
        } catch (e, stackTrace) {
          print("Error during PDF handling: $e");
          print("Stack trace: $stackTrace");
          rethrow;
        }
      }

      // Create magazine data
      final magazineData = Magazine(
        id: widget.magazine?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        coverUrl: coverFileId,
        pdfFileId: pdfFileId,
        price: double.parse(_priceController.text),
        frequency: _frequency,
        publishDate: _publishDate,
        issueNumber: int.parse(_issueNumberController.text),
        category: _category,
      );

      print("Magazine data created, about to save to Firebase");
      print("PDF ID being saved: ${magazineData.pdfFileId}");

      await FirebaseDatabase.instance
          .ref()
          .child('magazines')
          .child(magazineData.id)
          .set(magazineData.toJson());

      print("Save completed successfully");

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      print("Error in _saveMagazine: $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving magazine: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
              TextFormField(
                controller: _issueNumberController,
                decoration: const InputDecoration(labelText: 'Issue Number'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter an issue number'
                    : null,
              ),
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: ['weekly', 'monthly', 'quarterly', 'yearly']
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
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _pickPDFFile,
                child: Text(
                    _pdfFile == null ? 'Select PDF File' : 'Change PDF File'),
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
}
