import 'package:flutter/material.dart';
import 'admin_venue_list_page.dart';
import 'add_venue_page.dart';
import 'admin_monitoring_page.dart';

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({super.key});

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int _currentIndex = 0;
  final Color primaryColor = const Color(0xFF4B39EF);

  final List<Widget> _pages = [
    const AdminVenueListPage(),
    const AddVenuePage(),
    const AdminMonitoringPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 70,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: primaryColor);
            }
            return const IconThemeData(color: Colors.grey);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color:
                  states.contains(WidgetState.selected)
                      ? primaryColor
                      : Colors.grey,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on),
              label: 'Venues',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_business_outlined),
              selectedIcon: Icon(Icons.add_business),
              label: 'Add Venue',
            ),
            NavigationDestination(
              icon: Icon(Icons.monitor_heart_outlined),
              selectedIcon: Icon(Icons.monitor_heart),
              label: 'Monitor',
            ),
          ],
        ),
      ),
    );
  }
}
