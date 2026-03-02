import '../models/time_block.dart';

// THE MISSING CLASS!
class TimelineSegment {
  final DateTime startTime;
  final DateTime endTime;
  final bool isGap;
  final TimeBlock? block;

  TimelineSegment({
    required this.startTime,
    required this.endTime,
    required this.isGap,
    this.block,
  });
}

class TimelineEngine {
  List<TimelineSegment> generateSegments(
    DateTime targetDate,
    List<TimeBlock> blocks, {
    DateTime? playheadTime,
  }) {
    final List<TimelineSegment> segments = [];
    final DateTime startOfDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    DateTime currentTime = startOfDay;
    blocks.sort((a, b) => a.startTime.compareTo(b.startTime));

    void addGap(DateTime start, DateTime end) {
      if (start.isAtSameMomentAs(end) || start.isAfter(end)) return;

      // Slice the gap at the red playhead!
      if (playheadTime != null &&
          playheadTime.isAfter(start) &&
          playheadTime.isBefore(end)) {
        segments.add(
          TimelineSegment(startTime: start, endTime: playheadTime, isGap: true),
        );
        segments.add(
          TimelineSegment(startTime: playheadTime, endTime: end, isGap: true),
        );
      } else {
        segments.add(
          TimelineSegment(startTime: start, endTime: end, isGap: true),
        );
      }
    }

    for (final block in blocks) {
      if (block.startTime.isAfter(currentTime)) {
        addGap(currentTime, block.startTime);
      }

      segments.add(
        TimelineSegment(
          startTime: block.startTime,
          endTime: block.endTime,
          isGap: false,
          block: block,
        ),
      );

      if (block.endTime.isAfter(currentTime)) {
        currentTime = block.endTime;
      }
    }

    if (currentTime.isBefore(endOfDay)) {
      addGap(currentTime, endOfDay);
    }

    return segments;
  }
}
