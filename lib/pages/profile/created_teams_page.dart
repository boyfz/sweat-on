import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreatedTeamsPage extends StatelessWidget {
  const CreatedTeamsPage({super.key});

  final Color primaryColor = const Color(0xFF4B39EF);

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("User not logged in.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Created Teams'),
        backgroundColor: Colors.white, // Make AppBar blend in
        foregroundColor: Colors.black87,
        elevation: 0, // Flat look
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('teams')
                .where('createdBy', isEqualTo: userId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No teams created yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final List<dynamic> joinedPlayersList =
                  data['joinedPlayers'] ?? [];
              final date = (data['date'] as Timestamp?)?.toDate();
              final formattedDate =
                  date != null
                      ? DateFormat('dd MMM yyyy, EEEE').format(date)
                      : 'Unknown Date';

              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['venueName'] ?? 'Unnamed Venue',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data['sport'] ?? ''} • ${data['venueAddress'] ?? ''}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$formattedDate • ${data['startTime'] ?? ''} • ${data['duration'] ?? ''}h',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Joined Players:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (joinedPlayersList.isEmpty)
                        const Text(
                          'No players joined yet.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Column(
                          children:
                              joinedPlayersList.map<Widget>((player) {
                                final playerMap =
                                    player as Map<String, dynamic>;
                                final playerName =
                                    playerMap['displayName'] ??
                                    'Unknown Player';
                                final playerPosition =
                                    playerMap['position'] ?? 'Unknown Position';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(playerName),
                                      Text(playerPosition),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
