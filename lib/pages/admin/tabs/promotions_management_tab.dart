import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:magazine_nexus/services/appwrite_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PromotionsManagementTab extends StatefulWidget {
  const PromotionsManagementTab({super.key});

  @override
  State<PromotionsManagementTab> createState() =>
      _PromotionsManagementTabState();
}

class _PromotionsManagementTabState extends State<PromotionsManagementTab> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  DateTime? _endDate;
  String? _selectedImageId;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final file = await AppwriteService.uploadFile(
          bucketId: '67718720002aaa542f4d',
          file: File(image.path),
          fileName: 'promotion_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        setState(() => _selectedImageId = file);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDateTimePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _createPromotion() async {
    if (!_formKey.currentState!.validate() ||
        _selectedImageId == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ref =
          FirebaseDatabase.instance.ref().child('promotional_banners').push();
      await ref.set({
        'imageUrl': _selectedImageId,
        'description': _descriptionController.text,
        'endDate': _endDate!.toIso8601String(),
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promotion created successfully')),
        );
        _clearForm();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _descriptionController.clear();
    setState(() {
      _endDate = null;
      _selectedImageId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Promotion',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a description'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_endDate == null
                          ? 'Select End Date'
                          : 'Ends on: ${DateFormat('yyyy-MM-dd HH:mm').format(_endDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectEndDate,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          if (_selectedImageId != null)
                            Image.network(
                              AppwriteService.getFilePreviewUrl(
                                bucketId: '67718720002aaa542f4d',
                                fileId: _selectedImageId!,
                              ).toString(),
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _pickImage,
                            icon: const Icon(Icons.image),
                            label: Text(_selectedImageId == null
                                ? 'Select Image'
                                : 'Change Image'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createPromotion,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Create Promotion'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Active Promotions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: FirebaseDatabase.instance
                .ref()
                .child('promotional_banners')
                .orderByChild('isActive')
                .equalTo(true)
                .onValue,
            builder: (context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data?.snapshot?.value == null) {
                return const Center(
                  child: Text('No active promotions'),
                );
              }

              Map<dynamic, dynamic> promotions = snapshot.data!.snapshot!.value;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: promotions.length,
                itemBuilder: (context, index) {
                  final promotion = promotions.entries.elementAt(index);
                  final endDate = DateTime.parse(promotion.value['endDate']);
                  final isExpired = DateTime.now().isAfter(endDate);

                  return Card(
                    child: ListTile(
                      leading: Image.network(
                        AppwriteService.getFilePreviewUrl(
                          bucketId: '67718720002aaa542f4d',
                          fileId: promotion.value['imageUrl'],
                        ).toString(),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                      title: Text(promotion.value['description']),
                      subtitle: Text(
                        'Ends: ${DateFormat('yyyy-MM-dd HH:mm').format(endDate)}',
                        style: TextStyle(
                          color: isExpired ? Colors.red : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await FirebaseDatabase.instance
                              .ref()
                              .child('promotional_banners')
                              .child(promotion.key)
                              .update({'isActive': false});
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}

Future<DateTime?> showDateTimePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final DateTime? date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (date == null) return null;

  final TimeOfDay? time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );
  if (time == null) return null;

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}
