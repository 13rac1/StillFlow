import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  // Ensure Flutter bindings are initialized before audio service
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const StillFlowApp());
}

class StillFlowApp extends StatelessWidget {
  const StillFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Still Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Dark theme only for sleep-friendly interface
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6B9AC4),
          secondary: const Color(0xFF97C4B8),
          surface: const Color(0xFF1A1A2E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFFE0E0E0),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A1A2E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
