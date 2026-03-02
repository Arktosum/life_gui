import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/time_block.dart';
import '../models/mood_preset.dart';
import '../database/database_helper.dart';
import '../logic/timeline_engine.dart';
import '../widgets/timeline/solid_segment_widget.dart';
import '../widgets/timeline/quick_log_sheet.dart';

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

  // FIX 1: Add a ScrollController to remember where you are!
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startTicker();
    _loadDropdownData();
    _loadDataForDate(_selectedDate);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _scrollController.dispose();
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

  Future<void> _loadDropdownData() async {
    try {
      final categoriesList = await DatabaseHelper.instance
          .getActiveCategories();
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

    // FIX 1: Only show the loading spinner if we are switching to a completely new day.
    // If we are just refreshing the current day after adding a block, do it silently!
    if (_dailySegments[startOfDay] == null && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final blocks = await DatabaseHelper.instance.getTimeBlocksForDateRange(
        startOfDay,
        endOfDay,
      );

      if (mounted) {
        setState(() {
          final isToday = DateUtils.isSameDay(startOfDay, _currentTime);

          _dailySegments[startOfDay] = _engine.generateSegments(
            startOfDay,
            blocks,
            playheadTime: isToday ? _currentTime : null,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🔥 SQL ERROR loading blocks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadDataForDate(_selectedDate);

    // Jump to the top of the new day when you swipe
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _openSheet({
    required DateTime start,
    required DateTime end,
    TimeBlock? existing,
  }) {
    final now = DateTime.now();
    final bool isFutureGap =
        existing == null &&
        start.isAfter(now.subtract(const Duration(minutes: 2)));
    final defaultStatus = isFutureGap
        ? BlockStatus.planned
        : BlockStatus.completed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
        // Notice we DO NOT mess with the scroll controller here, so it stays perfectly still!
      }
    });
  }

  double _calculateHeight(DateTime start, DateTime end) {
    final int minutes = end.difference(start).inMinutes;
    return (minutes / 60.0) * 80.0;
  }

  double _calculatePlayheadPosition(List<TimelineSegment> segments) {
    double yOffset = 0.0;
    for (var segment in segments) {
      if (_currentTime.isAfter(segment.startTime) &&
          _currentTime.isBefore(segment.endTime)) {
        final elapsedMinutes = _currentTime
            .difference(segment.startTime)
            .inMinutes;
        yOffset += (elapsedMinutes / 60.0) * 80.0;
        break;
      } else if (_currentTime.isAfter(segment.endTime) ||
          _currentTime.isAtSameMomentAs(segment.endTime)) {
        yOffset += _calculateHeight(segment.startTime, segment.endTime) + 2;
      }
    }
    return yOffset - 3;
  }

  @override
  Widget build(BuildContext context) {
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final segments = _dailySegments[startOfDay] ?? [];
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () => _changeDate(-1),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _selectedDate = DateTime.now());
                _loadDataForDate(_selectedDate);
                if (_scrollController.hasClients) _scrollController.jumpTo(0);
              },
              child: Text(
                isToday
                    ? "TODAY"
                    : DateFormat(
                        'MMM d, yyyy',
                      ).format(_selectedDate).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: isToday ? Colors.deepPurpleAccent : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
      ),
      body: _isLoading && segments.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            )
          // FIX 2: Wrapped the whole scroll view in a GestureDetector for horizontal swiping!
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! > 300) {
                    _changeDate(-1); // Swipe Right -> Yesterday
                  } else if (details.primaryVelocity! < -300) {
                    _changeDate(1); // Swipe Left -> Tomorrow
                  }
                }
              },
              child: SingleChildScrollView(
                controller: _scrollController, // Attach the memory controller!
                padding: const EdgeInsets.symmetric(vertical: 20),
                physics: const BouncingScrollPhysics(),
                child: Stack(
                  children: [
                    Column(
                      children: segments.map((segment) {
                        final height = _calculateHeight(
                          segment.startTime,
                          segment.endTime,
                        );
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 70,
                              child: Text(
                                DateFormat('HH:mm').format(segment.startTime),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _openSheet(
                                  start: segment.startTime,
                                  end: segment.endTime,
                                  existing: segment.block,
                                ),
                                child: segment.isGap
                                    ? Container(
                                        height: height,
                                        margin: const EdgeInsets.only(
                                          right: 16,
                                          bottom: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.02),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.add,
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                          ),
                                        ),
                                      )
                                    : SolidSegmentWidget(
                                        block: segment.block!,
                                        category:
                                            _categories[segment
                                                .block!
                                                .categoryId] ??
                                            const ActivityCategory(
                                              name: 'Unknown',
                                              colorVal: 0xFF9E9E9E,
                                            ),
                                        height: height,
                                      ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),

                    if (isToday)
                      Positioned(
                        top: _calculatePlayheadPosition(segments),
                        left: 66,
                        right: 16,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: Colors.redAccent.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
