import '../models/time_block.dart';

class TimelineSegment {
  final DateTime startTime;
  final DateTime endTime;
  final bool isGap;
  final TimeBlock? block;

  const TimelineSegment({
    required this.startTime,
    required this.endTime,
    required this.isGap,
    this.block,
  });

  Duration get duration => endTime.difference(startTime);
}