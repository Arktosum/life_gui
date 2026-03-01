import 'package:flutter/material.dart';
import 'dart:async';
import '../database/database_helper.dart';
import '../models/time_block.dart';
import '../models/category.dart';
import '../logic/timeline_engine.dart';
import '../logic/timeline_segment.dart';
import '../widgets/timeline/timeline_canvas.dart';
import '../widgets/timeline/quick_log_sheet.dart';
import '../widgets/timeline/date_selector.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final TimelineEngine _engine = const TimelineEngine();
  List<TimelineSegment> _segments = [];
  Map<int, ActivityCategory> _categories = {};

  DateTime _currentTime = DateTime.now(); // For the Playhead
  late DateTime _selectedDate; // NEW: For navigating days

  Timer? _timer;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // Default to today
    _loadData();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
          // Only force a heavy DB reload on the timer if we are actually viewing today
          if (DateUtils.isSameDay(_selectedDate, _currentTime)) {
            _loadData();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Handle user changing the date via the DateSelector
  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _isLoading = true;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // FIX: Query using _selectedDate instead of _currentTime
      final DateTime startOfDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      final List<TimeBlock> blocks = await DatabaseHelper.instance
          .getTimeBlocksForDateRange(startOfDay, endOfDay);
      final List<ActivityCategory> activeCategories = await DatabaseHelper
          .instance
          .getActiveCategories();

      final Map<int, ActivityCategory> categoryMap = {
        for (var cat in activeCategories) cat.id!: cat,
      };

      if (mounted) {
        setState(() {
          _categories = categoryMap;
          // Generate segments based on the selected target date
          _segments = _engine.generateSegments(startOfDay, blocks);
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _handleGapTap(TimelineSegment segment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickLogSheet(
        initialStartTime: segment.startTime,
        initialEndTime: segment.endTime,
        categories: _categories.values.toList(),
      ),
    ).then((didSave) {
      if (didSave == true) _loadData();
    });
  }

  void _handleBlockTap(TimelineSegment segment) {
    if (segment.block == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickLogSheet(
        initialStartTime: segment.startTime,
        initialEndTime: segment.endTime,
        categories: _categories.values.toList(),
        existingBlock: segment.block,
      ),
    ).then((didSave) {
      if (didSave == true) _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'LIFE GUI',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          DateSelector(
            selectedDate: _selectedDate,
            onDateChanged: _onDateChanged,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'DATABASE ERROR:\n\n$_errorMessage',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120, top: 10),
                    child: TimelineCanvas(
                      segments: _segments,
                      categories: _categories,
                      engine: _engine,
                      currentTime: _currentTime,
                      selectedDate: _selectedDate, // Passed down!
                      onGapTap: _handleGapTap,
                      onBlockTap: _handleBlockTap,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
