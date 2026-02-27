import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String currentMonth = DateFormat('EEEE, MMMM d, yyyy').format(now);

    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    // 1. Find out what day of the week the 1st of the month falls on
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);

    // DateTime.weekday returns 1 for Monday, 7 for Sunday.
    // Since our calendar starts on Monday, the number of empty boxes we need is (weekday - 1).
    int emptyBoxesOffset = firstDayOfMonth.weekday - 1;

    // 2. The standard Weekday headers
    final List<String> weekDays = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LIFE GUI',
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentMonth.toUpperCase(),
              style: const TextStyle(
                color: Colors.deepPurpleAccent,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 24),

            // --- NEW: The Weekday Header Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays.map((day) {
                return SizedBox(
                  width: 40, // Match the rough width of the grid items
                  child: Center(
                    child: Text(
                      day,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // --- UPDATED: The Calendar Grid ---
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // 7 days in a week
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                // We add the empty boxes to the total item count
                itemCount: daysInMonth + emptyBoxesOffset,
                itemBuilder: (context, index) {
                  // If the index is before our 1st of the month, render an empty space
                  if (index < emptyBoxesOffset) {
                    return const SizedBox.shrink();
                  }

                  // Calculate the actual date number
                  int day = index - emptyBoxesOffset + 1;
                  DateTime cellDate = DateTime(now.year, now.month, day);
                  bool isToday = day == now.day;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(pivotDate: cellDate),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.deepPurpleAccent.withOpacity(0.2)
                            : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isToday
                              ? Colors.deepPurpleAccent
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        day.toString(),
                        style: GoogleFonts.inter(
                          color: isToday
                              ? Colors.deepPurpleAccent
                              : Colors.white70,
                          fontSize: 16,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
