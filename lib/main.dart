import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/calendar_screen.dart'; // Update import

void main() {
  runApp(const ProviderScope(child: LifeLoggerApp()));
}

class LifeLoggerApp extends StatelessWidget {
  const LifeLoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LIFE GUI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        // Apply the sleek 'Inter' font to the whole app
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const CalendarScreen(),
    );
  }
}
