import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_gui/widgets/log_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  final DateTime pivotDate;
  const HomeScreen({super.key, required this.pivotDate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // We now track the exact DateTime instead of list indices!
  DateTime? _startTime;
  DateTime? _endTime;

  // The magic key that tells Flutter exactly where "Today" starts
  final Key _centerKey = const ValueKey('present-sliver');

  void _handleTap(DateTime tappedTime) {
    setState(() {
      if (_startTime == null || (_startTime != null && _endTime != null)) {
        // First tap: start a new selection
        _startTime = tappedTime;
        _endTime = null;
      } else {
        // Second tap: end selection and OPEN THE SHEET!
        _endTime = tappedTime;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true, // Needed so it can take up 85% of screen
          backgroundColor: Colors.transparent,
          builder: (context) =>
              LogBottomSheet(startTime: _startTime!, endTime: _endTime!),
        ).then((_) {
          // When the sheet closes, clear the selection so you can log again
          setState(() {
            _startTime = null;
            _endTime = null;
          });
        });
      }
    });
  }

  // Helper function to check if a block is inside the selected range
  bool _isSelected(DateTime time) {
    if (_startTime != null && _endTime == null) {
      return time == _startTime;
    } else if (_startTime != null && _endTime != null) {
      DateTime lower = _startTime!.isBefore(_endTime!)
          ? _startTime!
          : _endTime!;
      DateTime upper = _startTime!.isAfter(_endTime!) ? _startTime! : _endTime!;
      return (time.isAtSameMomentAs(lower) || time.isAfter(lower)) &&
          (time.isAtSameMomentAs(upper) || time.isBefore(upper));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Normalize pivot to exactly 00:00 of the tapped day
    DateTime pivotMidnight = DateTime(
      widget.pivotDate.year,
      widget.pivotDate.month,
      widget.pivotDate.day,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('EEE, MMM d, yyyy').format(widget.pivotDate).toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: CustomScrollView(
        // This key tells the scroll view to start exactly between the two lists
        center: _centerKey,
        slivers: [
          // --- 1. THE PAST (Scrolls UPWARDS) ---
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // index 0 is 23:00 the day before. It calculates backward.
                DateTime blockTime = pivotMidnight.subtract(
                  Duration(hours: index + 1),
                );
                return _buildHourWithHeader(blockTime, false);
              },
              childCount: 7 * 24, // 7 days into the past
            ),
          ),

          // --- 2. THE PRESENT & FUTURE (Scrolls DOWNWARDS) ---
          SliverList(
            key: _centerKey,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // index 0 is 00:00 of the Pivot Day. It calculates forward.
                DateTime blockTime = pivotMidnight.add(Duration(hours: index));
                return _buildHourWithHeader(
                  blockTime,
                  blockTime.isAtSameMomentAs(pivotMidnight),
                );
              },
              childCount: 8 * 24, // Pivot day + 7 days into the future
            ),
          ),
        ],
      ),
    );
  }

  // A helper to draw the Midnight Header and the Hour Block together
  Widget _buildHourWithHeader(DateTime blockTime, bool isPivotDay) {
    final timeString = DateFormat('HH:mm').format(blockTime);
    Widget hourBlock = _buildHourBlock(context, timeString, blockTime);

    if (blockTime.hour == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0, left: 20.0),
            child: Text(
              isPivotDay
                  ? 'TODAY'
                  : DateFormat('EEE, MMM d').format(blockTime).toUpperCase(),
              style: TextStyle(
                color: isPivotDay ? Colors.deepPurpleAccent : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          hourBlock,
        ],
      );
    }
    return hourBlock;
  }

  // The actual block UI
  Widget _buildHourBlock(
    BuildContext context,
    String timeString,
    DateTime blockTime,
  ) {
    bool isSelected = _isSelected(blockTime);
    bool isStart =
        _startTime != null && _endTime == null && blockTime == _startTime;

    return GestureDetector(
      onTap: () => _handleTap(blockTime),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
        height: isStart ? 95 : 80,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF252530) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? Colors.deepPurpleAccent
                : Colors.white.withOpacity(0.05),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 75,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isSelected
                        ? Colors.deepPurpleAccent.withOpacity(0.3)
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              child: Text(
                timeString,
                style: GoogleFonts.jetBrainsMono(
                  color: isSelected ? Colors.deepPurpleAccent : Colors.white54,
                  fontSize: isSelected ? 18 : 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _startTime != null && _endTime == null && !isSelected
                      ? 'Tap to end range...'
                      : (isSelected ? 'Logging...' : 'Tap to log...'),
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.white24,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.add_circle_outline,
                color: isSelected ? Colors.deepPurpleAccent : Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
