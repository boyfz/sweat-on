import 'package:flutter/material.dart';
import 'home_page.dart';
import 'book_venue_page.dart';
import 'join_flow/join_game_page.dart';
import 'create_team_page.dart';
import 'profile/profile_page.dart';
import 'login_page.dart';

class MainNavigation extends StatefulWidget {
  final String userEmail;
  const MainNavigation({super.key, required this.userEmail});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  final Color primaryColor = const Color(0xFF4B39EF);
  final Color unselectedColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(userEmail: widget.userEmail),
      BookVenuePage(),
      JoinGamePage(),
      CreateTeamPage(),
      ProfilePage(
        userEmail: widget.userEmail,
        onLogout: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        color: Colors.white,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
              states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                );
              }
              return TextStyle(
                color: unselectedColor,
                fontWeight: FontWeight.normal,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(color: primaryColor);
              }
              return IconThemeData(color: unselectedColor);
            }),
          ),
          child: NavigationBar(
            backgroundColor: Colors.white,
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(
                icon: Icon(Icons.location_on),
                label: 'Book',
              ),
              NavigationDestination(
                icon: Icon(Icons.sports_soccer),
                label: 'Join',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_add),
                label: 'Create',
              ),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
