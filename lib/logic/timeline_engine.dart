import '../models/time_block.dart';
import 'timeline_segment.dart';

class TimelineEngine {
  final double pixelsPerHour;
  final double minBlockHeight;

  const TimelineEngine({
    this.pixelsPerHour = 120.0,
    this.minBlockHeight = 48.0,
  });

  double get pixelsPerMinute => pixelsPerHour / 60.0;

  List<TimelineSegment> generateSegments(DateTime targetDate, List<TimeBlock> blocks) {
    final List<TimelineSegment> segments = [];
    final DateTime startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    DateTime currentTime = startOfDay;

    blocks.sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final block in blocks) {
      if (block.startTime.isAfter(currentTime)) {
        segments.add(TimelineSegment(
          startTime: currentTime,
          endTime: block.startTime,
          isGap: true,
        ));
      }

      segments.add(TimelineSegment(
        startTime: block.startTime,
        endTime: block.endTime,
        isGap: false,
        block: block,
      ));

      if (block.endTime.isAfter(currentTime)) {
        currentTime = block.endTime;
      }
    }

    if (currentTime.isBefore(endOfDay)) {
      segments.add(TimelineSegment(
        startTime: currentTime,
        endTime: endOfDay,
        isGap: true,
      ));
    }

    return segments;
  }

  double calculateHeight(Duration duration) {
    final double rawHeight = duration.inMinutes * pixelsPerMinute;
    return rawHeight < minBlockHeight ? minBlockHeight : rawHeight;
  }

  double calculateOffsetFromMidnight(DateTime time) {
    final int minutesSinceMidnight = time.hour * 60 + time.minute;
    return minutesSinceMidnight * pixelsPerMinute;
  }
}