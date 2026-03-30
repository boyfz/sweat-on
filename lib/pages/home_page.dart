import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'book_venue_page.dart';
import 'join_flow/join_game_page.dart';
import 'profile/booking_history_page.dart';
import 'profile/profile_page.dart';

class HomePage extends StatefulWidget {
  final String userEmail;
  const HomePage({super.key, required this.userEmail});

  static const Color primaryColor = Color(0xFF4B39EF);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? fullName;

  @override
  void initState() {
    super.initState();
    _loadUserFullName();
  }

  Future<void> _loadUserFullName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        fullName = doc.data()?['fullName'] ?? widget.userEmail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset('assets/images/sweaton_logo.png', height: 36),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Let’s Get Moving!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Welcome, ${fullName ?? '...'}',
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            _buildFeatureCard(
              context,
              icon: Icons.sports_soccer,
              title: 'Book a Venue',
              subtitle: 'Find and reserve the perfect spot for your match.',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BookVenuePage()),
                  ),
            ),
            const SizedBox(height: 16),

            _buildFeatureCard(
              context,
              icon: Icons.group,
              title: 'Join a Game',
              subtitle: 'Browse and join games near your location.',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => JoinGamePage()),
                  ),
            ),
            const SizedBox(height: 16),

            _buildFeatureCard(
              context,
              icon: Icons.history,
              title: 'My Bookings',
              subtitle: 'Review your previous and upcoming games.',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BookingHistoryPage()),
                  ),
            ),
            const SizedBox(height: 16),

            _buildFeatureCard(
              context,
              icon: Icons.person,
              title: 'Profile',
              subtitle: 'Edit your details, change password and more.',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ProfilePage(
                            userEmail: widget.userEmail,
                            onLogout: () {
                              Navigator.of(
                                context,
                              ).pushNamedAndRemoveUntil('/', (r) => false);
                            },
                          ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              HomePage.primaryColor.withOpacity(0.25),
              HomePage.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: HomePage.primaryColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: HomePage.primaryColor, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.black38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
