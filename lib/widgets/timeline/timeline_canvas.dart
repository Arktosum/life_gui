import 'package:flutter/material.dart';
import '../../logic/timeline_engine.dart';
import '../../logic/timeline_segment.dart';
import '../../models/category.dart';
import 'solid_segment_widget.dart';
import 'gap_segment_widget.dart';
import 'timeline_playhead.dart';

class TimelineCanvas extends StatelessWidget {
  final List<TimelineSegment> segments;
  final Map<int, ActivityCategory> categories;
  final TimelineEngine engine;
  final DateTime currentTime;
  final Function(TimelineSegment) onGapTap;
  final Function(TimelineSegment) onBlockTap;

  const TimelineCanvas({
    super.key,
    required this.segments,
    required this.categories,
    required this.engine,
    required this.currentTime,
    required this.onGapTap,
    required this.onBlockTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24 * engine.pixelsPerHour,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildBackgroundGutter(),
          ..._buildSegments(),
          _buildPlayhead(),
        ],
      ),
    );
  }

  Widget _buildBackgroundGutter() {
    return Stack(
      children: List.generate(24, (index) {
        final double topOffset = index * engine.pixelsPerHour;
        return Positioned(
          top: topOffset,
          left: 0,
          right: 0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '${index.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 7),
                  height: 1,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _buildSegments() {
    return segments.map((segment) {
      final double topOffset = engine.calculateOffsetFromMidnight(
        segment.startTime,
      );
      final double height = engine.calculateHeight(segment.duration);

      return Positioned(
        top: topOffset,
        left: 60,
        right: 0,
        height: height,
        child: segment.isGap
            ? GapSegmentWidget(
                height: height,
                isPast: segment.endTime.isBefore(currentTime),
                onTap: () => onGapTap(segment),
              )
            : GestureDetector(
                onTap: () => onBlockTap(segment),
                child: SolidSegmentWidget(
                  block: segment.block!,
                  category: categories[segment.block!.categoryId]!,
                  height: height,
                ),
              ),
      );
    }).toList();
  }

  Widget _buildPlayhead() {
    final double topOffset = engine.calculateOffsetFromMidnight(currentTime);

    return Positioned(
      top: topOffset - 4,
      left: 56,
      right: 0,
      child: const TimelinePlayhead(),
    );
  }
}
