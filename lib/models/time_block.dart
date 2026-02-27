import 'package:flutter/material.dart';

class TimeBlock {
  final int? id; // For SQLite
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  final String remarks;
  // Plutchik's 8 core emotions (Values 0-5)
  final Map<String, int> emotions;
  final Color blockColor;

  TimeBlock({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.remarks = '',
    required this.emotions,
    required this.blockColor,
  });

  // We'll add toMap() and fromMap() later when we wire up SQLite!
}
