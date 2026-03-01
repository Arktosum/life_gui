import 'package:flutter/material.dart';

class TimelinePlayhead extends StatelessWidget {
  const TimelinePlayhead({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent,
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 1.5,
            color: Colors.redAccent.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
