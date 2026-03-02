import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // NEW: We need this to save the mood as a JSON string
import '../../models/category.dart';
import '../../models/time_block.dart';
import '../../models/mood_preset.dart'; // NEW
import '../../database/database_helper.dart';

class QuickLogSheet extends StatefulWidget {
  final DateTime initialStartTime;
  final DateTime initialEndTime;
  final List<ActivityCategory> categories;
  final List<MoodPreset> moods; // NEW: Receives the database moods
  final TimeBlock? existingBlock;
  final BlockStatus defaultStatus;

  const QuickLogSheet({
    super.key,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.categories,
    required this.moods, // NEW
    this.existingBlock,
    this.defaultStatus = BlockStatus.completed,
  });

  @override
  State<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<QuickLogSheet> {
  late DateTime _startTime;
  late DateTime _endTime;

  final TextEditingController _categoryController = TextEditingController();
  final FocusNode _categoryFocus = FocusNode();

  // NEW: Mood Controller State
  final TextEditingController _moodController = TextEditingController();
  final FocusNode _moodFocus = FocusNode();
  MoodPreset? _selectedMood;

  final TextEditingController _remarksController = TextEditingController();

  bool get _isEditing => widget.existingBlock != null;
  bool get _isVerifying =>
      _isEditing && widget.existingBlock!.status == BlockStatus.planned;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _startTime = widget.existingBlock!.startTime;
      _endTime = widget.existingBlock!.endTime;
      _remarksController.text = widget.existingBlock!.remarks;

      final matchedCat = widget.categories.firstWhere(
        (c) => c.id == widget.existingBlock!.categoryId,
        orElse: () => const ActivityCategory(name: '', colorVal: 0),
      );
      _categoryController.text = matchedCat.name;

      // Parse the saved JSON mood back into the text field so you can see what you logged!
      if (widget.existingBlock!.intensities.isNotEmpty) {
        try {
          final savedMoodMap = jsonDecode(widget.existingBlock!.intensities);
          _moodController.text =
              '${savedMoodMap['emoji']} ${savedMoodMap['name']}';
        } catch (e) {
          // Fallback if parsing fails
        }
      }
    } else {
      _startTime = widget.initialStartTime;
      if (widget.defaultStatus == BlockStatus.planned) {
        _endTime = widget.initialEndTime;
      } else {
        final now = DateTime.now();
        _endTime = widget.initialEndTime.isAfter(now)
            ? now
            : widget.initialEndTime;
      }
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _categoryFocus.dispose();
    _moodController.dispose();
    _moodFocus.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final initialTime = TimeOfDay.fromDateTime(isStart ? _startTime : _endTime);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() {
        final anchor = widget.initialStartTime;
        DateTime newDateTime = DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (isStart) {
          _startTime = newDateTime;
          if (_startTime.isAfter(_endTime))
            _endTime = _startTime.add(const Duration(hours: 1));
        } else {
          if (newDateTime.isBefore(_startTime) ||
              (newDateTime == _startTime && newDateTime.hour == 0)) {
            newDateTime = newDateTime.add(const Duration(days: 1));
          }
          _endTime = newDateTime;
        }
      });
    }
  }

  Future<void> _saveLog(BlockStatus targetStatus) async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isEmpty) return;

    final matchedCategory = await DatabaseHelper.instance.getOrCreateCategory(
      categoryName,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.deleteTimeBlock(widget.existingBlock!.id!);
    }
    await DatabaseHelper.instance.deleteOverlappingBlocks(_startTime, _endTime);

    // NEW: Encode the 8-dimensional vector into JSON for the database!
    String intensitiesJson = '';
    if (_selectedMood != null) {
      intensitiesJson = jsonEncode(_selectedMood!.toMap());
    } else if (_isEditing && _moodController.text.isNotEmpty) {
      intensitiesJson =
          widget.existingBlock!.intensities; // Keep it if they didn't touch it
    }

    final newBlock = TimeBlock(
      startTime: _startTime,
      endTime: _endTime,
      categoryId: matchedCategory.id ?? 0,
      remarks: _remarksController.text.trim(),
      status: targetStatus,
      intensities: intensitiesJson, // Safe and ready for analytics!
    );

    await DatabaseHelper.instance.insertTimeBlock(newBlock);

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteLog() async {
    if (_isEditing) {
      await DatabaseHelper.instance.deleteTimeBlock(widget.existingBlock!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final duration = _endTime.difference(_startTime);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => _pickTime(context, true),
                    child: Text(
                      timeFormat.format(_startTime),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ),
                  const Text(
                    '  →  ',
                    style: TextStyle(fontSize: 18, color: Colors.white54),
                  ),
                  InkWell(
                    onTap: () => _pickTime(context, false),
                    child: Text(
                      timeFormat.format(_endTime),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: _deleteLog,
                )
              else
                Text(
                  '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),

          if (_isVerifying)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Awaiting Verification',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // CATEGORY SEARCH BAR
          RawAutocomplete<ActivityCategory>(
            textEditingController: _categoryController,
            focusNode: _categoryFocus,
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.trim();
              if (query.isEmpty)
                return const Iterable<ActivityCategory>.empty();
              final matches = widget.categories
                  .where(
                    (option) =>
                        option.name.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();
              if (!matches.any(
                (c) => c.name.toLowerCase() == query.toLowerCase(),
              )) {
                matches.add(
                  ActivityCategory(id: -1, name: query, colorVal: 0xFF9E9E9E),
                );
              }
              return matches;
            },
            displayStringForOption: (option) => option.name,
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: !_isEditing,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: widget.defaultStatus == BlockStatus.planned
                          ? 'Plan Category'
                          : 'Category',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8.0,
                  color: const Color(0xFF252530),
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 300,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        final isCreate = option.id == -1;
                        return ListTile(
                          leading: isCreate
                              ? const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.deepPurpleAccent,
                                )
                              : CircleAvatar(
                                  radius: 8,
                                  backgroundColor: Color(option.colorVal),
                                ),
                          title: isCreate
                              ? Text(
                                  '✨ Create "${option.name}"',
                                  style: const TextStyle(
                                    color: Colors.deepPurpleAccent,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Text(
                                  option.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // NEW: MOOD PRESET SEARCH BAR
          RawAutocomplete<MoodPreset>(
            textEditingController: _moodController,
            focusNode: _moodFocus,
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.trim();
              if (query.isEmpty)
                return widget.moods; // Show all default moods if empty!

              final matches = widget.moods
                  .where(
                    (option) =>
                        option.name.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();

              if (!matches.any(
                    (m) => m.name.toLowerCase() == query.toLowerCase(),
                  ) &&
                  query.isNotEmpty) {
                matches.add(MoodPreset(id: -1, name: query, emoji: '✨'));
              }
              return matches;
            },
            displayStringForOption: (option) =>
                '${option.emoji} ${option.name}',
            onSelected: (option) {
              if (option.id == -1) {
                // They want to create a new mood!
                _moodController.clear();
                _moodFocus.unfocus();
                // TODO: Launch Plutchik Studio
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plutchik Studio coming next!')),
                );
              } else {
                _selectedMood = option;
              }
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Psychological State (Optional)',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.psychology_alt,
                        color: Colors.cyanAccent,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8.0,
                  color: const Color(0xFF252530),
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 300,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        final isCreate = option.id == -1;
                        return ListTile(
                          leading: Text(
                            option.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          title: isCreate
                              ? Text(
                                  'Open Studio for "${option.name}"',
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Text(
                                  option.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _remarksController,
            decoration: InputDecoration(
              labelText: 'Remarks (Optional)',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_isVerifying)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF252530),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _saveLog(BlockStatus.planned),
                      child: const Text(
                        'UPDATE PLAN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _saveLog(BlockStatus.completed),
                      child: const Text(
                        'VERIFY (DONE)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.defaultStatus == BlockStatus.planned
                      ? Colors.transparent
                      : Colors.deepPurpleAccent,
                  foregroundColor: widget.defaultStatus == BlockStatus.planned
                      ? Colors.deepPurpleAccent
                      : Colors.white,
                  side: widget.defaultStatus == BlockStatus.planned
                      ? const BorderSide(
                          color: Colors.deepPurpleAccent,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                onPressed: () => _saveLog(
                  _isEditing
                      ? widget.existingBlock!.status
                      : widget.defaultStatus,
                ),
                child: Text(
                  _isEditing
                      ? 'UPDATE LOG'
                      : (widget.defaultStatus == BlockStatus.planned
                            ? 'SAVE PLAN'
                            : 'SAVE LOG'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
