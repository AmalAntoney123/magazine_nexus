import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/appwrite_service.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  // Add a key to force refresh the avatar
  final Key _avatarKey = UniqueKey();

  Future<void> _uploadImage(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final File imageFile = File(image.path);
      final user = _authService.getCurrentUser();

      if (user != null) {
        // Upload to Appwrite Storage
        final fileId = await AppwriteService.uploadFile(
          bucketId: '6772a79b000f5848edc4',
          file: imageFile,
          fileName: '${user.uid}_profile.jpg',
        );

        // Get the file URL
        final downloadUrl = AppwriteService.getFilePreviewUrl(
          bucketId: '6772a79b000f5848edc4',
          fileId: fileId,
        ).toString();

        // Update user profile
        await user.updatePhotoURL(downloadUrl);

        // Refresh the UI
        setState(() {});

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    String? passwordError;
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: !showCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(
                          () => showCurrentPassword = !showCurrentPassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: !showNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  helperText: 'At least 6 characters',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showNewPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => showNewPassword = !showNewPassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  errorText: passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(
                          () => showConfirmPassword = !showConfirmPassword);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Reset error message
                setState(() => passwordError = null);

                // Validate password length
                if (newPasswordController.text.length < 6) {
                  setState(() =>
                      passwordError = 'Password must be at least 6 characters');
                  return;
                }

                // Validate password match
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  setState(() => passwordError = 'Passwords do not match');
                  return;
                }

                try {
                  await _authService.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );

                  if (context.mounted) {
                    Navigator.pop(context); // Close the dialog

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  String errorMessage = 'Failed to change password';

                  // Convert Firebase errors to user-friendly messages
                  if (e.toString().contains('wrong-password')) {
                    errorMessage = 'Current password is incorrect';
                  } else if (e.toString().contains('requires-recent-login')) {
                    errorMessage =
                        'Please log out and log in again before changing your password';
                  } else if (e.toString().contains('weak-password')) {
                    errorMessage =
                        'Password is too weak. Please choose a stronger password';
                  }

                  setState(() => passwordError = errorMessage);
                }
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final user = _authService.getCurrentUser();

    // Pre-fill with current name
    nameController.text = user?.displayName ?? '';
    String? nameError;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              border: const OutlineInputBorder(),
              errorText: nameError,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Reset error
                setState(() => nameError = null);

                // Validate name
                if (nameController.text.trim().isEmpty) {
                  setState(() => nameError = 'Name cannot be empty');
                  return;
                }

                try {
                  await user?.updateDisplayName(nameController.text.trim());

                  if (context.mounted) {
                    // Refresh the UI
                    this.setState(() {});

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => nameError = 'Failed to update name');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  key: _avatarKey, // Add key to force refresh
                  radius: 60,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 20),
                    onPressed: () => _uploadImage(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Name'),
              subtitle: Text(user?.displayName ?? 'Not set'),
              trailing: const Icon(Icons.edit),
              onTap: () => _editName(context),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(user?.email ?? 'Not set'),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _changePassword(context),
            ),
          ],
        ),
      ),
    );
  }
}
