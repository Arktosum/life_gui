import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/time_block.dart';

// THE MAGIC: Real-time syntax highlighting for your plaintext tags!
class TagHighlightingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final RegExp tagRegex = RegExp(r'([@#][a-zA-Z0-9_]+)');
    final List<TextSpan> spans = [];

    text.splitMapJoin(
      tagRegex,
      onMatch: (Match match) {
        final String word = match[0]!;
        // @People are Purple, #Places/Concepts are Cyan
        final Color color = word.startsWith('@')
            ? Colors.deepPurpleAccent
            : Colors.cyanAccent;
        spans.add(
          TextSpan(
            text: word,
            style: style?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        );
        return word;
      },
      onNonMatch: (String text) {
        spans.add(TextSpan(text: text, style: style));
        return text;
      },
    );
    return TextSpan(children: spans, style: style);
  }
}

class DailyJournalScreen extends StatefulWidget {
  final DateTime date;
  const DailyJournalScreen({super.key, required this.date});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  late String _dateId;
  final TagHighlightingController _textController = TagHighlightingController();

  bool _isLoading = true;
  int _totalTrackedMinutes = 0;
  List<TimeBlock> _blocksWithRemarks = [];

  @override
  void initState() {
    super.initState();
    _dateId = DateFormat('yyyy-MM-dd').format(widget.date);
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Load the Journal Entry
    final savedContent = await DatabaseHelper.instance.getJournalContent(
      _dateId,
    );
    if (savedContent != null) {
      _textController.text = savedContent;
    }

    // 2. Load the Day's Summary Data
    final startOfDay = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
    final endOfDay = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      23,
      59,
      59,
    );
    final blocks = await DatabaseHelper.instance.getTimeBlocksForDateRange(
      startOfDay,
      endOfDay,
    );

    int totalMins = 0;
    List<TimeBlock> withRemarks = [];

    for (var b in blocks) {
      if (b.status == BlockStatus.completed) {
        totalMins += b.endTime.difference(b.startTime).inMinutes;
      }
      if (b.remarks.isNotEmpty) {
        withRemarks.add(b);
      }
    }

    if (mounted) {
      setState(() {
        _totalTrackedMinutes = totalMins;
        _blocksWithRemarks = withRemarks;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndExit() async {
    await DatabaseHelper.instance.saveJournalContent(
      _dateId,
      _textController.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _saveAndExit,
        ),
        title: Text(
          DateFormat('EEEE, MMM d').format(widget.date).toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: _saveAndExit,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            )
          : Column(
              children: [
                // --- THE DAILY CONTEXT HEADER ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.analytics_outlined,
                            color: Colors.white54,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tracked: ${_totalTrackedMinutes ~/ 60}h ${_totalTrackedMinutes % 60}m',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_blocksWithRemarks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'NOTABLE REMARKS:',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ..._blocksWithRemarks.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              '• ${b.remarks}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // --- THE TEXT EDITOR ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.6,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        hintText: "What's the context behind today's data?",
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
