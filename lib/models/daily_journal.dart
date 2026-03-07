class DailyJournal {
  final String dateId; // Format: YYYY-MM-DD
  final String content;

  DailyJournal({required this.dateId, required this.content});

  Map<String, dynamic> toMap() => {'date_id': dateId, 'content': content};

  factory DailyJournal.fromMap(Map<String, dynamic> map) =>
      DailyJournal(dateId: map['date_id'], content: map['content']);
}
