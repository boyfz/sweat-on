import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class JoinGameDetailsPage extends StatefulWidget {
  final Map<String, dynamic> team;
  final String teamId;
  final bool alreadyJoined;
  final String? joinedPosition;

  const JoinGameDetailsPage({
    super.key,
    required this.team,
    required this.teamId,
    this.alreadyJoined = false,
    this.joinedPosition,
  });

  @override
  State<JoinGameDetailsPage> createState() => _JoinGameDetailsPageState();
}

class _JoinGameDetailsPageState extends State<JoinGameDetailsPage> {
  final Color primaryColor = const Color(0xFF4B39EF);
  String? selectedPosition;
  bool isJoining = false;

  bool _hasJoined(Map<String, dynamic> team, String currentUid) {
    final joinedPlayers = List<Map<String, dynamic>>.from(
      team['joinedPlayers'] ?? [],
    );
    return joinedPlayers.any((player) => player['uid'] == currentUid);
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.team;
    final String sport = team['sport'] ?? 'Game';
    final String venue = team['venueName'] ?? 'Unknown Venue';
    final String address = team['venueAddress'] ?? 'No address provided';
    final double? latitude = (team['latitude'] as num?)?.toDouble();
    final double? longitude = (team['longitude'] as num?)?.toDouble();
    final String createdBy = team['createdByName'] ?? 'Unknown';
    final String phone = team['phoneNumber'] ?? '-';
    final String startTime = team['startTime'] ?? '-';
    final int duration = team['duration'] ?? 1;
    final int joined = team['joined'] ?? 0;
    final int needed = team['playersNeeded'] ?? 1;
    final String description = team['description'] ?? '';
    final Timestamp? dateTimestamp = team['date'];
    final String formattedDate =
        dateTimestamp != null
            ? DateFormat('dd MMM yyyy, EEEE').format(dateTimestamp.toDate())
            : 'Unknown';
    final positions = Map<String, dynamic>.from(team['positions'] ?? {});

    final String creatorUid = team['createdBy'] ?? '';
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String currentUid = currentUser?.uid ?? '';
    final bool isCreator = currentUid == creatorUid;
    final bool hasJoined = widget.alreadyJoined || _hasJoined(team, currentUid);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Game Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTag(sport),
            const SizedBox(height: 8),
            Text(
              venue,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Hosted by $createdBy',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              "Host's Contact Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(phone),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(address)),
                OutlinedButton.icon(
                  onPressed: () async {
                    Uri? uri;
                    if (latitude != null && longitude != null) {
                      uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
                      );
                    } else {
                      uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
                      );
                    }
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  icon: Icon(Icons.map_outlined, color: primaryColor),
                  label: Text(
                    'Getting there',
                    style: TextStyle(color: primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              '$formattedDate\n$startTime • $duration hour(s)',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.group_outlined, '$joined / $needed joined'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (needed > 0 ? joined / needed : 0),
              backgroundColor: Colors.grey[300],
              color: primaryColor,
              minHeight: 8,
            ),
            const SizedBox(height: 24),

            // Show position selection only if NOT joined/creator/read-only
            if (positions.isNotEmpty &&
                !isCreator &&
                !hasJoined &&
                !widget.alreadyJoined) ...[
              const Text(
                'Choose Your Position:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...positions.entries.map((entry) {
                final isDisabled = entry.value == 0;
                return RadioListTile<String>(
                  title: Text(
                    '${entry.key} (${entry.value} slots)',
                    style: TextStyle(
                      color: isDisabled ? Colors.grey : Colors.black,
                    ),
                  ),
                  value: entry.key,
                  groupValue: selectedPosition,
                  onChanged:
                      isDisabled
                          ? null
                          : (v) => setState(() => selectedPosition = v),
                );
              }),
              const SizedBox(height: 24),
            ],

            const Text(
              'Game Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(description),
            const SizedBox(height: 32),

            if (isCreator)
              Center(
                child: Text(
                  'You are the host and cannot join this game.',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (hasJoined || widget.alreadyJoined)
              Center(
                child: Text(
                  'You have already joined this game as: ${widget.joinedPosition ?? "Unknown"}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (selectedPosition != null && !isJoining)
                          ? () => _showConfirmationDialog()
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      isJoining
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Join Game'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String sport) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        sport.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4B39EF),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Future<void> _showConfirmationDialog() async {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirm Join'),
            content: Text('Join as $selectedPosition?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              TextButton(onPressed: _handleJoinGame, child: const Text('Yes')),
            ],
          ),
    );
  }

  Future<void> _handleJoinGame() async {
    Navigator.pop(context); // Close dialog
    setState(() => isJoining = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || selectedPosition == null) return;

      final position = selectedPosition!;
      final teamRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId);
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final userDoc = await userRef.get();
      final displayName =
          userDoc.data()?['fullName'] ?? user.email ?? 'Unknown Player';

      // Run the slot check and all writes in one transaction so two players
      // can't both take the last spot, and a failure can't leave counts
      // out of sync with joinedPlayers.
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final teamSnapshot = await tx.get(teamRef);
        final data = teamSnapshot.data();
        if (data == null) {
          throw Exception('This game no longer exists');
        }

        if (_hasJoined(data, user.uid)) {
          throw Exception('You have already joined this game');
        }

        final positions = Map<String, dynamic>.from(data['positions'] ?? {});
        final slotsLeft = positions[position];
        if (slotsLeft is! num || slotsLeft <= 0) {
          throw Exception('Selected position is no longer available');
        }

        positions[position] = slotsLeft - 1;

        tx.update(teamRef, {
          'positions': positions,
          'joined': FieldValue.increment(1),
          'joinedPlayers': FieldValue.arrayUnion([
            {
              'uid': user.uid,
              'displayName': displayName,
              'position': position,
              'joinedAt': Timestamp.now(),
            },
          ]),
        });

        tx.set(userRef.collection('bookings').doc(widget.teamId), {
          'teamId': widget.teamId,
          'position': position,
          'joinedAt': FieldValue.serverTimestamp(),
          'teamData': widget.team,
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You’ve successfully joined the game!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isJoining = false);
    }
  }
}
