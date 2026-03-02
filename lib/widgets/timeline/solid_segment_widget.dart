import 'package:flutter/material.dart';
import '../../models/time_block.dart';
import '../../models/category.dart';

class SolidSegmentWidget extends StatelessWidget {
  final TimeBlock block;
  final ActivityCategory category;
  final double height;

  const SolidSegmentWidget({
    super.key,
    required this.block,
    required this.category,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSliver = height < 30.0;

    final now = DateTime.now();
    bool isActuallyMissed =
        block.status == BlockStatus.missed ||
        (block.status == BlockStatus.planned && block.endTime.isBefore(now));

    final bool isGhost =
        block.status == BlockStatus.planned && !isActuallyMissed;

    final Color baseColor = Color(category.colorVal);
    final Color contentColor = isGhost ? baseColor.withOpacity(0.8) : baseColor;

    BoxDecoration decoration;

    if (isActuallyMissed) {
      // MISSED: Subtle Red Warning
      decoration = BoxDecoration(
        color: Colors.redAccent.withOpacity(0.05),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(8),
      );
    } else if (isGhost) {
      // PLANNED (GHOST): The Blueprint Look
      decoration = BoxDecoration(
        color: baseColor.withOpacity(0.03), // Frosted, barely-there background
        border: Border(
          left: BorderSide(
            color: baseColor.withOpacity(0.8),
            width: 3,
          ), // Glowing left edge
          top: BorderSide(color: baseColor.withOpacity(0.15), width: 1),
          right: BorderSide(color: baseColor.withOpacity(0.15), width: 1),
          bottom: BorderSide(color: baseColor.withOpacity(0.15), width: 1),
        ),
        borderRadius: BorderRadius.circular(8),
      );
    } else {
      // COMPLETED: The Solid Look
      decoration = BoxDecoration(
        color: baseColor.withOpacity(0.15),
        border: Border(
          left: BorderSide(color: baseColor, width: isSliver ? 2 : 4),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      );
    }

    return Container(
      height: height,
      width: double.infinity,
      margin: const EdgeInsets.only(right: 16, bottom: 2),
      decoration: decoration,
      padding: isSliver
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: isSliver
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        category.name.toUpperCase(),
                        style: TextStyle(
                          color: contentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Add visual icons based on state!
                    if (isActuallyMissed)
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 14,
                      )
                    else if (isGhost)
                      Icon(
                        Icons.schedule_rounded,
                        color: baseColor.withOpacity(0.6),
                        size: 14,
                      ), // Waiting Icon
                  ],
                ),
                if (block.remarks.isNotEmpty && height > 50) ...[
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      block.remarks,
                      style: TextStyle(
                        color: isGhost ? Colors.white38 : Colors.white60,
                        fontSize: 12,
                        fontStyle: isGhost
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
