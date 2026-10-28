import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/booking_time.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final Color primaryColor = const Color(0xFF4B39EF);
  String searchQuery = '';
  String filter = 'All'; // Options: All, Upcoming, Past

  void _openMap(String venueName) async {
    final encoded = Uri.encodeComponent(venueName);
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$encoded",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Helper function to get booking status: Past, Live, Upcoming
  String getBookingStatus(Map<String, dynamic> data) {
    final dateStr = data['date'] ?? '';
    final startTimeStr = data['startTime'] ?? '00:00';
    final durationHours = data['durationHours'] ?? 1;

    DateTime? bookingDate;
    try {
      bookingDate = DateTime.parse(dateStr);
    } catch (_) {
      bookingDate = null;
    }

    if (bookingDate == null) return 'Unknown';

    try {
      final startTimeParsed = parseStoredTime(startTimeStr);
      if (startTimeParsed == null) throw FormatException(startTimeStr);

      final startDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        startTimeParsed.hour,
        startTimeParsed.minute,
      );

      final endDateTime = startDateTime.add(Duration(hours: durationHours));
      final now = DateTime.now();

      if (now.isBefore(startDateTime)) {
        return 'Upcoming';
      } else if (now.isAfter(endDateTime)) {
        return 'Expired';
      } else {
        return 'Live';
      }
    } catch (_) {
      // If parsing fails, fallback to just comparing dates
      final nowDate = DateTime.now();
      final todayDate = DateTime(nowDate.year, nowDate.month, nowDate.day);
      final bookingDay = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
      );

      if (bookingDay.isBefore(todayDate)) {
        return 'Expired';
      } else if (bookingDay.isAfter(todayDate)) {
        return 'Upcoming';
      } else {
        return 'Live';
      }
    }
  }

  bool _matchesFilterAndSearch(Map<String, dynamic> data) {
    final venue = (data['venue'] ?? '').toString().toLowerCase();
    final address = (data['venueAddress'] ?? '').toString().toLowerCase();
    final query = searchQuery.toLowerCase();

    final matchQuery = venue.contains(query) || address.contains(query);
    if (!matchQuery) return false;

    final status = getBookingStatus(data);

    if (filter == 'All') {
      return true; // show all regardless of status
    } else if (filter == 'Upcoming' && status == 'Upcoming') {
      return true;
    } else if (filter == 'Past' && status == 'Expired') {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: const Center(child: Text('User not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
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
                hintText: 'Search venue or address...',
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
                      .collection('bookings')
                      .where('uid', isEqualTo: uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final bookings =
                    snapshot.data?.docs
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .where(_matchesFilterAndSearch)
                        .toList() ??
                    [];

                if (bookings.isEmpty) {
                  return const Center(
                    child: Text('No bookings match your search or filter.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final data = bookings[index];

                    final venue = data['venue'] ?? 'Unknown Venue';
                    final address =
                        data['venueAddress'] ?? 'No address provided';
                    final startTime = data['startTime'] ?? 'Unknown Time';
                    final duration = data['durationHours']?.toString() ?? '-';

                    // Use totalPrice as price field, else fallback to '-'
                    final price =
                        data['totalPrice'] != null
                            ? (data['totalPrice'] is num
                                ? (data['totalPrice'] as num).toStringAsFixed(2)
                                : data['totalPrice'].toString())
                            : '-';

                    final createdAt = data['createdAt'];
                    final createdDate =
                        createdAt is Timestamp
                            ? DateFormat(
                              'dd MMM yyyy • hh:mm a',
                            ).format(createdAt.toDate())
                            : 'Unknown';

                    final status = getBookingStatus(data);

                    Color statusColor;
                    if (status == 'Expired') {
                      statusColor = Colors.red;
                    } else if (status == 'Live') {
                      statusColor = Colors.orange;
                    } else {
                      statusColor = Colors.green;
                    }

                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        venue,
                                        style: const TextStyle(
                                          fontSize: 18,
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
                                        border: Border.all(color: statusColor),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(address),
                                const SizedBox(height: 8),
                                Text(
                                  'Date: ${data['date'] != null ? DateFormat('dd MMM yyyy, EEEE').format(DateTime.parse(data['date'])) : 'Unknown Date'}',
                                ),
                                Text('Time: $startTime • $duration hour(s)'),
                                Text('Price: RM $price'),
                                const SizedBox(height: 8),
                                Text(
                                  'Booked at: $createdDate',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () => _openMap(venue),
                                  icon: const Icon(Icons.location_on_outlined),
                                  label: const Text('View Map'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
