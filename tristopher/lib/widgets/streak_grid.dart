import 'package:flutter/material.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:intl/intl.dart';

class StreakGrid extends StatelessWidget {
  final int currentStreak;
  final List<bool> completionHistory;
  final bool is66DayChallenge;
  final DateTime? startDate;

  const StreakGrid({
    super.key,
    required this.currentStreak,
    required this.completionHistory,
    this.is66DayChallenge = false,
    this.startDate,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = is66DayChallenge ? 66 : getDaysInMonth(today.year, today.month);
    
    return Column(
      children: [
        Text(
          'Current Streak: $currentStreak ${currentStreak == 1 ? 'day' : 'days'}',
          style: AppTextStyles.header(size: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        Text(
          is66DayChallenge 
              ? '66-Day Challenge Progress' 
              : DateFormat('MMMM yyyy').format(today),
          style: AppTextStyles.userText(weight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: days,
          itemBuilder: (context, index) {
            final dayNumber = index + 1;
            final bool isToday = today.day == dayNumber && !is66DayChallenge;
            final bool isFutureDay = is66DayChallenge 
                ? index >= completionHistory.length
                : dayNumber > today.day;
            
            // Determine if day was completed
            bool isDayCompleted = false;
            if (!isFutureDay && index < completionHistory.length) {
              isDayCompleted = completionHistory[index];
            }
            
            return _buildDayCircle(
              dayNumber: dayNumber,
              isToday: isToday,
              isFutureDay: isFutureDay,
              isCompleted: isDayCompleted,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayCircle({
    required int dayNumber,
    required bool isToday,
    required bool isFutureDay,
    required bool isCompleted,
  }) {
    final Color circleColor = isCompleted 
        ? AppColors.accentColor 
        : Colors.transparent;
    
    final Color borderColor = isToday
        ? AppColors.accentColor
        : Colors.black.withOpacity(0.3);
    
    final double borderWidth = isToday ? 2.0 : 1.0;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Center(
        child: Text(
          dayNumber.toString(),
          style: AppTextStyles.userText(
            size: 14,
            weight: isToday ? FontWeight.bold : FontWeight.normal,
          ).copyWith(
            color: isCompleted ? Colors.white : Colors.black.withOpacity(isFutureDay ? 0.3 : 0.7),
          ),
        ),
      ),
    );
  }

  int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
