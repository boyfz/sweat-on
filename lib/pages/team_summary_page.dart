import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_navigation.dart'; // Ensure this path is correct

class TeamSummaryPage extends StatelessWidget {
  final String sport;
  final DateTime date;
  final TimeOfDay time;
  final Map<String, int> positions;

  const TeamSummaryPage({
    super.key,
    required this.sport,
    required this.date,
    required this.time,
    required this.positions,
  });

  final Color primaryColor = const Color(0xFF4B39EF);

  String get formattedDate => '${date.day}/${date.month}/${date.year}';

  String get formattedTime {
    final hour = time.hourOfPeriod.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Team Created'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/fireball.gif',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              const Text(
                'Team Successfully Created!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Get ready to play and make new friends!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildInfoRow('Sport', sport),
              _buildInfoRow('Date', formattedDate),
              _buildInfoRow('Time', formattedTime),
              const SizedBox(height: 24),
              const Text(
                'Positions Needed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...positions.entries
                  .where((entry) => entry.value > 0)
                  .map((entry) => _buildRoleRow(entry.key, entry.value)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MainNavigation(userEmail: userEmail),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Return to Home',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleRow(String role, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.black87, size: 20),
          const SizedBox(width: 8),
          Text(
            '$role: ',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text('$count', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
