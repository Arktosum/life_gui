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
    final map = <String, dynamic>{
      'name': name,
      'color_val': colorVal,
      'is_active': isActive ? 1 : 0,
    };
    // Only add the ID if it actually exists!
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory ActivityCategory.fromMap(Map<String, dynamic> map) {
    // Safely handle SQLite's weird boolean translations
    final rawActive = map['is_active'];
    bool activeState = true; 
    
    if (rawActive != null) {
      activeState = (rawActive == 1 || rawActive == true || rawActive == '1');
    }

    return ActivityCategory(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Unnamed',
      colorVal: map['color_val'] as int? ?? 0xFF9E9E9E,
      isActive: activeState,
    );
  }
}
