import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_scaffold.dart'; // NEW IMPORT

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const LifeGuiApp());
}

class LifeGuiApp extends StatelessWidget {
  const LifeGuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life GUI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F14),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const MainScaffold(), // FIX: Boot into the Navigation Hub!
    );
  }
}
