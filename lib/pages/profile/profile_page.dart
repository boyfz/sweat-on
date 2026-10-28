import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'created_teams_page.dart';
import 'booking_history_page.dart';
import 'account_details_page.dart';
import 'joined_games_page.dart'; // <-- new import

class ProfilePage extends StatefulWidget {
  final String userEmail;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.userEmail,
    required this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? displayName;
  String? photoURL;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      displayName = user?.displayName ?? 'SweatOn User';
      photoURL = user?.photoURL;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4B39EF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 👤 Profile header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor.withValues(alpha: 0.2),
                    backgroundImage:
                        photoURL != null ? NetworkImage(photoURL!) : null,
                    child:
                        photoURL == null
                            ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName ?? 'SweatOn User',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.userEmail,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: Colors.grey.shade300, height: 1),

            // 📋 Menu list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildMenuItem(
                    context,
                    Icons.person_outline,
                    'Account Details',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountDetailsPage(),
                        ),
                      );
                      await _loadUserProfile();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.edit,
                    'Edit Profile',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                      await _loadUserProfile();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.lock,
                    'Change Password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.group,
                    'My Created Teams',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreatedTeamsPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.calendar_today,
                    'My Bookings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BookingHistoryPage()),
                      );
                    },
                  ),
                  // NEW menu item for Joined Games
                  _buildMenuItem(
                    context,
                    Icons.sports_soccer,
                    'My Joined Games',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const JoinedGamesPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: widget.onLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(160, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: const Text('Log Out'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey.shade400,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
