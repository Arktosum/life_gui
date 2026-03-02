class MoodPreset {
  final int? id;
  final String name;
  final String emoji;

  // The 8 Plutchik Axes (0.0 to 1.0)
  final double joy;
  final double trust;
  final double fear;
  final double surprise;
  final double sadness;
  final double disgust;
  final double anger;
  final double anticipation;

  const MoodPreset({
    this.id,
    required this.name,
    required this.emoji,
    this.joy = 0.0,
    this.trust = 0.0,
    this.fear = 0.0,
    this.surprise = 0.0,
    this.sadness = 0.0,
    this.disgust = 0.0,
    this.anger = 0.0,
    this.anticipation = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'joy': joy,
      'trust': trust,
      'fear': fear,
      'surprise': surprise,
      'sadness': sadness,
      'disgust': disgust,
      'anger': anger,
      'anticipation': anticipation,
    };
  }

  factory MoodPreset.fromMap(Map<String, dynamic> map) {
    return MoodPreset(
      id: map['id'] as int?,
      name: map['name'] as String,
      emoji: map['emoji'] as String,
      joy: (map['joy'] as num).toDouble(),
      trust: (map['trust'] as num).toDouble(),
      fear: (map['fear'] as num).toDouble(),
      surprise: (map['surprise'] as num).toDouble(),
      sadness: (map['sadness'] as num).toDouble(),
      disgust: (map['disgust'] as num).toDouble(),
      anger: (map['anger'] as num).toDouble(),
      anticipation: (map['anticipation'] as num).toDouble(),
    );
  }
}
