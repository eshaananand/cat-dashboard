import 'package:flutter/material.dart';

import '../cat_data.dart';
import '../prep_store.dart';
import '../utils/color_utils.dart';
import '../utils/date_utils.dart';
import '../widgets/common_widgets.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({required this.store, super.key});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final phase = phaseFor(todayOnly());
    return AppPage(
      title: 'Study Plan',
      subtitle:
          'A working-professional rhythm: weekday focus blocks, weekend testing, and mock analysis that compounds.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            title: 'Current Phase',
            icon: Icons.flag_outlined,
            child: _PhaseCard(phase: phase, highlighted: true),
          ),
          const SizedBox(height: 16),
          Panel(
            title: 'Phase Map',
            icon: Icons.timeline_outlined,
            child: Column(
              children: [
                for (final item in planPhases) ...[
                  _PhaseCard(phase: item, highlighted: item == phase),
                  if (item != planPhases.last) const Divider(height: 24),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 840;
              final priority = _PriorityPanel();
              final rhythm = _WeeklyRhythmPanel();
              if (!wide) {
                return Column(
                  children: [priority, const SizedBox(height: 16), rhythm],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: priority),
                  const SizedBox(width: 16),
                  Expanded(child: rhythm),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Panel(
            title: 'Resource Stack',
            icon: Icons.bookmark_added_outlined,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final resource in resourceStack)
                  SizedBox(
                    width: 280,
                    child: _ResourceTile(resource: resource),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.phase, required this.highlighted});

  final PlanPhase phase;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF4E6EAF);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlighted ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                phase.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  letterSpacing: 0,
                ),
              ),
              StatusChip(label: phase.range, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            phase.focus,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          for (final action in phase.actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 17, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(action)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PriorityPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const bands = [
      (
        'Highest',
        'RC, Arithmetic, Algebra foundations, DILR representation and set selection',
        'Make these attemptable under time pressure.',
      ),
      (
        'High',
        'Para summary, para completion, odd one out, arrangements, scheduling, tables, graphs, Geometry',
        'Turn these into reliable second-layer marks.',
      ),
      (
        'Medium',
        'Number Systems, Modern Math, unusual DILR sets, para jumbles',
        'Build coverage so paper shifts do not create panic.',
      ),
      (
        'Low',
        'Rare edge cases, fancy shortcuts, highly niche QA tricks',
        'Use only after mock data proves the need.',
      ),
    ];

    return Panel(
      title: 'First 90 Days',
      icon: Icons.priority_high,
      child: Column(
        children: [
          for (final band in bands) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  child: StatusChip(
                    label: band.$1,
                    color: priorityColor(band.$1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        band.$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(band.$3),
                    ],
                  ),
                ),
              ],
            ),
            if (band != bands.last) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class _WeeklyRhythmPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Weekday', '20:45-22:15', 'Concept block plus timed drill'),
      ('Micro-slot', '15-20 min', 'RC reading, formula recall, error log'),
      (
        'Saturday',
        '2 focused blocks',
        'Heavy concepts plus sectional practice',
      ),
      (
        'Sunday',
        '2 focused blocks',
        'Full test or sectionals plus deep review',
      ),
    ];

    return Panel(
      title: 'Weekly Rhythm',
      icon: Icons.schedule,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          dataRowMinHeight: 56,
          dataRowMaxHeight: 72,
          headingTextStyle: Theme.of(context).textTheme.labelLarge,
          columns: const [
            DataColumn(label: Text('Day')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Use')),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  DataCell(Text(row.$1)),
                  DataCell(Text(row.$2)),
                  DataCell(SizedBox(width: 220, child: Text(row.$3))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({required this.resource});

  final ResourceItem resource;

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
          Text(
            resource.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          StatusChip(label: resource.useFor, color: const Color(0xFF4E6EAF)),
          const SizedBox(height: 10),
          Text(resource.note),
        ],
      ),
    );
  }
}
