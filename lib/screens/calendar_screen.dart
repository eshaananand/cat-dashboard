import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cat_data.dart';
import '../dialogs/import_backup_dialog.dart';
import '../dialogs/study_log_dialog.dart';
import '../prep_store.dart';
import '../utils/color_utils.dart';
import '../utils/date_utils.dart';
import '../widgets/common_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({required this.store, super.key});

  final PrepStore store;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final today = todayOnly();
    _visibleMonth = DateTime(today.year, today.month);
  }

  @override
  Widget build(BuildContext context) {
    final today = todayOnly();
    final daysLeft = math.max(targetExamDate.difference(today).inDays, 0);
    final missedDays = missedStudyDays(widget.store, today).length;
    final mocksLeft = widget.store.allMockSlots
        .where((mock) => !mock.date.isBefore(today))
        .where((mock) => widget.store.resultFor(mock.id) == null)
        .length;
    final studiedDays = widget.store.studyDayKeys.length;
    final completedMocks = widget.store.completedMockCount;

    return AppPage(
      title: 'Calendar',
      subtitle:
          'Tap any date to mark study done and write what you studied. Past empty dates show as missed.',
      child: Column(
        children: [
          ResponsiveMetricGrid(
            children: [
              MetricTile(
                icon: Icons.event_available_outlined,
                title: 'Days left',
                value: '$daysLeft',
                caption: '$examDateLabel target',
                color: Theme.of(context).colorScheme.primary,
              ),
              MetricTile(
                icon: Icons.check_circle_outline,
                title: 'Study days',
                value: '$studiedDays',
                caption: 'days marked as studied',
                color: const Color(0xFFF2B84B),
              ),
              MetricTile(
                icon: Icons.event_busy_outlined,
                title: 'Missed days',
                value: '$missedDays',
                caption: 'from ${shortDate(prepStartDate)} to yesterday',
                color: const Color(0xFFE05D44),
              ),
              MetricTile(
                icon: Icons.assignment_outlined,
                title: 'Mocks left',
                value: '$mocksLeft',
                caption: '$completedMocks completed',
                color: const Color(0xFF4E6EAF),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final calendar = _MonthCalendar(
                month: _visibleMonth,
                store: widget.store,
                onPrevious: () => setState(() {
                  _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month - 1,
                  );
                }),
                onNext: () => setState(() {
                  _visibleMonth = DateTime(
                    _visibleMonth.year,
                    _visibleMonth.month + 1,
                  );
                }),
              );
              final backup = _BackupPanel(store: widget.store);
              if (!wide) {
                return Column(
                  children: [calendar, const SizedBox(height: 16), backup],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: calendar),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: backup),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.store,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final PrepStore store;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cells = monthCells(month);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Panel(
      title: '${monthName(month.month)} ${month.year}',
      icon: Icons.calendar_month_outlined,
      trailing: Wrap(
        spacing: 4,
        children: [
          Tooltip(
            message: 'Previous month',
            child: IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrevious,
            ),
          ),
          Tooltip(
            message: 'Next month',
            child: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.92,
            ),
            itemCount: cells.length,
            itemBuilder: (context, index) {
              final date = cells[index];
              if (date == null) {
                return const SizedBox.shrink();
              }
              return _CalendarDayCell(
                date: date,
                store: store,
                onTap: () => editStudyLog(context, store, date),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: const [
              _LegendDot(color: Color(0xFF00796B), label: 'Studied'),
              _LegendDot(color: Color(0xFFE05D44), label: 'Missed'),
              _LegendDot(color: Color(0xFF4E6EAF), label: 'Mock'),
              _LegendDot(color: Color(0xFFF2B84B), label: 'Today'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.store,
    required this.onTap,
  });

  final DateTime date;
  final PrepStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final today = todayOnly();
    final studied = store.isStudyDay(date);
    final hasLog = store.studyLogFor(date).isNotEmpty;
    final isToday = dateKey(date) == dateKey(today);
    final isPastMissed =
        date.isBefore(today) && !date.isBefore(prepStartDate) && !studied;
    final dayMocks = store.allMockSlots
        .where((mock) => dateKey(mock.date) == dateKey(date))
        .toList();
    final hasMock = dayMocks.isNotEmpty;
    final color = studied
        ? Theme.of(context).colorScheme.primary
        : isPastMissed
        ? Theme.of(context).colorScheme.secondary
        : hasMock
        ? const Color(0xFF4E6EAF)
        : mutedTextColor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: studied
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : isPastMissed
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
              : softSurfaceColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? Theme.of(context).colorScheme.tertiary
                : color.withValues(alpha: 0.28),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                if (hasLog)
                  Icon(Icons.edit_note, size: 17, color: color)
                else if (studied)
                  Icon(Icons.check_circle, size: 16, color: color),
              ],
            ),
            const Spacer(),
            if (hasMock)
              Text(
                dayMocks.length == 1
                    ? dayMocks.first.kind
                    : '${dayMocks.length} mocks',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF4E6EAF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            if (isPastMissed)
              Text(
                'Missed',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _BackupPanel extends StatelessWidget {
  const _BackupPanel({required this.store});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Backup',
      icon: Icons.cloud_upload_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your tracker data is saved locally in this browser/device. GitHub saves the app code, not this personal progress.',
            style: TextStyle(color: mutedTextColor(context), letterSpacing: 0),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Copy Backup JSON'),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: store.exportBackupJson()),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup copied to clipboard')),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Import Backup JSON'),
            onPressed: () => importBackup(context, store),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            'Use this before clearing browser data, changing devices, or publishing to a new domain.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
