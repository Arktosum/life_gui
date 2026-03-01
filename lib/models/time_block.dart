import 'dart:convert';

class TimeBlock {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final int categoryId;
  final String remarks;
  final List<double> intensities;
  final int? calculatedColor;

  const TimeBlock({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.categoryId,
    this.remarks = '',
    this.intensities = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    this.calculatedColor,
  });

  TimeBlock copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? categoryId,
    String? remarks,
    List<double>? intensities,
    int? calculatedColor,
  }) {
    return TimeBlock(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      categoryId: categoryId ?? this.categoryId,
      remarks: remarks ?? this.remarks,
      intensities: intensities ?? this.intensities,
      calculatedColor: calculatedColor ?? this.calculatedColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'category_id': categoryId,
      'remarks': remarks,
      'intensities': jsonEncode(intensities),
      'calculated_color': calculatedColor,
    };
  }

  factory TimeBlock.fromMap(Map<String, dynamic> map) {
    return TimeBlock(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      categoryId: map['category_id'] as int,
      remarks: map['remarks'] as String,
      intensities: List<double>.from(jsonDecode(map['intensities'] as String)),
      calculatedColor: map['calculated_color'] as int?,
    );
  }
}