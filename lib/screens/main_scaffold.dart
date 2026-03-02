import 'package:flutter/material.dart';
import 'timeline_screen.dart';
import 'category_manager_screen.dart';
import 'analytics_screen.dart'; 
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TimelineScreen(),
    const CategoryManagerScreen(),
    const AnalyticsScreen(), // NEW SCREEN
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF16161E),
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white38,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_rounded),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_rounded),
            label: 'Tags',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded), // NEW ICON
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}