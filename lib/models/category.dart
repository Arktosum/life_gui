class ActivityCategory {
  final int? id;
  final String name;
  final int colorVal;
  final bool isActive;

  const ActivityCategory({
    this.id,
    required this.name,
    required this.colorVal,
    this.isActive = true,
  });

  ActivityCategory copyWith({
    int? id,
    String? name,
    int? colorVal,
    bool? isActive,
  }) {
    return ActivityCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorVal: colorVal ?? this.colorVal,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_val': colorVal,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory ActivityCategory.fromMap(Map<String, dynamic> map) {
    return ActivityCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorVal: map['color_val'] as int,
      isActive: (map['is_active'] as int) == 1,
    );
  }
}