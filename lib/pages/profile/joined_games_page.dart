import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sweaton/pages/join_flow/join_game_details_page.dart';

class JoinedGamesPage extends StatefulWidget {
  const JoinedGamesPage({super.key});

  @override
  State<JoinedGamesPage> createState() => _JoinedGamesPageState();
}

class _JoinedGamesPageState extends State<JoinedGamesPage> {
  final user = FirebaseAuth.instance.currentUser;
  String searchQuery = '';
  String filter = 'All'; // All, Upcoming, Past
  final Color primaryColor = const Color(0xFF4B39EF);

  bool _matchesFilterAndSearch(Map<String, dynamic> teamData) {
    final venue = (teamData['venueName'] ?? '').toString().toLowerCase();
    final sport = (teamData['sport'] ?? '').toString().toLowerCase();
    final query = searchQuery.toLowerCase();

    final matchesQuery = venue.contains(query) || sport.contains(query);

    final Timestamp? timestamp = teamData['date'];
    if (timestamp == null) return false;
    final gameDate = timestamp.toDate();
    final now = DateTime.now();

    if (filter == 'Upcoming' && gameDate.isBefore(now)) return false;
    if (filter == 'Past' && gameDate.isAfter(now)) return false;

    return matchesQuery;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Joined Games'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: const Center(
          child: Text('Please login to view your joined games.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Joined Games'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search venue or sport...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children:
                    ['All', 'Upcoming', 'Past'].map((option) {
                      final isSelected = filter == option;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => filter = option),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? primaryColor
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                option,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('bookings')
                      .orderBy('joinedAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('You have not joined any games.'),
                  );
                }

                final filteredDocs =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final teamData =
                          data['teamData'] as Map<String, dynamic>?;
                      return teamData != null &&
                          _matchesFilterAndSearch(teamData);
                    }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No games match your search or filter.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final bookingData =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    final teamData =
                        bookingData['teamData'] as Map<String, dynamic>;
                    final teamId =
                        bookingData['teamId'] ?? filteredDocs[index].id;
                    final position =
                        bookingData['position'] ?? 'Unknown Position';

                    final gameDate = (teamData['date'] as Timestamp?)?.toDate();
                    final isPast =
                        gameDate != null && gameDate.isBefore(DateTime.now());

                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                teamData['venueName'] ?? 'Unknown Venue',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isPast ? Colors.red : Colors.green,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPast ? 'Expired' : 'Upcoming',
                                style: TextStyle(
                                  color: isPast ? Colors.red : Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${teamData['sport'] ?? 'Game'}\nJoined as: $position',
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => JoinGameDetailsPage(
                                    team: teamData,
                                    teamId: teamId,
                                    alreadyJoined: true,
                                    joinedPosition: position,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
