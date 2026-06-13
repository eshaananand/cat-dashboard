import '../cat_data.dart';
import '../prep_store.dart';

MockSlot? nextUpcomingMock(PrepStore store, DateTime today) {
  for (final mock in store.allMockSlots) {
    if (!mock.date.isBefore(today)) {
      return mock;
    }
  }
  return null;
}

PlanPhase phaseFor(DateTime date) {
  for (final phase in planPhases) {
    if (!date.isBefore(phase.start) && !date.isAfter(phase.end)) {
      return phase;
    }
  }
  if (date.isBefore(planPhases.first.start)) {
    return planPhases.first;
  }
  return planPhases.last;
}

DateTime todayOnly() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

List<DateTime> weekDates(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  return List.generate(7, (index) => monday.add(Duration(days: index)));
}

List<DateTime?> monthCells(DateTime month) {
  final first = DateTime(month.year, month.month);
  final leadingBlanks = first.weekday - 1;
  final dayCount = DateTime(month.year, month.month + 1, 0).day;
  final cellCount = ((leadingBlanks + dayCount + 6) ~/ 7) * 7;
  return List.generate(cellCount, (index) {
    final dayNumber = index - leadingBlanks + 1;
    if (dayNumber < 1 || dayNumber > dayCount) {
      return null;
    }
    return DateTime(month.year, month.month, dayNumber);
  });
}

List<DateTime> missedStudyDays(PrepStore store, DateTime today) {
  final end = today.subtract(const Duration(days: 1));
  if (end.isBefore(prepStartDate)) {
    return [];
  }
  final count = end.difference(prepStartDate).inDays + 1;
  return List.generate(count, (index) {
    return DateTime(
      prepStartDate.year,
      prepStartDate.month,
      prepStartDate.day + index,
    );
  }).where((date) => !store.isStudyDay(date)).toList();
}

String monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month - 1];
}

String longDate(DateTime date) {
  return '${date.day} ${monthName(date.month)} ${date.year}';
}
