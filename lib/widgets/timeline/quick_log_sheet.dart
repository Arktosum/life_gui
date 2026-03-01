import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../models/time_block.dart';
import '../../database/database_helper.dart';

class QuickLogSheet extends StatefulWidget {
  final DateTime initialStartTime;
  final DateTime initialEndTime;
  final List<ActivityCategory> categories;
  final TimeBlock? existingBlock; // NEW: If this is passed, we are in Edit Mode!

  const QuickLogSheet({
    super.key,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.categories,
    this.existingBlock,
  });

  @override
  State<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends State<QuickLogSheet> {
  late DateTime _startTime;
  late DateTime _endTime;
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final FocusNode _categoryFocus = FocusNode(); 
  
  bool get _isEditing => widget.existingBlock != null;

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      // EDIT MODE: Pre-fill everything from the existing block
      _startTime = widget.existingBlock!.startTime;
      _endTime = widget.existingBlock!.endTime;
      _remarksController.text = widget.existingBlock!.remarks;
      
      // Find the category name to pre-fill the text field
      final matchedCat = widget.categories.firstWhere(
        (c) => c.id == widget.existingBlock!.categoryId,
        orElse: () => const ActivityCategory(name: '', colorVal: 0),
      );
      _categoryController.text = matchedCat.name;
    } else {
      // CREATE MODE: Use the gap times
      _startTime = widget.initialStartTime;
      final now = DateTime.now();
      _endTime = widget.initialEndTime.isAfter(now) ? now : widget.initialEndTime;
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _remarksController.dispose();
    _categoryFocus.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final initialTime = TimeOfDay.fromDateTime(isStart ? _startTime : _endTime);
    final pickedTime = await showTimePicker(context: context, initialTime: initialTime);
    
    if (pickedTime != null) {
      setState(() {
        final targetDate = isStart ? _startTime : _endTime;
        final newDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, pickedTime.hour, pickedTime.minute);
        
        if (isStart) {
          _startTime = newDateTime;
          if (_startTime.isAfter(_endTime)) _endTime = _startTime.add(const Duration(hours: 1));
        } else {
          _endTime = newDateTime;
          if (_endTime.isBefore(_startTime)) _startTime = _endTime.subtract(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _saveLog() async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isEmpty) return;

    final matchedCategory = await DatabaseHelper.instance.getOrCreateCategory(categoryName);

    // If editing, delete the old version of this block first so we don't trip over ourselves
    if (_isEditing) {
      await DatabaseHelper.instance.deleteTimeBlock(widget.existingBlock!.id!);
    }

    // Nuke any overlaps to enforce Zero-Based chronological integrity
    await DatabaseHelper.instance.deleteOverlappingBlocks(_startTime, _endTime);

    // Insert the fresh block
    final newBlock = TimeBlock(
      startTime: _startTime,
      endTime: _endTime,
      categoryId: matchedCategory.id ?? 0, 
      remarks: _remarksController.text.trim(),
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
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Time Range and (Optional) Delete Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => _pickTime(context, true),
                    child: Text(timeFormat.format(_startTime), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
                  ),
                  const Text('  →  ', style: TextStyle(fontSize: 18, color: Colors.white54)),
                  InkWell(
                    onTap: () => _pickTime(context, false),
                    child: Text(timeFormat.format(_endTime), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
                  ),
                ],
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: _deleteLog,
                  tooltip: 'Delete Block',
                )
              else
                Text(
                  '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                  style: const TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 20),

          RawAutocomplete<ActivityCategory>(
            textEditingController: _categoryController,
            focusNode: _categoryFocus,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return widget.categories;
              return widget.categories.where((option) => 
                option.name.toLowerCase().contains(textEditingValue.text.toLowerCase())
              );
            },
            displayStringForOption: (option) => option.name,
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: !_isEditing, // Only auto-keyboard if it's a brand new block
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Category (Type to search or create)',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          leading: CircleAvatar(radius: 8, backgroundColor: Color(option.colorVal)),
                          title: Text(option.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
              onPressed: _saveLog,
              child: Text(_isEditing ? 'UPDATE BLOCK' : 'SAVE BLOCK', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}