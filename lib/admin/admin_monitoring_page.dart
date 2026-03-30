import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/login_page.dart';

class AdminMonitoringPage extends StatefulWidget {
  const AdminMonitoringPage({super.key});

  @override
  State<AdminMonitoringPage> createState() => _AdminMonitoringPageState();
}

class _AdminMonitoringPageState extends State<AdminMonitoringPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Color primaryColor = const Color(0xFF4B39EF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Log Out'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Log Out'),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Admin Monitoring'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: primaryColor),
            tooltip: 'Log Out',
            onPressed: () => _logout(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged:
                      (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.black54,
                indicatorColor: primaryColor,
                tabs: const [
                  Tab(text: 'Bookings'),
                  Tab(text: 'Teams'),
                  Tab(text: 'Users'),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: TabBarView(
        controller: _tabController,
        children: [_buildBookingsTab(), _buildTeamsTab(), _buildUsersTab()],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('bookings')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading bookings'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data?.docs ?? [];

        final filtered =
            bookings.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final venue = data['venue']?.toString().toLowerCase() ?? '';
              final date = data['date']?.toString().toLowerCase() ?? '';
              final email = data['email']?.toString().toLowerCase() ?? '';
              final startTime =
                  data['startTime']?.toString().toLowerCase() ?? '';
              return venue.contains(_searchQuery) ||
                  date.contains(_searchQuery) ||
                  startTime.contains(_searchQuery) ||
                  email.contains(_searchQuery);
            }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No bookings found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final data = filtered[index].data() as Map<String, dynamic>;

            final venue = data['venue'] ?? 'Unknown Venue';
            final dateRaw = data['date']?.toString();
            final startTime = data['startTime'] ?? '-';
            final duration = data['durationHours']?.toString() ?? '-';
            final email = data['email'] ?? '-';
            final totalPrice = data['totalPrice']?.toStringAsFixed(2) ?? '-';

            String formattedDate = '-';
            if (dateRaw != null) {
              try {
                final parsedDate = DateTime.parse(dateRaw);
                formattedDate =
                    '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
              } catch (_) {}
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    color: Color(0xFF4B39EF),
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: $formattedDate  |  $startTime',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Duration: $duration hour(s)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Email: $email',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Total Paid: RM $totalPrice',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
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
    );
  }

  Widget _buildTeamsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('teams')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading teams'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final teams = snapshot.data?.docs ?? [];

        final filtered =
            teams.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final sport = data['sport']?.toString().toLowerCase() ?? '';
              final venueName =
                  data['venueName']?.toString().toLowerCase() ?? '';
              final createdByName =
                  data['createdByName']?.toString().toLowerCase() ?? '';
              return sport.contains(_searchQuery) ||
                  venueName.contains(_searchQuery) ||
                  createdByName.contains(_searchQuery);
            }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No teams found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final data = filtered[index].data() as Map<String, dynamic>;

            final sport = data['sport'] ?? '-';
            final venueName = data['venueName'] ?? '-';
            final createdByName = data['createdByName'] ?? '-';
            final dateTimestamp = data['date'] as Timestamp?;
            String formattedDate = '-';
            if (dateTimestamp != null) {
              final dt = dateTimestamp.toDate();
              formattedDate = '${dt.day}/${dt.month}/${dt.year}';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.groups, color: Color(0xFF4B39EF), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$sport Team',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Venue: $venueName',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Date: $formattedDate',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Created by: $createdByName',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
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
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .orderBy('fullName')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading users'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        final filtered =
            users.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['fullName']?.toString().toLowerCase() ?? '';
              final email = data['email']?.toString().toLowerCase() ?? '';
              final phone = data['phone']?.toString().toLowerCase() ?? '';
              return name.contains(_searchQuery) ||
                  email.contains(_searchQuery) ||
                  phone.contains(_searchQuery);
            }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data() as Map<String, dynamic>;

            final fullName = data['fullName'] ?? '-';
            final email = data['email'] ?? '-';
            final phone = data['phone'] ?? '-';
            final isDisabled = data['isDisabled'] == true;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF4B39EF), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Email: $email',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Phone: $phone',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          isDisabled ? 'Status: Disabled' : 'Status: Active',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDisabled ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'disable') {
                        await doc.reference.update({'isDisabled': true});
                      } else if (value == 'enable') {
                        await doc.reference.update({'isDisabled': false});
                      }
                    },
                    itemBuilder:
                        (context) => [
                          if (!isDisabled)
                            const PopupMenuItem(
                              value: 'disable',
                              child: Text('Disable User'),
                            )
                          else
                            const PopupMenuItem(
                              value: 'enable',
                              child: Text('Enable User'),
                            ),
                        ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
