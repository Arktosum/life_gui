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
    // If the block is less than ~7 minutes (at 240px/hr), it's a "sliver"
    final bool isSliver = height < 30.0;

    return Container(
      height: height,
      width: double.infinity,
      margin: const EdgeInsets.only(right: 16, bottom: 2),
      decoration: BoxDecoration(
        color: Color(category.colorVal).withOpacity(0.15),
        border: Border(
          left: BorderSide(color: Color(category.colorVal), width: isSliver ? 2 : 4),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: isSliver 
          ? EdgeInsets.zero 
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: isSliver 
          ? const SizedBox.shrink() // Don't try to cram text into tiny boxes!
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name.toUpperCase(),
                  style: TextStyle(
                    color: Color(category.colorVal),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (block.remarks.isNotEmpty && height > 50) ...[
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      block.remarks,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}