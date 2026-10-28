import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('[WARNING] Firebase already initialized: $e');
  }

  runApp(const SweatOnApp());
}

class SweatOnApp extends StatelessWidget {
  const SweatOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SweatOn',
      theme: ThemeData(
        fontFamily: 'Urbanist',
        textTheme: ThemeData.light().textTheme
            .apply(
              fontFamily: 'Urbanist',
              bodyColor: Colors.black,
              displayColor: Colors.black,
            )
            .copyWith(
              bodyLarge: const TextStyle(fontWeight: FontWeight.w700),
              bodyMedium: const TextStyle(fontWeight: FontWeight.w700),
              bodySmall: const TextStyle(fontWeight: FontWeight.w700),
              titleLarge: const TextStyle(fontWeight: FontWeight.w700),
              titleMedium: const TextStyle(fontWeight: FontWeight.w700),
              titleSmall: const TextStyle(fontWeight: FontWeight.w700),
            ),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4B39EF)),
        useMaterial3: true,
        primaryColor: const Color(0xFF4B39EF),
      ),
      home: const LoginPage(),
    );
  }
}
