import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../cat_data.dart';
import '../dialogs/study_log_dialog.dart';
import '../prep_store.dart';
import '../utils/color_utils.dart';
import '../utils/date_utils.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.store, super.key});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final today = todayOnly();
    final daysLeft = math.max(targetExamDate.difference(today).inDays, 0);
    final completedTasks = dailyTasks
        .where((task) => store.isTaskComplete(task.id))
        .length;
    final overallProgress = store.completionFor(catTopics);
    final nextMock = nextUpcomingMock(store, today);
    final currentPhase = phaseFor(today);
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
          _DailyBoostPanel(today: today),
          const SizedBox(height: 16),
          ResponsiveMetricGrid(
            children: [
              MetricTile(
                icon: Icons.track_changes,
                title: 'Syllabus done',
                value: '${(overallProgress * 100).round()}%',
                caption:
                    '${store.completedSubtopicCountFor(catTopics)} of ${store.totalSubtopicCountFor(catTopics)} subtopics complete',
                color: Theme.of(context).colorScheme.primary,
              ),
              MetricTile(
                icon: Icons.timer_outlined,
                title: 'Hours logged',
                value: '${store.totalHoursLogged.toStringAsFixed(1)}h',
                caption: '$totalHoursGoal hour six-month goal',
                color: const Color(0xFFE05D44),
              ),
              MetricTile(
                icon: Icons.fact_check_outlined,
                title: 'Today',
                value: '$completedTasks/${dailyTasks.length}',
                caption: 'daily prep blocks complete',
                color: const Color(0xFFF2B84B),
              ),
              MetricTile(
                icon: Icons.assessment_outlined,
                title: 'Mocks done',
                value: '${store.completedMockCount}',
                caption: nextMock == null
                    ? 'target complete'
                    : 'next: ${shortDate(nextMock.date)}',
                color: const Color(0xFF4E6EAF),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WeeklyStudyPanel(store: store),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 840;
              final checklist = _DailyChecklist(store: store);
              final progress = _SectionProgressPanel(store: store);
              if (!wide) {
                return Column(
                  children: [checklist, const SizedBox(height: 16), progress],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: checklist),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: progress),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 840;
              final upcoming = _UpcomingMocksPanel(store: store);
              final focus = _FocusQueuePanel(store: store);
              if (!wide) {
                return Column(
                  children: [upcoming, const SizedBox(height: 16), focus],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: upcoming),
                  const SizedBox(width: 16),
                  Expanded(child: focus),
                ],
              );
            },
          ),
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

class _DailyChecklist extends StatelessWidget {
  const _DailyChecklist({required this.store});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Today',
      icon: Icons.fact_check_outlined,
      trailing: Text(
        '${dailyTasks.where((task) => store.isTaskComplete(task.id)).length}/${dailyTasks.length}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      child: Column(
        children: [
          for (final task in dailyTasks)
            CheckboxListTile(
              value: store.isTaskComplete(task.id),
              onChanged: (value) => store.toggleTask(task.id, value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: sectionColor(task.section),
              title: Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              subtitle: Text('${task.detail} - ${task.minutes} min'),
              secondary: Icon(
                sectionIcon(task.section),
                color: sectionColor(task.section),
              ),
            ),
        ],
      ),
    );
  }
}

class _DailyBoostPanel extends StatelessWidget {
  const _DailyBoostPanel({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final start = today.difference(prepStartDate).inDays.abs();
    final lines = List.generate(3, (index) {
      return motivationLines[(start + index + 1) % motivationLines.length];
    });

    return Panel(
      title: 'Daily Boost',
      icon: Icons.auto_awesome_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final chips = [
            for (final line in lines)
              _BoostChip(
                text: line,
                color: compact
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFF4E6EAF),
              ),
          ];
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final chip in chips) ...[
                  chip,
                  if (chip != chips.last) const SizedBox(height: 8),
                ],
              ],
            );
          }
          return Row(
            children: [
              for (final chip in chips) ...[
                Expanded(child: chip),
                if (chip != chips.last) const SizedBox(width: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BoostChip extends StatelessWidget {
  const _BoostChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bolt_outlined, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
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
              '$completed/$total',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
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

class _FocusQueuePanel extends StatelessWidget {
  const _FocusQueuePanel({required this.store});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final queue = catTopics
        .where((topic) => !store.isTopicComplete(topic))
        .take(5);
    return Panel(
      title: 'Next Topics',
      icon: Icons.bolt_outlined,
      child: Column(
        children: [
          for (final topic in queue)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TopicMiniRow(topic: topic, store: store),
            ),
        ],
      ),
    );
  }
}

class _TopicMiniRow extends StatelessWidget {
  const _TopicMiniRow({required this.topic, required this.store});

  final PrepTopic topic;
  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final hours = store.hoursFor(topic.id);
    final progress = store.topicCompletion(topic);
    return Row(
      children: [
        Icon(sectionIcon(topic.section), color: sectionColor(topic.section)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text('${topic.section.shortName} - ${topic.priority} priority'),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: progress,
                  backgroundColor: sectionColor(
                    topic.section,
                  ).withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(
                    sectionColor(topic.section),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${store.completedSubtopicCount(topic)}/${topic.subtopics.length} subtopics - ${hours.toStringAsFixed(1)}h logged',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedTextColor(context),
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
