import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../cat_data.dart';
import '../prep_store.dart';
import '../utils/color_utils.dart';
import '../utils/date_utils.dart';
import '../widgets/common_widgets.dart';

const int _overallTarget = 115;
const int _varcTarget = 42;
const int _dilrTarget = 36;
const int _qaTarget = 37;

const List<_TargetRowData> _targetRows = [
  _TargetRowData(
    section: 'VARC',
    safeTarget: '42-45',
    primaryTarget: _varcTarget,
    percentile: '99-99.5+',
  ),
  _TargetRowData(
    section: 'DILR',
    safeTarget: '35-38',
    primaryTarget: _dilrTarget,
    percentile: '99-99.5+',
  ),
  _TargetRowData(
    section: 'QA',
    safeTarget: '35-38',
    primaryTarget: _qaTarget,
    percentile: '99-99.5+',
  ),
  _TargetRowData(
    section: 'Overall',
    safeTarget: '112-121',
    primaryTarget: _overallTarget,
    percentile: 'Around 99.8+',
  ),
];

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({required this.store, super.key});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final today = todayOnly();
    final daysLeft = math.max(targetExamDate.difference(today).inDays, 0);
    final stats = _GoalStats.fromStore(store);
    final avgTotal = stats.averageTotal;
    final bestTotal = stats.bestTotal;
    final latestTotal = stats.latest?.total;
    final avgGap = avgTotal == null ? null : _overallTarget - avgTotal;
    final bestGap = bestTotal == null ? null : _overallTarget - bestTotal;

    return AppPage(
      title: 'Goals',
      subtitle:
          'Target scoreboard for the 99.8+ CAT push, updated from your saved mocks.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveMetricGrid(
            children: [
              MetricTile(
                icon: Icons.flag_outlined,
                title: 'Primary target',
                value: '$_overallTarget',
                caption: 'VARC $_varcTarget, DILR $_dilrTarget, QA $_qaTarget',
                color: Theme.of(context).colorScheme.primary,
              ),
              MetricTile(
                icon: Icons.calendar_today_outlined,
                title: 'Days left',
                value: '$daysLeft',
                caption: '$examDateLabel target date',
                color: const Color(0xFF4E6EAF),
              ),
              MetricTile(
                icon: Icons.functions,
                title: 'Average marks',
                value: avgTotal == null ? '-' : avgTotal.toStringAsFixed(1),
                caption: avgGap == null
                    ? 'save a mock score to start'
                    : _gapCaption(avgGap),
                color: const Color(0xFFE05D44),
              ),
              MetricTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Highest marks',
                value: bestTotal?.toString() ?? '-',
                caption: bestGap == null
                    ? 'best saved mock total'
                    : _gapCaption(bestGap.toDouble()),
                color: const Color(0xFFF2B84B),
              ),
              MetricTile(
                icon: Icons.percent_outlined,
                title: 'Average percentile',
                value: stats.averagePercentile == null
                    ? '-'
                    : stats.averagePercentile!.toStringAsFixed(2),
                caption: stats.bestPercentile == null
                    ? 'save percentiles in mocks'
                    : 'best: ${stats.bestPercentile!.toStringAsFixed(2)}',
                color: const Color(0xFF00796B),
              ),
              MetricTile(
                icon: Icons.insights_outlined,
                title: 'Latest mock',
                value: latestTotal?.toString() ?? '-',
                caption: stats.latest == null
                    ? 'no saved mock yet'
                    : '${stats.latest!.title} - ${stats.latest!.percentile.toStringAsFixed(2)} pct',
                color: const Color(0xFF6A5ACD),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 880;
              final targetPanel = const _TargetScorePanel();
              final trackerPanel = _LiveGoalTracker(stats: stats);
              if (!wide) {
                return Column(
                  children: [
                    targetPanel,
                    const SizedBox(height: 16),
                    trackerPanel,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 5, child: _TargetScorePanel()),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: trackerPanel),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const _PercentileEstimatePanel(),
        ],
      ),
    );
  }

  static String _gapCaption(double gap) {
    if (gap <= 0) {
      return '${gap.abs().toStringAsFixed(1)} above target';
    }
    return '${gap.toStringAsFixed(1)} marks to target';
  }
}

class _TargetScorePanel extends StatelessWidget {
  const _TargetScorePanel();

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Final CAT Target',
      icon: Icons.flag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PrimaryTargetBlock(),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: Theme.of(context).textTheme.labelLarge,
              dataTextStyle: Theme.of(context).textTheme.bodyLarge,
              columns: const [
                DataColumn(label: Text('Section')),
                DataColumn(label: Text('Safe target marks')),
                DataColumn(label: Text('Target pct')),
              ],
              rows: [
                for (final row in _targetRows)
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          row.section,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      DataCell(Text(row.safeTarget)),
                      DataCell(Text(row.percentile)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryTargetBlock extends StatelessWidget {
  const _PrimaryTargetBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          ScoreChip(label: 'Overall', value: '115'),
          ScoreChip(label: 'VARC', value: '42'),
          ScoreChip(label: 'DILR', value: '36'),
          ScoreChip(label: 'QA', value: '37'),
        ],
      ),
    );
  }
}

class _LiveGoalTracker extends StatelessWidget {
  const _LiveGoalTracker({required this.stats});

