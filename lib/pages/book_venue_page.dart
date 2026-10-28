import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'booking_flow/booking_details_page.dart';

class BookVenuePage extends StatefulWidget {
  const BookVenuePage({super.key});

  @override
  State<BookVenuePage> createState() => _BookVenuePageState();
}

class _BookVenuePageState extends State<BookVenuePage> {
  final Color primaryColor = const Color(0xFF4B39EF);
  String _searchQuery = '';
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return; // <-- IMPORTANT: prevent setState after dispose

    setState(() {
      _userPosition = position;
    });
  }

  double _calculateDistance(GeoPoint venueLoc) {
    if (_userPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          venueLoc.latitude,
          venueLoc.longitude,
        ) /
        1000; // meters to km
  }

  void _openMap(double lat, double lng) async {
    final url = Uri.encodeFull(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (!mounted) return; // also check before using context here
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the map.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Venue'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged:
                  (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search name, address or type...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Venue List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('venues')
                      .where('isVisible', isEqualTo: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final venues =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final combined =
                          '${data['name'] ?? ''} ${data['address'] ?? ''} ${data['type'] ?? ''}'
                              .toLowerCase();
                      return combined.contains(_searchQuery);
                    }).toList();

                if (venues.isEmpty) {
                  return const Center(child: Text('No venues found.'));
                }

                // Sort by distance if user location available
                venues.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aLoc = aData['location'] as GeoPoint?;
                  final bLoc = bData['location'] as GeoPoint?;

                  if (_userPosition == null || aLoc == null || bLoc == null) {
                    return 0;
                  }

                  final distA = _calculateDistance(aLoc);
                  final distB = _calculateDistance(bLoc);

                  return distA.compareTo(distB);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: venues.length,
                  itemBuilder: (context, index) {
                    final doc = venues[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? 'Unnamed Venue';
                    final type = data['type'] ?? 'Unknown';
                    final address = data['address'] ?? 'No Address';
                    final imageUrl = data['imageUrl'] ?? '';
                    final price =
                        (data['pricePerHour'] as num?)?.toDouble() ?? 0.0;
                    final location = data['location'] as GeoPoint?;
                    final facilities = List<String>.from(
                      data['facilities'] ?? [],
                    );

                    String distanceText = '';
                    if (location != null && _userPosition != null) {
                      final distanceKm = _calculateDistance(location);
                      distanceText = '${distanceKm.toStringAsFixed(2)} km away';
                    }

                    return Card(
                      color: Colors.white,
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                            child:
                                imageUrl.isNotEmpty
                                    ? AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          progress,
                                        ) {
                                          if (progress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                      ),
                                    )
                                    : Container(
                                      height: 160,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 60,
                                        ),
                                      ),
                                    ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    if (distanceText.isNotEmpty)
                                      Text(
                                        distanceText,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  type,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Price per hour: RM ${price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (facilities.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children:
                                        facilities.map((facility) {
                                          IconData icon;
                                          switch (facility) {
                                            case 'Parking':
                                              icon = Icons.local_parking;
                                              break;
                                            case 'Toilet':
                                              icon = Icons.wc;
                                              break;
                                            case 'Changing Room':
                                              icon = Icons.door_front_door;
                                              break;
                                            default:
                                              icon = Icons.check;
                                          }
                                          return Chip(
                                            avatar: Icon(icon, size: 18),
                                            label: Text(facility),
                                            backgroundColor: Colors.grey[100],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (location != null)
                                      TextButton.icon(
                                        onPressed:
                                            () => _openMap(
                                              location.latitude,
                                              location.longitude,
                                            ),
                                        icon: const Icon(Icons.map_outlined),
                                        label: const Text('View Map'),
                                      ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => BookingDetailsPage(
                                                  venueName: name,
                                                  venueType: type,
                                                  venueAddress: address,
                                                  pricePerHour: price,
                                                ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Book'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
