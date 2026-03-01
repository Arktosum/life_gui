import 'package:flutter/material.dart';
import 'dart:async';
import '../database/database_helper.dart';
import '../models/time_block.dart';
import '../models/category.dart';
import '../logic/timeline_engine.dart';
import '../logic/timeline_segment.dart';
import '../widgets/timeline/timeline_canvas.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final TimelineEngine _engine = const TimelineEngine();
  List<TimelineSegment> _segments = [];
  Map<int, ActivityCategory> _categories = {};
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
          _loadData();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final DateTime startOfDay = DateTime(
        _currentTime.year,
        _currentTime.month,
        _currentTime.day,
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
          _segments = _engine.generateSegments(_currentTime, blocks);
          _errorMessage = null; // Clear any old errors
        });
      }
    } catch (e) {
      // NEW: Catch the silent crash and update the UI
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _handleGapTap(TimelineSegment segment) {
    // Phase 4: Trigger Bottom Sheet pre-filled with this gap's start/end time
  }

  void _handleBlockTap(TimelineSegment segment) {
    // Phase 4: Trigger Bottom Sheet in Edit Mode with this block's data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'LIFE GUI',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: _errorMessage != null
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
          : _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120, top: 20),
              child: TimelineCanvas(
                segments: _segments,
                categories: _categories,
                engine: _engine,
                currentTime: _currentTime,
                onGapTap: _handleGapTap,
                onBlockTap: _handleBlockTap,
              ),
            ),
    );
  }
}
