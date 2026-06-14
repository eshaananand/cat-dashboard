import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../cat_data.dart';
import '../dialogs/study_log_dialog.dart';
import '../prep_store.dart';
import '../utils/color_utils.dart';
import '../utils/date_utils.dart';
import '../widgets/common_widgets.dart';

const String _dashboardReminderNoteId = 'dashboard:reminder';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.store, super.key});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final today = todayOnly();
    final daysLeft = math.max(targetExamDate.difference(today).inDays, 0);
    final nextMock = nextUpcomingMock(store, today);
    final currentPhase = phaseFor(today);
    final averageScore = store.averageMockScore;
    final averagePercentile = store.averageMockPercentile;
    final bestPercentile = store.bestPercentile;
    final quote =
        motivationLines[today.difference(prepStartDate).inDays.abs() %
            motivationLines.length];

    return AppPage(
      title: 'CAT 2026 Dashboard',
      subtitle:
          'Personal command center for syllabus, mocks, hours, and calm consistency.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CountdownHero(
            daysLeft: daysLeft,
            quote: quote,
            currentPhase: currentPhase,
          ),
          const SizedBox(height: 16),
          ResponsiveMetricGrid(
            children: [
              for (final section in CatSection.values)
                _SectionMetricTile(section: section, store: store),
              MetricTile(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Mocks done',
                value: '${store.completedMockCount}',
                caption: nextMock == null
                    ? 'target complete'
                    : 'next: ${shortDate(nextMock.date)}',
                color: const Color(0xFF4E6EAF),
              ),
              MetricTile(
                icon: Icons.functions,
                title: 'Avg marks',
                value: averageScore == null
                    ? '-'
                    : averageScore.toStringAsFixed(1),
                caption: 'saved mock average score',
                color: const Color(0xFFE05D44),
              ),
              MetricTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Avg percentile',
                value: averagePercentile == null
                    ? '-'
                    : averagePercentile.toStringAsFixed(2),
                caption: bestPercentile == null
                    ? 'add mock scores to start'
                    : 'best: ${bestPercentile.toStringAsFixed(2)}',
                color: const Color(0xFFF2B84B),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 840;
              final notes = _StudyNotesPanel(store: store, today: today);
              final progress = _SectionProgressPanel(store: store);
              if (!wide) {
                return Column(
                  children: [notes, const SizedBox(height: 16), progress],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: notes),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: progress),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _WeeklyStudyPanel(store: store),
          const SizedBox(height: 16),
          _UpcomingMocksPanel(store: store),
        ],
      ),
    );
  }
}

class _CountdownHero extends StatelessWidget {
  const _CountdownHero({
    required this.daysLeft,
    required this.quote,
    required this.currentPhase,
  });

  final int daysLeft;
  final String quote;
  final PlanPhase currentPhase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF14332F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final days = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$daysLeft',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontSize: wide ? 56 : 46,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'days to target',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                avatar: const Icon(Icons.event, size: 16),
                label: Text('$examDateLabel - $examDateStatus'),
                backgroundColor: Colors.white,
                side: BorderSide.none,
              ),
            ],
          );

          final phase = Column(
            crossAxisAlignment: wide
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                currentPhase.title,
                textAlign: wide ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentPhase.focus,
                textAlign: wide ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 15,
                  height: 1.4,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.tertiary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quote,
                  style: const TextStyle(
                    color: Color(0xFF2F2410),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [days, const SizedBox(height: 20), phase],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: days),
              const SizedBox(width: 24),
              Expanded(child: phase),
            ],
          );
        },
      ),
    );
  }
}

class _SectionMetricTile extends StatelessWidget {
  const _SectionMetricTile({required this.section, required this.store});

  final CatSection section;
  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final topics = catTopics
        .where((topic) => topic.section == section)
        .toList();
    final progress = store.completionFor(topics);
    final completed = store.completedSubtopicCountFor(topics);
    final total = store.totalSubtopicCountFor(topics);
    final covered = (progress * 100).round();
    final left = math.max(100 - covered, 0);

