import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    final dateLabel = isToday
        ? 'TODAY'
        : DateFormat('EEE, MMM d, yyyy').format(selectedDate).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white70),
            onPressed: () =>
                onDateChanged(selectedDate.subtract(const Duration(days: 1))),
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Colors.deepPurpleAccent,
                        onPrimary: Colors.white,
                        surface: Color(0xFF252530),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) onDateChanged(picked);
            },
            child: Text(
              dateLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isToday ? Colors.deepPurpleAccent : Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white70),
            onPressed: () =>
                onDateChanged(selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }
}
