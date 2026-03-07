import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/category.dart';
import '../../../models/time_block.dart';
import '../../../logic/timeline_engine.dart';
import 'solid_segment_widget.dart';
class DailyCanvas extends StatelessWidget {
  final DateTime date;
  final List<TimelineSegment> segments;
  final DateTime currentTime;
  final Map<int, ActivityCategory> categories;
  final ScrollController scrollController;
  final Function(DateTime start, DateTime end, TimeBlock? existing) onBlockTap;

  const DailyCanvas({
    super.key,
    required this.date,
    required this.segments,
    required this.currentTime,
    required this.categories,
    required this.scrollController,
    required this.onBlockTap,
  });

  double _calculateHeight(DateTime start, DateTime end) {
    final int minutes = end.difference(start).inMinutes;
    return (minutes / 60.0) * 80.0; // 80 pixels per hour
  }

  double _calculatePlayheadPosition() {
    double yOffset = 0.0;
    for (var segment in segments) {
      if (currentTime.isAfter(segment.startTime) &&
          currentTime.isBefore(segment.endTime)) {
        final elapsedMinutes = currentTime
            .difference(segment.startTime)
            .inMinutes;
        yOffset += (elapsedMinutes / 60.0) * 80.0;
        break;
      } else if (currentTime.isAfter(segment.endTime) ||
          currentTime.isAtSameMomentAs(segment.endTime)) {
        yOffset += _calculateHeight(segment.startTime, segment.endTime) + 2;
      }
    }
    return yOffset - 3; // Shift up slightly for perfect alignment
  }

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 20),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
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
                  // TIME COLUMN
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

                  // BLOCK / GAP COLUMN
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onBlockTap(
                        segment.startTime,
                        segment.endTime,
                        segment.block,
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
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            )
                          : SolidSegmentWidget(
                              block: segment.block!,
                              category:
                                  categories[segment.block!.categoryId] ??
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

          // THE RED PLAYHEAD
          if (isToday)
            Positioned(
              top: _calculatePlayheadPosition(),
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
    );
  }
}