    return MetricTile(
      icon: sectionIcon(section),
      title: '${section.shortName} covered',
      value: '$covered%',
      caption: '$left% left - $completed/$total subtopics',
      color: sectionColor(section),
    );
  }
}

class _StudyNotesPanel extends StatefulWidget {
  const _StudyNotesPanel({required this.store, required this.today});

  final PrepStore store;
  final DateTime today;

  @override
  State<_StudyNotesPanel> createState() => _StudyNotesPanelState();
}

class _StudyNotesPanelState extends State<_StudyNotesPanel> {
  late final TextEditingController _todayController;
  late final TextEditingController _reminderController;

  @override
  void initState() {
    super.initState();
    _todayController = TextEditingController(
      text: widget.store.studyLogFor(widget.today),
    );
    _reminderController = TextEditingController(
      text: widget.store.noteFor(_dashboardReminderNoteId),
    );
  }

  @override
  void dispose() {
    _todayController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasTodayLog = widget.store.studyLogFor(widget.today).isNotEmpty;
    final isStudied = widget.store.isStudyDay(widget.today);

    return Panel(
      title: 'Study Notes',
      icon: Icons.edit_note,
      trailing: StatusChip(
        label: hasTodayLog || isStudied ? 'Today saved' : 'Free text',
        color: hasTodayLog || isStudied
            ? const Color(0xFF00796B)
            : Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;
              final todayField = _DashboardTextField(
                controller: _todayController,
                label: 'What I studied today',
                hint: 'Example: 2 RC passages, 1 DILR set, percentages drill.',
                icon: Icons.today_outlined,
              );
              final reminderField = _DashboardTextField(
                controller: _reminderController,
                label: 'Reminder / tomorrow plan',
                hint: 'Example: revise ratios, solve one caselet, review mock.',
                icon: Icons.notifications_active_outlined,
              );

              if (!wide) {
                return Column(
                  children: [
                    todayField,
                    const SizedBox(height: 12),
                    reminderField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: todayField),
                  const SizedBox(width: 12),
                  Expanded(child: reminderField),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _saveNotes,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save notes'),
              ),
              TextButton.icon(
                onPressed: _clearTodayLog,
                icon: const Icon(Icons.cleaning_services_outlined),
                label: const Text('Clear today'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveNotes() {
    final todayText = _todayController.text.trim();
    widget.store.saveStudyLog(
      widget.today,
      todayText.isNotEmpty,
      _todayController.text,
    );
    widget.store.saveNote(_dashboardReminderNoteId, _reminderController.text);
    _showSavedMessage();
  }

  void _clearTodayLog() {
    _todayController.clear();
    widget.store.saveStudyLog(widget.today, false, '');
    _showSavedMessage();
  }

  void _showSavedMessage() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notes saved')));
  }
}

class _DashboardTextField extends StatelessWidget {
  const _DashboardTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 4,
      maxLines: 7,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _WeeklyStudyPanel extends StatelessWidget {
  const _WeeklyStudyPanel({required this.store});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final today = todayOnly();
    final week = weekDates(today);
    final weekStart = week.first;
    final weekEnd = week.last;
    final studiedCount = week.where(store.isStudyDay).length;
    final weekMocks = store.allMockSlots.where((mock) {
      return !mock.date.isBefore(weekStart) && !mock.date.isAfter(weekEnd);
    }).toList();
    final completedMocks = weekMocks
        .where((mock) => store.resultFor(mock.id) != null)
        .length
        .clamp(0, 2);
    final targetProgress = completedMocks / 2;

    return Panel(
      title: 'This Week',
      icon: Icons.calendar_view_week_outlined,
      trailing: StatusChip(
        label: 'Mon-Sun',
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final dayTiles = [
                for (final day in week)
                  _WeekDayTile(
                    date: day,
                    selected: store.isStudyDay(day),
                    hasLog: store.studyLogFor(day).isNotEmpty,
                    isToday: dateKey(day) == dateKey(today),
                    compact: compact,
                    onTap: () => editStudyLog(context, store, day),
                  ),
              ];

              if (compact) {
                return Wrap(spacing: 8, runSpacing: 8, children: dayTiles);
              }
              return Row(
                children: [for (final tile in dayTiles) Expanded(child: tile)],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 700;
              final studySummary = _WeeklySummaryBlock(
                icon: Icons.local_fire_department_outlined,
                title: '$studiedCount/7 study days',
                detail: studiedCount == 0
                    ? 'Mark today after your prep block.'
                    : 'Every checked day is saved here.',
                color: const Color(0xFFF2B84B),
              );
              final mockSummary = _WeeklySummaryBlock(
                icon: Icons.assignment_turned_in_outlined,
                title: '$completedMocks/2 mocks this week',
                detail: weekMocks.isEmpty
                    ? 'Use sectionals/PYQs if no full mock is scheduled.'
                    : weekMocks.map((mock) => mock.title).join(', '),
                color: const Color(0xFF4E6EAF),
                progress: targetProgress,
              );
              if (compact) {
                return Column(
                  children: [
                    studySummary,
                    const SizedBox(height: 12),
                    mockSummary,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: studySummary),
                  const SizedBox(width: 12),
                  Expanded(child: mockSummary),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekDayTile extends StatelessWidget {
  const _WeekDayTile({
    required this.date,
    required this.selected,
    required this.hasLog,
    required this.isToday,
    required this.compact,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool hasLog;
  final bool isToday;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: compact ? 72 : null,
        margin: compact ? EdgeInsets.zero : const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : softSurfaceColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? Theme.of(context).colorScheme.tertiary
                : color.withValues(alpha: 0.35),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? hasLog
                        ? Icons.edit_note
                        : Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              labels[date.weekday - 1],
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date.day.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedTextColor(context),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklySummaryBlock extends StatelessWidget {
  const _WeeklySummaryBlock({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    this.progress,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softSurfaceColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: mutedTextColor(context), letterSpacing: 0),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionProgressPanel extends StatelessWidget {
  const _SectionProgressPanel({required this.store});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Section Progress',
      icon: Icons.stacked_bar_chart,
      child: Column(
        children: [
          for (final section in CatSection.values) ...[
            _SectionProgressRow(section: section, store: store),
            if (section != CatSection.values.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _SectionProgressRow extends StatelessWidget {
  const _SectionProgressRow({required this.section, required this.store});

  final CatSection section;
  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final topics = catTopics
        .where((topic) => topic.section == section)
        .toList();
    final progress = store.completionFor(topics);
    final completed = store.completedSubtopicCountFor(topics);
    final total = store.totalSubtopicCountFor(topics);
    final covered = (progress * 100).round();
    final left = math.max(100 - covered, 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(sectionIcon(section), size: 18, color: sectionColor(section)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                section.shortName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '$covered% covered',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$left% left - $completed/$total subtopics complete',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: mutedTextColor(context),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress,
            backgroundColor: sectionColor(section).withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(sectionColor(section)),
          ),
        ),
      ],
    );
  }
}

class _UpcomingMocksPanel extends StatelessWidget {
  const _UpcomingMocksPanel({required this.store});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final today = todayOnly();
    final upcoming = store.allMockSlots
        .where(
          (mock) =>
              !mock.date.isBefore(today) || store.resultFor(mock.id) == null,
        )
        .take(4)
        .toList();

    return Panel(
      title: 'Upcoming Mocks',
      icon: Icons.assessment_outlined,
      child: Column(
        children: [
          for (final mock in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CompactMockRow(mock: mock, store: store),
            ),
          if (upcoming.isEmpty)
            const EmptyState(
              icon: Icons.flag_circle_outlined,
              title: 'Mock schedule complete',
              message: 'Use the saved scores for final review.',
            ),
        ],
      ),
    );
  }
}

class _CompactMockRow extends StatelessWidget {
  const _CompactMockRow({required this.mock, required this.store});

  final MockSlot mock;
  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final result = store.resultFor(mock.id);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DateBadge(date: mock.date),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mock.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result == null
                    ? mock.focus
                    : 'Score ${result.total}, percentile ${result.percentile.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
