import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final Color primaryColor = const Color(0xFF4B39EF);

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    if (newPassword.length < 6) {
      _showError('Password must be at least 6 characters long.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showError('New password and confirmation do not match.');
      return;
    }

    if (newPassword == currentPassword) {
      _showError('New password cannot be the same as current password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );

      // Re-authenticate and update password
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      setState(() => _isLoading = false);

      // Show success and navigate back
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Your password has been updated.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back to Profile page
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      if (e.code == 'wrong-password') {
        _showError('Current password is incorrect.');
      } else {
        _showError('Failed to change password. Please try again later.');
      }
    }
  }

  InputDecoration _inputDecoration(
    String label, {
    bool showToggle = false,
    VoidCallback? onToggle,
    bool isVisible = false,
  }) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      suffixIcon:
          showToggle
              ? IconButton(
                icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: onToggle,
              )
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: _currentPasswordController,
                  obscureText: !_showCurrentPassword,
                  decoration: _inputDecoration(
                    'Current Password',
                    showToggle: true,
                    onToggle:
                        () => setState(
                          () => _showCurrentPassword = !_showCurrentPassword,
                        ),
                    isVisible: _showCurrentPassword,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  obscureText: !_showNewPassword,
                  decoration: _inputDecoration(
                    'New Password',
                    showToggle: true,
                    onToggle:
                        () => setState(
                          () => _showNewPassword = !_showNewPassword,
                        ),
                    isVisible: _showNewPassword,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password must be at least 6 characters.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  decoration: _inputDecoration(
                    'Confirm New Password',
                    showToggle: true,
                    onToggle:
                        () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        ),
                    isVisible: _showConfirmPassword,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Update Password',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
