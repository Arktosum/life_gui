enum BlockStatus {
  completed, 
  planned,   
  missed     
}

class TimeBlock {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final int categoryId;
  final String remarks;
  final BlockStatus status; 
  final String intensities; // NEW: The emotional data string!

  TimeBlock({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.categoryId,
    this.remarks = '',
    this.status = BlockStatus.completed,
    this.intensities = '', // Default to empty string to satisfy SQLite's NOT NULL constraint
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'category_id': categoryId,
      'remarks': remarks,
      'status': status.name, 
      'intensities': intensities, // Send it to the database!
    };
  }

  factory TimeBlock.fromMap(Map<String, dynamic> map) {
    final statusString = map['status'] as String?;
    final parsedStatus = BlockStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => BlockStatus.completed,
    );

    return TimeBlock(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      categoryId: map['category_id'] as int,
      remarks: map['remarks'] as String? ?? '',
      status: parsedStatus,
      intensities: map['intensities'] as String? ?? '', // Safely read it back
    );
  }
}