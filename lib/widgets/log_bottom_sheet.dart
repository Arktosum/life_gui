import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'package:life_gui/widgets/emotional_picker.dart';

class LogBottomSheet extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;

  const LogBottomSheet({
    super.key,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<LogBottomSheet> createState() => _LogBottomSheetState();
}

class _LogBottomSheetState extends State<LogBottomSheet> {
  List<double> _currentIntensities = List.filled(8, 0.0);
  String _selectedCategory = 'Deep Work'; // Default
  final TextEditingController _remarksController = TextEditingController();

  final List<String> _categories = [
    'Deep Work',
    'Mechatronics',
    'Flutter Dev',
    'Maintenance',
    'Leisure',
    'Social',
    'Sleep',
  ];

  // The Magic Vector Engine: Blends the RGB values based on petal intensity
  Color _calculateDynamicColor() {
    double totalIntensity = _currentIntensities.fold(0, (a, b) => a + b);

    // If no emotion is selected, default to the brand purple
    if (totalIntensity == 0) return Colors.deepPurpleAccent;

    double r = 0, g = 0, b = 0;
    for (int i = 0; i < 8; i++) {
      Color c = plutchikEmotions[i]['color'];
      double weight = _currentIntensities[i];
      r += c.red * weight;
      g += c.green * weight;
      b += c.blue * weight;
    }

    return Color.fromRGBO(
      (r / totalIntensity).round().clamp(0, 255),
      (g / totalIntensity).round().clamp(0, 255),
      (b / totalIntensity).round().clamp(0, 255),
      1.0,
    );
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color dynamicGlow = _calculateDynamicColor();
    DateTime start = widget.startTime.isBefore(widget.endTime)
        ? widget.startTime
        : widget.endTime;
    DateTime end = widget.startTime.isAfter(widget.endTime)
        ? widget.startTime
        : widget.endTime;
    end = end.add(const Duration(hours: 1));

    return Container(
      // Let it take up to 90% of the screen if needed
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // THE KEYBOARD FIX: Make it scrollable and add dynamic bottom padding!
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              20, // Pushes UI up above keyboard
          left: 20,
          right: 20,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content tightly
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${end.difference(start).inHours}H LOG',
              style: TextStyle(
                color: dynamicGlow,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 280,
              width: 280,
              child: EmotionPicker(
                onChanged: (intensities) =>
                    setState(() => _currentIntensities = intensities),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  bool isSelected = _categories[index] == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(_categories[index]),
                      selected: isSelected,
                      selectedColor: dynamicGlow.withOpacity(0.2),
                      backgroundColor: const Color(0xFF1E1E1E),
                      side: BorderSide(
                        color: isSelected ? dynamicGlow : Colors.transparent,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? dynamicGlow : Colors.white54,
                      ),
                      onSelected: (selected) {
                        if (selected)
                          setState(
                            () => _selectedCategory = _categories[index],
                          );
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _remarksController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What happened?',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: dynamicGlow),
                ),
              ),
            ),

            const SizedBox(height: 24), // Replaced Spacer() with a fixed height

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: dynamicGlow,
                  foregroundColor: totalIntensity == 0
                      ? Colors.white
                      : Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'SAVE LOG',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Helper for the text color contrast
  double get totalIntensity => _currentIntensities.fold(0, (a, b) => a + b);
}
