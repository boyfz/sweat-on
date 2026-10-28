import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_venue_page.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminVenueListPage extends StatefulWidget {
  const AdminVenueListPage({super.key});

  @override
  State<AdminVenueListPage> createState() => _AdminVenueListPageState();
}

class _AdminVenueListPageState extends State<AdminVenueListPage> {
  String _searchText = '';

  void _deleteVenue(BuildContext context, DocumentReference docRef) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Venue'),
            content: const Text('Are you sure you want to delete this venue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await docRef.delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Venue deleted')));
    }
  }

  void _editVenue(BuildContext context, DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditVenuePage(venueDoc: doc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF4B39EF);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venue List'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search name, address or type...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged:
                  (value) => setState(() => _searchText = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('venues')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No venues available.'));
                }

                final venues =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final combinedText =
                          '${data['name'] ?? ''} ${data['address'] ?? ''} ${data['type'] ?? ''}'
                              .toLowerCase();
                      return combinedText.contains(_searchText);
                    }).toList();

                if (venues.isEmpty) {
                  return const Center(child: Text('No results found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: venues.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = venues[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? 'Unnamed';
                    final type = data['type'] ?? 'Unknown';
                    final address = data['address'] ?? 'No address';
                    final imageUrl = data['imageUrl'] ?? '';
                    final isVisible = data['isVisible'] as bool? ?? true;
                    final price = data['pricePerHour']?.toString() ?? 'N/A';
                    final facilities = List<String>.from(
                      data['facilities'] ?? [],
                    );
                    final location = data['location'] as GeoPoint?;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
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
                                      height: 180,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 60,
                                      ),
                                    ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Type: $type',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Price per hour: RM $price',
                                  style: const TextStyle(color: Colors.black54),
                                ),

                                if (facilities.isNotEmpty) ...[
                                  const SizedBox(height: 6),
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

                                if (location != null) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      final url =
                                          'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url));
                                      }
                                    },
                                    child: Text(
                                      'View on Map: (${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isVisible
                                                ? Colors.green[100]
                                                : Colors.red[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isVisible ? 'Shown' : 'Hidden',
                                        style: TextStyle(
                                          color:
                                              isVisible
                                                  ? Colors.green
                                                  : Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Switch(
                                      value: isVisible,
                                      activeColor: primaryColor,
                                      onChanged: (val) {
                                        doc.reference.update({
                                          'isVisible': val,
                                        });
                                      },
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      color: Colors.black54,
                                      onPressed: () => _editVenue(context, doc),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.black54,
                                      onPressed:
                                          () => _deleteVenue(
                                            context,
                                            doc.reference,
                                          ),
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
