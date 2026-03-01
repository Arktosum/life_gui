import 'package:flutter/material.dart';

class GapSegmentWidget extends StatelessWidget {
  final double height;
  final bool isPast;
  final VoidCallback onTap;

  const GapSegmentWidget({
    super.key,
    required this.height,
    required this.isPast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        width: double.infinity,
        margin: const EdgeInsets.only(right: 16, bottom: 2),
        decoration: BoxDecoration(
          // FIX: Cranked the opacity up to 0.15 for the fill and 0.8 for the border
          color: isPast
              ? Colors.redAccent.withOpacity(0.15)
              : Colors.transparent,
          border: isPast
              ? Border.all(color: Colors.redAccent.withOpacity(0.8), width: 2.0)
              : Border.all(
                  color: Colors.white.withOpacity(0.05),
                  style: BorderStyle.solid,
                ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isPast && height > 40
            ? Center(
                child: Text(
                  'UNACCOUNTED TIME',
                  style: TextStyle(
                    color: Colors.redAccent.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