  final _GoalStats stats;

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Live Gap Tracker',
      icon: Icons.track_changes_outlined,
      child: Column(
        children: [
          _GoalProgressRow(
            label: 'Overall',
            target: _overallTarget,
            average: stats.averageTotal,
            best: stats.bestTotal?.toDouble(),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          _GoalProgressRow(
            label: 'VARC',
            target: _varcTarget,
            average: stats.averageVarc,
            best: stats.bestVarc?.toDouble(),
            color: sectionColor(CatSection.varc),
          ),
          const SizedBox(height: 14),
          _GoalProgressRow(
            label: 'DILR',
            target: _dilrTarget,
            average: stats.averageDilr,
            best: stats.bestDilr?.toDouble(),
            color: sectionColor(CatSection.dilr),
          ),
          const SizedBox(height: 14),
          _GoalProgressRow(
            label: 'QA',
            target: _qaTarget,
            average: stats.averageQa,
            best: stats.bestQa?.toDouble(),
            color: sectionColor(CatSection.qa),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  const _GoalProgressRow({
    required this.label,
    required this.target,
    required this.average,
    required this.best,
    required this.color,
  });

  final String label;
  final int target;
  final double? average;
  final double? best;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = average == null
        ? 0.0
        : (average! / target).clamp(0, 1).toDouble();
    final gap = average == null ? null : target - average!;
    final averageLabel = average == null ? '-' : average!.toStringAsFixed(1);
    final bestLabel = best == null ? '-' : best!.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              'Avg $averageLabel / $target',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MetaChip(icon: Icons.flag_outlined, label: 'Target $target'),
            MetaChip(icon: Icons.trending_up, label: 'Best $bestLabel'),
            MetaChip(
              icon: Icons.linear_scale,
              label: gap == null
                  ? 'Gap -'
                  : gap <= 0
                  ? '${gap.abs().toStringAsFixed(1)} above'
                  : '${gap.toStringAsFixed(1)} left',
            ),
          ],
        ),
      ],
    );
  }
}

class _PercentileEstimatePanel extends StatelessWidget {
  const _PercentileEstimatePanel();

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Percentile Estimate Notes',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              ScoreChip(label: '99.5 est.', value: '97-103'),
              ScoreChip(label: '99.8 target', value: '110-118'),
              ScoreChip(label: '99.9 est.', value: '115-122'),
              ScoreChip(label: 'Margin', value: '115+'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Percentile is relative, so the same marks can map to a different percentile across years and slots. For now this dashboard uses 115 as the primary target because it gives margin inside the 99.8+ estimate range.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: mutedTextColor(context),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetRowData {
  const _TargetRowData({
    required this.section,
    required this.safeTarget,
    required this.primaryTarget,
    required this.percentile,
  });

  final String section;
  final String safeTarget;
  final int primaryTarget;
  final String percentile;
}

class _GoalStats {
  const _GoalStats({
    required this.count,
    required this.averageTotal,
    required this.averageVarc,
    required this.averageDilr,
    required this.averageQa,
    required this.averagePercentile,
    required this.bestTotal,
    required this.bestVarc,
    required this.bestDilr,
    required this.bestQa,
    required this.bestPercentile,
    required this.latest,
  });

  final int count;
  final double? averageTotal;
  final double? averageVarc;
  final double? averageDilr;
  final double? averageQa;
  final double? averagePercentile;
  final int? bestTotal;
  final int? bestVarc;
  final int? bestDilr;
  final int? bestQa;
  final double? bestPercentile;
  final _LatestMockResult? latest;

  factory _GoalStats.fromStore(PrepStore store) {
    final results = store.mockResults.entries.map((entry) {
      final slot = store.allMockSlots
          .where((mock) => mock.id == entry.key)
          .firstOrNull;
      return _ScoredMock(
        date: slot?.date ?? DateTime.fromMillisecondsSinceEpoch(0),
        title: slot?.title ?? 'Saved mock',
        result: entry.value,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    if (results.isEmpty) {
      return const _GoalStats(
        count: 0,
        averageTotal: null,
        averageVarc: null,
        averageDilr: null,
        averageQa: null,
        averagePercentile: null,
        bestTotal: null,
        bestVarc: null,
        bestDilr: null,
        bestQa: null,
        bestPercentile: null,
        latest: null,
      );
    }

    final count = results.length;
    final mockResults = results.map((mock) => mock.result).toList();
    final latest = results.last;

    return _GoalStats(
      count: count,
      averageTotal: _average(mockResults.map((result) => result.total)),
      averageVarc: _average(mockResults.map((result) => result.varc)),
      averageDilr: _average(mockResults.map((result) => result.dilr)),
      averageQa: _average(mockResults.map((result) => result.qa)),
      averagePercentile: _average(
        mockResults.map((result) => result.percentile),
      ),
      bestTotal: mockResults.map((result) => result.total).reduce(math.max),
      bestVarc: mockResults.map((result) => result.varc).reduce(math.max),
      bestDilr: mockResults.map((result) => result.dilr).reduce(math.max),
      bestQa: mockResults.map((result) => result.qa).reduce(math.max),
      bestPercentile: mockResults
          .map((result) => result.percentile)
          .reduce(math.max),
      latest: _LatestMockResult(
        title: latest.title,
        total: latest.result.total,
        percentile: latest.result.percentile,
      ),
    );
  }

  static double _average(Iterable<num> values) {
    final list = values.toList();
    return list.fold<double>(0, (sum, value) => sum + value) / list.length;
  }
}

class _ScoredMock {
  const _ScoredMock({
    required this.date,
    required this.title,
    required this.result,
  });

  final DateTime date;
  final String title;
  final MockResult result;
}

class _LatestMockResult {
  const _LatestMockResult({
    required this.title,
    required this.total,
    required this.percentile,
  });

  final String title;
  final int total;
  final double percentile;
}
