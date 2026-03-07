import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../models/category.dart';
import '../../models/time_block.dart';
import '../../models/mood_preset.dart';
import '../../database/database_helper.dart';
import 'plutchik_studio_sheet.dart';
import '../../services/notification_service.dart';



class QuickLogSheet extends StatefulWidget {
  final DateTime initialStartTime;
  final DateTime initialEndTime;
  final List<ActivityCategory> categories;
  final List<MoodPreset> moods;
  final TimeBlock? existingBlock;
  final BlockStatus defaultStatus;

  const QuickLogSheet({
    super.key,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.categories,
    required this.moods,
    this.existingBlock,
    this.defaultStatus = BlockStatus.completed,
  });

  @override
  State<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<QuickLogSheet> {
  late DateTime _startTime;
  late DateTime _endTime;

  // Unified Local State so newly created chips appear instantly
  late List<ActivityCategory> _localCategories;
  late List<MoodPreset> _localMoods;

  // Category State
  final TextEditingController _categorySearchController =
      TextEditingController();
  ActivityCategory? _selectedCategory;

  // Mood State
  final TextEditingController _moodSearchController = TextEditingController();
  MoodPreset? _selectedMood;

  final TextEditingController _remarksController = TextEditingController();

  bool get _isEditing => widget.existingBlock != null;
  bool get _isVerifying =>
      _isEditing && widget.existingBlock!.status == BlockStatus.planned;

  @override
  void initState() {
    super.initState();
    _localCategories = List.from(widget.categories);
    _localMoods = List.from(widget.moods);

    if (_isEditing) {
      _startTime = widget.existingBlock!.startTime;
      _endTime = widget.existingBlock!.endTime;
      _remarksController.text = widget.existingBlock!.remarks;

      _selectedCategory = _localCategories.firstWhere(
        (c) => c.id == widget.existingBlock!.categoryId,
        orElse: () => _localCategories.isNotEmpty
            ? _localCategories.first
            : const ActivityCategory(name: 'Unknown', colorVal: 0xFF9E9E9E),
      );

      if (widget.existingBlock!.intensities.isNotEmpty) {
        try {
          final savedMoodMap = jsonDecode(widget.existingBlock!.intensities);
          _selectedMood = MoodPreset.fromMap(savedMoodMap);
          // If the mood was deleted from the DB but still exists on this block, temporarily add it to the grid to view it
          if (!_localMoods.any((m) => m.name == _selectedMood!.name)) {
            _localMoods.add(_selectedMood!);
          }
        } catch (e) {
          debugPrint('Error parsing mood: $e');
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
    _categorySearchController.dispose();
    _moodSearchController.dispose();
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
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Category!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final matchedCategory = await DatabaseHelper.instance.getOrCreateCategory(
      _selectedCategory!.name,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.deleteTimeBlock(widget.existingBlock!.id!);
    }
    await DatabaseHelper.instance.deleteOverlappingBlocks(_startTime, _endTime);

    String intensitiesJson = '';
    if (_selectedMood != null) {
      intensitiesJson = jsonEncode(_selectedMood!.toMap());
    } else if (_isEditing && widget.existingBlock!.intensities.isNotEmpty) {
      intensitiesJson = widget.existingBlock!.intensities;
    }

    final newBlock = TimeBlock(
      startTime: _startTime,
      endTime: _endTime,
      categoryId: matchedCategory.id ?? 0,
      remarks: _remarksController.text.trim(),
      status: targetStatus,
      intensities: intensitiesJson,
    );

    await DatabaseHelper.instance.insertTimeBlock(newBlock);

    // THE MAGIC: Reset the Time Bomb!
    await NotificationService.instance.scheduleDailyReminder();
    
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteLog() async {
    if (_isEditing) {
      await DatabaseHelper.instance.deleteTimeBlock(widget.existingBlock!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _openStudio({
    String? initialName,
    MoodPreset? existingMood,
  }) async {
    FocusScope.of(context).unfocus();

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PlutchikStudioSheet(
        initialName: initialName,
        existingPreset: existingMood,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result == 'DELETED') {
          // They trashed it. Remove it from the local UI grid.
          _localMoods.removeWhere((m) => m.id == existingMood?.id);
          if (_selectedMood?.id == existingMood?.id) _selectedMood = null;
        } else if (result is MoodPreset) {
          // They saved or updated it!
          _selectedMood = result;

          final index = _localMoods.indexWhere((m) => m.id == result.id);
          if (index >= 0) {
            _localMoods[index] = result; // Update existing
          } else {
            _localMoods.insert(0, result); // Add new
            _moodSearchController.clear();
          }
        }
      });
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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

            // --- CATEGORY CHIP GRID ---
            TextField(
              controller: _categorySearchController,
              onChanged: (value) => setState(() {}),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurpleAccent,
              ),
              decoration: InputDecoration(
                labelText: widget.defaultStatus == BlockStatus.planned
                    ? 'Plan Category'
                    : 'Category',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(
                  Icons.category,
                  color: Colors.deepPurpleAccent,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _categorySearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () {
                          _categorySearchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            Builder(
              builder: (context) {
                final query = _categorySearchController.text
                    .trim()
                    .toLowerCase();
                final matches = _localCategories
                    .where((c) => c.name.toLowerCase().contains(query))
                    .toList();
                final exactMatch = matches.any(
                  (c) => c.name.toLowerCase() == query,
                );

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        if (query.isNotEmpty && !exactMatch)
                          ActionChip(
                            backgroundColor: Colors.deepPurpleAccent
                                .withOpacity(0.1),
                            side: const BorderSide(
                              color: Colors.deepPurpleAccent,
                              width: 1.5,
                            ),
                            avatar: const Icon(
                              Icons.add_circle,
                              color: Colors.deepPurpleAccent,
                              size: 18,
                            ),
                            label: Text(
                              'Create "$query"',
                              style: const TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              final newCat = ActivityCategory(
                                id: -1,
                                name: _categorySearchController.text.trim(),
                                colorVal: 0xFF9E9E9E,
                              );
                              setState(() {
                                _localCategories.insert(0, newCat);
                                _selectedCategory = newCat;
                                _categorySearchController.clear();
                                FocusScope.of(context).unfocus();
                              });
                            },
                          ),
                        ...matches.map((cat) {
                          final isSelected =
                              _selectedCategory?.name == cat.name;
                          return ChoiceChip(
                            label: Text(
                              cat.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Color(cat.colorVal),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Color(cat.colorVal),
                            backgroundColor: const Color(0xFF252530),
                            side: BorderSide(
                              color: Color(cat.colorVal).withOpacity(0.3),
                              width: 1,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? cat : null;
                                // NEW: Auto-fill the search bar!
                                if (selected) {
                                  _categorySearchController.text = cat.name;
                                } else {
                                  _categorySearchController.clear();
                                }
                                FocusScope.of(context).unfocus();
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // --- MOOD CHIP GRID ---
            TextField(
              controller: _moodSearchController,
              onChanged: (value) => setState(() {}),
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
                suffixIcon: _moodSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () {
                          _moodSearchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            Builder(
              builder: (context) {
                final query = _moodSearchController.text.trim().toLowerCase();
                final matches = _localMoods
                    .where((m) => m.name.toLowerCase().contains(query))
                    .toList();
                final exactMatch = matches.any(
                  (m) => m.name.toLowerCase() == query,
                );

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        if (query.isNotEmpty && !exactMatch)
                          ActionChip(
                            backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                            side: const BorderSide(
                              color: Colors.cyanAccent,
                              width: 1.5,
                            ),
                            avatar: const Icon(
                              Icons.add_circle,
                              color: Colors.cyanAccent,
                              size: 18,
                            ),
                            label: Text(
                              'Create "$query"',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => _openStudio(),
                          ),
                        ...matches.map((mood) {
                          final isSelected = _selectedMood?.name == mood.name;
                          // NEW: Wrap ChoiceChip in GestureDetector to catch Long Presses!
                          return GestureDetector(
                            onLongPress: () => _openStudio(existingMood: mood),
                            child: ChoiceChip(
                              label: Text(
                                '${mood.emoji} ${mood.name}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Colors.cyanAccent,
                              backgroundColor: const Color(0xFF252530),
                              side: BorderSide.none,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedMood = selected ? mood : null;
                                  // NEW: Auto-fill the search bar!
                                  if (selected) {
                                    _moodSearchController.text = mood.name;
                                  } else {
                                    _moodSearchController.clear();
                                  }
                                  FocusScope.of(context).unfocus();
                                });
                              },
                            ),
                          );
                        }),
                      ],
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
      ),
    );
  }
}
