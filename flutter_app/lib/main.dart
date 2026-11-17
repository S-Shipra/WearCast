import 'package:material_ui/material_ui.dart';

import 'screens/auth_screen.dart'; // Import the Auth Screen

void main() {
  runApp(const WearcastApp());
}

class WearcastApp extends StatelessWidget {
  const WearcastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wearcast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9F8F6), // Soft off-white
        fontFamily: 'Roboto', // Clean font
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5A6B50), // Olive Green
          primary: const Color(0xFF5A6B50),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}
