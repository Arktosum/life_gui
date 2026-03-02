import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/time_block.dart';
import '../database/database_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // 0: Today, 1: Week, 2: Month, 3: Year, 4: Custom
  int _selectedFilterIndex = 0;
  DateTime? _customStart;
  DateTime? _customEnd;

  bool _isLoading = true;

  Map<ActivityCategory, Duration> _categoryDurations = {};
  Duration _totalTrackedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _crunchNumbers();
  }

  Future<void> _crunchNumbers() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    late DateTime startOfRange;
    late DateTime endOfRange;

    // 1. Determine the exact boundaries for our SQL query
    if (_selectedFilterIndex == 0) {
      // TODAY
      startOfRange = DateTime(now.year, now.month, now.day);
      endOfRange = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_selectedFilterIndex == 1) {
      // WEEK (Last 7 Days)
      startOfRange = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));
      endOfRange = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_selectedFilterIndex == 2) {
      // MONTH (Last 30 Days)
      startOfRange = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 29));
      endOfRange = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_selectedFilterIndex == 3) {
      // YEAR (Last 365 Days)
      startOfRange = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 364));
      endOfRange = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_selectedFilterIndex == 4 &&
        _customStart != null &&
        _customEnd != null) {
      // CUSTOM
      startOfRange = _customStart!;
      // Ensure the end range covers the absolute end of the selected day
      endOfRange = DateTime(
        _customEnd!.year,
        _customEnd!.month,
        _customEnd!.day,
        23,
        59,
        59,
      );
    } else {
      // Fallback safety
      startOfRange = DateTime(now.year, now.month, now.day);
      endOfRange = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    // 2. Fetch the Blocks and Categories
    final blocks = await DatabaseHelper.instance.getTimeBlocksForDateRange(
      startOfRange,
      endOfRange,
    );
    final allCategories = await DatabaseHelper.instance.getAllCategories();
    final categoryMap = {for (var cat in allCategories) cat.id!: cat};

    // 3. Crunch the Durations
    Duration totalTime = Duration.zero;
    Map<ActivityCategory, Duration> durations = {};

    for (var block in blocks) {
      final category = categoryMap[block.categoryId];
      if (category == null) continue;

      // Mathematically clamp blocks that cross over the edges of our requested date range
      DateTime blockStart = block.startTime.isBefore(startOfRange)
          ? startOfRange
          : block.startTime;
      DateTime blockEnd = block.endTime.isAfter(endOfRange)
          ? endOfRange
          : block.endTime;

      final blockDuration = blockEnd.difference(blockStart);
      if (blockDuration.isNegative) continue;

      totalTime += blockDuration;
      durations[category] =
          (durations[category] ?? Duration.zero) + blockDuration;
    }

    var sortedEntries = durations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (mounted) {
      setState(() {
        _categoryDurations = Map.fromEntries(sortedEntries);
        _totalTrackedTime = totalTime;
        _isLoading = false;
      });
    }
  }

  // --- UI Interactions ---

  Future<void> _handleCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
      firstDate: DateTime(2024), // How far back they can search
      lastDate: DateTime.now(), // Can't search the future
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepPurpleAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF252530),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _selectedFilterIndex = 4; // Lock in the Custom index
      });
      _crunchNumbers();
    }
  }

  void _onFilterTapped(int index) {
    if (index == 4) {
      _handleCustomDateRange();
    } else {
      setState(() => _selectedFilterIndex = index);
      _crunchNumbers();
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String get _customLabel {
    if (_customStart == null || _customEnd == null) return 'CUSTOM';
    final fmt = DateFormat('MMM d');
    return '${fmt.format(_customStart!)} - ${fmt.format(_customEnd!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          'ANALYTICS',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Scrollable Filter Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: const Color(0xFF1E1E1E),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterButton('TODAY', 0),
                  const SizedBox(width: 8),
                  _buildFilterButton('WEEK', 1),
                  const SizedBox(width: 8),
                  _buildFilterButton('MONTH', 2),
                  const SizedBox(width: 8),
                  _buildFilterButton('YEAR', 3),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    _selectedFilterIndex == 4 ? _customLabel : 'CUSTOM',
                    4,
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _totalTrackedTime.inMinutes == 0
                ? const Center(
                    child: Text(
                      'No data tracked for this period.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _crunchNumbers,
                    color: Colors.deepPurpleAccent,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'TOTAL TRACKED',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDuration(_totalTrackedTime),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        const Text(
                          'TIME DISTRIBUTION',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        ..._categoryDurations.entries.map((entry) {
                          final category = entry.key;
                          final duration = entry.value;
                          final double percentage =
                              duration.inMinutes / _totalTrackedTime.inMinutes;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 6,
                                          backgroundColor: Color(
                                            category.colorVal,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          category.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  children: [
                                    Container(
                                      height: 8,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: percentage,
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Color(category.colorVal),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(
                                                category.colorVal,
                                              ).withOpacity(0.4),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String title, int index) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => _onFilterTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurpleAccent.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.deepPurpleAccent : Colors.white12,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.deepPurpleAccent : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
