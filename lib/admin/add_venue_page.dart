import 'package:flutter/material.dart';
import 'add_venue_form_page.dart';
import 'dart:ui'; // for blur effect

class AddVenuePage extends StatelessWidget {
  const AddVenuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4B39EF);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/addvenuebg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 🔲 Optional blur overlay (if image is too strong)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.black.withValues(
                  alpha: 0.1,
                ), // optional dim layer
              ),
            ),
          ),

          // 🌟 Foreground content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Manage Your Venues",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: Offset(1, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Add new venues with ease and keep everything organized smoothly.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 30),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          'Add New Venue',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 14,
                        shadowColor: primaryColor.withValues(alpha: 0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddVenueFormPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 80),
                  Text(
                    "SweatOn",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
