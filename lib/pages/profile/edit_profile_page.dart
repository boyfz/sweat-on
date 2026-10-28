import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final Color primaryColor = const Color(0xFF4B39EF);
  File? _selectedImage;
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _photoURL = user.photoURL;
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('${user!.uid}.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingAnimationWidget.bouncingBall(
                    color: primaryColor,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  const Text("Saving..."),
                ],
              ),
            ),
          ),
    );

    try {
      // Upload new photo if selected
      if (_selectedImage != null) {
        final newPhotoURL = await _uploadImage(_selectedImage!);
        await user.updatePhotoURL(newPhotoURL);
      }

      await user.updateDisplayName(name);

      // Email only changes after the user clicks the link sent to the new
      // address (updateEmail is deprecated and blocked on newer projects).
      final emailChanged = user.email != email;
      if (emailChanged) {
        await user.verifyBeforeUpdateEmail(email);
      }

      await user.reload();
      if (!mounted) return;

      Navigator.of(context).pop(); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailChanged
                ? 'Profile updated. Check $email to confirm your new email.'
                : 'Profile updated successfully.',
          ),
        ),
      );
      Navigator.pop(context); // Go back to ProfilePage
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      String message;
      switch (e.code) {
        case 'requires-recent-login':
          message = 'Please log in again to update your email.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'email-already-in-use':
          message = 'This email is already in use.';
          break;
        default:
          message = 'Error: ${e.message}';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider =
        _selectedImage != null
            ? FileImage(_selectedImage!)
            : (_photoURL != null ? NetworkImage(_photoURL!) : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: primaryColor.withValues(alpha: 0.2),
                backgroundImage: imageProvider as ImageProvider?,
                child:
                    imageProvider == null
                        ? Icon(Icons.camera_alt, color: primaryColor)
                        : null,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _pickImage,
              child: const Text("Change Profile Picture"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: const TextStyle(color: Colors.black54),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.black54),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
