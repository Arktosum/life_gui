import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/time_block.dart';
import '../models/mood_preset.dart';
import '../database/database_helper.dart';
import '../logic/timeline_engine.dart';
import '../widgets/timeline/quick_log_sheet.dart';
import '../widgets/timeline/daily_canvas.dart'; // NEW IMPORT
import 'daily_journal_screen.dart'; // DIARY IMPORT

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<TimelineSegment>> _dailySegments = {};
  
  Map<int, ActivityCategory> _categories = {};
  List<MoodPreset> _moods = []; 
  
  bool _isLoading = true;
  final TimelineEngine _engine = TimelineEngine();
  
  Timer? _tickTimer;
  DateTime _currentTime = DateTime.now();
  
  final int _initialPage = 10000; 
  late PageController _pageController;
  final Map<DateTime, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _startTicker();
    _loadDropdownData();
    _loadDataForDate(_selectedDate);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _pageController.dispose();
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTicker() {
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
          if (DateUtils.isSameDay(_selectedDate, _currentTime)) {
            _loadDataForDate(_selectedDate);
          }
        });
      }
    });
  }

  ScrollController _getScrollController(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    if (!_scrollControllers.containsKey(startOfDay)) {
      _scrollControllers[startOfDay] = ScrollController();
    }
    return _scrollControllers[startOfDay]!;
  }

  DateTime _getDateFromIndex(int index) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: index - _initialPage));
  }

  Future<void> _loadDropdownData() async {
    try {
      final categoriesList = await DatabaseHelper.instance.getActiveCategories();
      final moodMaps = await DatabaseHelper.instance.getAllMoodPresets();
      
      if (mounted) {
        setState(() {
          _categories = {for (var cat in categoriesList) cat.id!: cat};
          _moods = moodMaps.map((m) => MoodPreset.fromMap(m)).toList();
        });
      }
    } catch (e) {
      debugPrint('🔥 SQL ERROR: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDataForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    if (_dailySegments[startOfDay] == null && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final blocks = await DatabaseHelper.instance.getTimeBlocksForDateRange(startOfDay, endOfDay);

      if (mounted) {
        setState(() {
          final isToday = DateUtils.isSameDay(startOfDay, _currentTime);
          _dailySegments[startOfDay] = _engine.generateSegments(
            startOfDay, blocks, playheadTime: isToday ? _currentTime : null,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🔥 SQL ERROR: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _animateToDate(int daysDelta) {
    final targetPage = (_pageController.page?.round() ?? _initialPage) + daysDelta;
    _pageController.animateToPage(targetPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _openSheet(DateTime start, DateTime end, TimeBlock? existing) {
    final now = DateTime.now();
    final bool isFutureGap = existing == null && start.isAfter(now.subtract(const Duration(minutes: 2)));
    final defaultStatus = isFutureGap ? BlockStatus.planned : BlockStatus.completed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => QuickLogSheet(
        initialStartTime: start,
        initialEndTime: end,
        categories: _categories.values.toList(),
        moods: _moods,
        existingBlock: existing,
        defaultStatus: defaultStatus,
      ),
    ).then((didSave) {
      if (didSave == true) {
        _loadDropdownData();
        _loadDataForDate(_selectedDate); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => _animateToDate(-1)),
            GestureDetector(
              onTap: () {
                _pageController.animateToPage(_initialPage, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
              },
              child: Text(
                DateFormat('EEE, d MMM yyyy').format(_selectedDate).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.5, // Reduced slightly to fit the longer day text
                  color: isToday ? Colors.deepPurpleAccent : Colors.white, 
                  fontSize: 15,
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: () => _animateToDate(1)),
          ],
        ),
        actions: [
          // THE DIARY BUTTON
          IconButton(
            icon: const Icon(Icons.book_outlined, color: Colors.cyanAccent),
            tooltip: 'Daily Journal',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DailyJournalScreen(date: _selectedDate))),
          ),
        ],
      ),
      
      // THE PAGEVIEW (Cleanly using our new DailyCanvas widget!)
      body: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          final newDate = _getDateFromIndex(index);
          setState(() => _selectedDate = newDate);
          _loadDataForDate(newDate);
        },
        itemBuilder: (context, index) {
          final pageDate = _getDateFromIndex(index);
          final startOfPageDay = DateTime(pageDate.year, pageDate.month, pageDate.day);
          
          if (!_dailySegments.containsKey(startOfPageDay)) {
            _loadDataForDate(pageDate);
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
          }

          // RENDER THE CLEAN CANVAS COMPONENT
          return DailyCanvas(
            date: pageDate,
            segments: _dailySegments[startOfPageDay]!,
            currentTime: _currentTime,
            categories: _categories,
            scrollController: _getScrollController(pageDate),
            onBlockTap: _openSheet,
          );
        },
      ),
    );
  }
}