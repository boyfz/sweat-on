import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'join_game_details_page.dart';

class JoinGamePage extends StatefulWidget {
  const JoinGamePage({super.key});

  @override
  State<JoinGamePage> createState() => _JoinGamePageState();
}

class _JoinGamePageState extends State<JoinGamePage> {
  final Color primaryColor = const Color(0xFF4B39EF);
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  LocationData? _currentLocation;
  bool _locationEnabled = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final loc = Location();
      final hasPerm =
          await loc.hasPermission() == PermissionStatus.granted ||
          (await loc.requestPermission() == PermissionStatus.granted);
      if (!hasPerm) {
        if (!mounted) return;
        setState(() {
          _locationError = 'Location permission denied';
        });
        return;
      }

      final enabled = await loc.serviceEnabled() || await loc.requestService();
      if (!enabled) {
        if (!mounted) return;
        setState(() {
          _locationError = 'Location service disabled';
        });
        return;
      }

      final data = await loc.getLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = data;
        _locationEnabled = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Unable to get location';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Join a Game'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 12),
            if (_locationError != null)
              Text(_locationError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Expanded(child: _buildGameList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search by venue, sport…',
          icon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
        ),
        onChanged: (v) {
          setState(() {
            searchQuery = v;
          });
        },
      ),
    );
  }

  Widget _buildGameList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('teams')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (c, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('No games found.'));
        }

        final now = DateTime.now();

        final docs =
            snap.data!.docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  double? distanceKm;

                  if (_locationEnabled &&
                      data['latitude'] != null &&
                      data['longitude'] != null &&
                      _currentLocation?.latitude != null &&
                      _currentLocation?.longitude != null) {
                    final dx =
                        (data['latitude'] - _currentLocation!.latitude!).abs();
                    final dy =
                        (data['longitude'] - _currentLocation!.longitude!)
                            .abs();
                    distanceKm = sqrt(dx * dx + dy * dy) * 111;
                  }

                  return {
                    'data': {...data, 'distance': distanceKm},
                    'id': doc.id,
                    'distance': distanceKm,
                  };
                })
                .where((item) {
                  final d = item['data'] as Map<String, dynamic>;

                  // Exclude games with date in the past
                  final Timestamp? ts = d['date'] as Timestamp?;
                  if (ts != null) {
                    final gameDate = ts.toDate();
                    if (gameDate.isBefore(
                      DateTime(now.year, now.month, now.day),
                    )) {
                      return false;
                    }
                  }

                  final v = (d['venueName'] as String).toLowerCase();
                  final s = (d['sport'] as String).toLowerCase();
                  return v.contains(searchQuery.toLowerCase()) ||
                      s.contains(searchQuery.toLowerCase());
                })
                .toList();

        docs.sort((a, b) {
          final dataA = a['data'] as Map<String, dynamic>;
          final dataB = b['data'] as Map<String, dynamic>;

          final joinedA = (dataA['joined'] ?? 0) as int;
          final neededA = (dataA['playersNeeded'] ?? 1) as int;
          final isFullA = joinedA >= neededA;

          final joinedB = (dataB['joined'] ?? 0) as int;
          final neededB = (dataB['playersNeeded'] ?? 1) as int;
          final isFullB = joinedB >= neededB;

          if (isFullA != isFullB) {
            return isFullA ? 1 : -1;
          }

          final da = a['distance'] as double?;
          final db = b['distance'] as double?;
          if (da != null && db != null) return da.compareTo(db);
          if (da != null) return -1;
          if (db != null) return 1;
          return 0;
        });

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (cxt, idx) {
            return _buildGameCard(
              cxt,
              docs[idx]['data'] as Map<String, dynamic>,
              docs[idx]['id'] as String,
            );
          },
        );
      },
    );
  }

  Widget _buildGameCard(
    BuildContext ctx,
    Map<String, dynamic> data,
    String id,
  ) {
    final double? dist = _locationEnabled ? data['distance'] : null;
    final String type = (data['sport'] ?? 'Game').toString();
    final String venue = data['venueName'] ?? 'Unknown Venue';
    final String createdBy =
        data['createdByName'] ?? data['email'] ?? 'Unknown';
    final String address = data['venueAddress'] ?? 'No address';
    final String startTime = data['startTime'] ?? '-';
    final int duration = data['duration'] ?? 1;
    final int joined = data['joined'] ?? 0;
    final int needed = data['playersNeeded'] ?? 1;
    final DateTime? date = (data['date'] as Timestamp?)?.toDate();
    final bool isFull = joined >= needed;
    final dateFormatted =
        date != null ? DateFormat('dd MMM yyyy, EEEE').format(date) : 'No date';

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B39EF),
                    ),
                  ),
                ),
                const Spacer(),
                if (dist != null)
                  Text(
                    '${dist.toStringAsFixed(1)} km away',
                    style: const TextStyle(color: Colors.black54),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              venue,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Hosted by $createdBy',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(address, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$dateFormatted\n$startTime • $duration h',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.group_outlined, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  isFull
                      ? 'Game is full!'
                      : 'Looking for ${needed - joined} more player(s)',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder:
                          (_) => JoinGameDetailsPage(team: data, teamId: id),
                    ),
                  );
                },
                icon: const SizedBox(),
                label: Row(
                  children: const [
                    Text(
                      'View more',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
                style: TextButton.styleFrom(foregroundColor: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
