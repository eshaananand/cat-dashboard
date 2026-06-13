import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cat_data.dart';
import '../prep_store.dart';
import '../utils/date_utils.dart';
import '../widgets/common_widgets.dart';

class MocksScreen extends StatelessWidget {
  const MocksScreen({required this.store, super.key});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final mockPoints = completedMockPoints(store);
    final nextMock = nextUpcomingMock(store, todayOnly());
    final best = store.bestPercentile;
    final average = store.averageMockScore;
    final allMocks = store.allMockSlots;
    final pyqDone = previousYearPapers
        .where((paper) => store.isPyqComplete(paper.id))
        .length;

    return AppPage(
      title: 'Mock Tracker',
      subtitle:
          'Record VARC, DILR, QA, and percentile. The schedule follows the free-first PYQ plus weekly mock cadence from your PDFs.',
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Mock'),
          onPressed: () => addCustomMockDialog(context, store),
        ),
      ],
      child: Column(
        children: [
          ResponsiveMetricGrid(
            children: [
              MetricTile(
                icon: Icons.done_all,
                title: 'Completed',
                value: '${store.completedMockCount}',
                caption: '${allMocks.length} scheduled/custom checks',
                color: Theme.of(context).colorScheme.primary,
              ),
              MetricTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Best percentile',
                value: best == null ? '-' : best.toStringAsFixed(2),
                caption: 'saved mock high',
                color: const Color(0xFFF2B84B),
              ),
              MetricTile(
                icon: Icons.functions,
                title: 'Average score',
                value: average == null ? '-' : average.toStringAsFixed(1),
                caption: 'out of 204 latest-pattern marks',
                color: const Color(0xFFE05D44),
              ),
              MetricTile(
                icon: Icons.event_available_outlined,
                title: 'Next check',
                value: nextMock == null ? 'Done' : shortDate(nextMock.date),
                caption: nextMock?.title ?? 'schedule complete',
                color: const Color(0xFF4E6EAF),
              ),
              MetricTile(
                icon: Icons.checklist_outlined,
                title: 'PYQs done',
                value: '$pyqDone/${previousYearPapers.length}',
                caption: 'previous-year slot checklist',
                color: const Color(0xFF00796B),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Panel(
            title: 'Score Trend',
            icon: Icons.show_chart,
            child: SizedBox(
              height: 220,
              child: mockPoints.length < 2
                  ? const EmptyState(
                      icon: Icons.show_chart,
                      title: 'Trend starts after two mocks',
                      message:
                          'Saved mock totals will draw here automatically.',
                    )
                  : CustomPaint(
                      painter: MockTrendPainter(
                        points: mockPoints,
                        color: Theme.of(context).colorScheme.primary,
                        accent: Theme.of(context).colorScheme.secondary,
                      ),
                      child: const SizedBox.expand(),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Panel(
            title: 'Schedule',
            icon: Icons.calendar_month_outlined,
            child: Column(
              children: [
                for (final mock in allMocks) ...[
                  MockTrackerTile(mock: mock, store: store),
                  if (mock != allMocks.last) const Divider(height: 24),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          PreviousYearChecklist(store: store),
        ],
      ),
    );
  }
}

class MockTrackerTile extends StatelessWidget {
  const MockTrackerTile({required this.mock, required this.store, super.key});

  final MockSlot mock;
  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final result = store.resultFor(mock.id);
    final isPast = mock.date.isBefore(todayOnly());
    final isCustom = mock.id.startsWith('custom_');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DateBadge(date: mock.date),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    mock.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  StatusChip(
                    label: result != null
                        ? 'Done'
                        : isPast
                        ? 'Due'
                        : mock.kind,
                    color: result != null
                        ? const Color(0xFF00796B)
                        : isPast
                        ? const Color(0xFFE05D44)
                        : const Color(0xFF4E6EAF),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(mock.focus),
              if (result != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ScoreChip(label: 'VARC', value: result.varc.toString()),
                    ScoreChip(label: 'DILR', value: result.dilr.toString()),
                    ScoreChip(label: 'QA', value: result.qa.toString()),
                    ScoreChip(label: 'Total', value: result.total.toString()),
                    ScoreChip(
                      label: 'Pct',
                      value: result.percentile.toStringAsFixed(2),
                    ),
                  ],
                ),
                if (result.remarks.isNotEmpty ||
                    result.analysis.isNotEmpty ||
                    result.nextActions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _MockAnalysisPreview(result: result),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            Tooltip(
              message: 'Record score',
              child: IconButton.filledTonal(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => editMockResult(context, mock, store),
              ),
            ),
            if (isCustom)
              Tooltip(
                message: 'Remove custom mock',
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => store.removeCustomMock(mock.id),
                ),
              ),
            if (result != null)
              Tooltip(
                message: 'Clear score',
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => store.clearMockResult(mock.id),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MockAnalysisPreview extends StatelessWidget {
  const _MockAnalysisPreview({required this.result});

  final MockResult result;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (result.remarks.isNotEmpty) ('Remarks', result.remarks),
      if (result.analysis.isNotEmpty) ('Analysis', result.analysis),
      if (result.nextActions.isNotEmpty) ('Next', result.nextActions),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items) ...[
            Text(
              item.$1,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 2),
            Text(item.$2, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (item != items.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class PreviousYearChecklist extends StatelessWidget {
  const PreviousYearChecklist({required this.store, super.key});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<PreviousYearPaper>>{};
    for (final paper in previousYearPapers) {
      grouped.putIfAbsent(paper.year, () => []).add(paper);
    }

    return Panel(
      title: 'Previous-Year Paper Checklist',
      icon: Icons.fact_check_outlined,
      trailing: Text(
        '${grouped.values.expand((items) => items).where((paper) => store.isPyqComplete(paper.id)).length}/${previousYearPapers.length}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      child: Column(
        children: [
          for (final entry in grouped.entries) ...[
            ExpansionTile(
              initiallyExpanded: entry.key >= 2021,
              tilePadding: EdgeInsets.zero,
              title: Text(
                'CAT ${entry.key}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              subtitle: Text(
                '${entry.value.where((paper) => store.isPyqComplete(paper.id)).length}/${entry.value.length} slots complete',
              ),
              children: [
                for (final paper in entry.value)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: store.isPyqComplete(paper.id),
                    onChanged: (value) {
                      store.setPyqComplete(paper.id, value ?? false);
                    },
                    title: Text(paper.title),
                    subtitle: Text('${paper.questions} - ${paper.note}'),
                    secondary: Icon(
                      paper.year >= 2024
                          ? Icons.priority_high
                          : Icons.history_outlined,
                      color: paper.year >= 2024
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            if (entry.key != grouped.keys.last) const Divider(height: 16),
          ],
        ],
      ),
    );
  }
}

Future<void> addCustomMockDialog(BuildContext context, PrepStore store) async {
  final titleController = TextEditingController();
  final kindController = TextEditingController(text: 'Full mock');
  final focusController = TextEditingController();
  var selectedDate = todayOnly();

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add mock'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Mock name',
                        hintText: 'Example: Cracku free mock 1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: kindController,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        hintText: 'Full mock / Sectional / PYQ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: focusController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Focus',
                        hintText: 'What should this mock test?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: Text('Date: ${shortDate(selectedDate)}'),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2026, 1),
                          lastDate: DateTime(2026, 12, 31),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );

  if (saved == true) {
    store.addCustomMock(
      title: titleController.text,
      date: selectedDate,
      kind: kindController.text,
      focus: focusController.text,
    );
  }

  titleController.dispose();
  kindController.dispose();
  focusController.dispose();
}

class MockPoint {
  const MockPoint({required this.slot, required this.result});

  final MockSlot slot;
  final MockResult result;
}

class MockTrendPainter extends CustomPainter {
  const MockTrendPainter({
    required this.points,
    required this.color,
    required this.accent,
  });

  final List<MockPoint> points;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 28.0;
    final chart = Rect.fromLTWH(
      padding,
      padding / 2,
      size.width - padding * 1.5,
      size.height - padding * 1.5,
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFE1E7E5)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF8AA09A)
      ..strokeWidth = 1.4;
    for (var i = 0; i <= 4; i++) {
      final y = chart.top + chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    canvas.drawLine(chart.bottomLeft, chart.bottomRight, axisPaint);
    canvas.drawLine(chart.bottomLeft, chart.topLeft, axisPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pointPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final dx = points.length == 1
          ? chart.left
          : chart.left + chart.width * index / (points.length - 1);
      final score = points[index].result.total.clamp(0, 204);
      final dy = chart.bottom - chart.height * (score / 204);
      final offset = Offset(dx, dy);
      if (index == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawCircle(offset, 5, pointPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant MockTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.accent != accent;
  }
}

Future<void> editMockResult(
  BuildContext context,
  MockSlot mock,
  PrepStore store,
) async {
  final existing = store.resultFor(mock.id);
  final varcController = TextEditingController(
    text: existing?.varc.toString() ?? '',
  );
  final dilrController = TextEditingController(
    text: existing?.dilr.toString() ?? '',
  );
  final qaController = TextEditingController(
    text: existing?.qa.toString() ?? '',
  );
  final percentileController = TextEditingController(
    text: existing?.percentile.toStringAsFixed(2) ?? '',
  );
  final remarksController = TextEditingController(
    text: existing?.remarks ?? '',
  );
  final analysisController = TextEditingController(
    text: existing?.analysis ?? '',
  );
  final nextActionsController = TextEditingController(
    text: existing?.nextActions ?? '',
  );

  final result = await showDialog<MockResult>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(mock.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreField(label: 'VARC', controller: varcController),
              const SizedBox(height: 10),
              _ScoreField(label: 'DILR', controller: dilrController),
              const SizedBox(height: 10),
              _ScoreField(label: 'QA', controller: qaController),
              const SizedBox(height: 10),
              _ScoreField(
                label: 'Percentile',
                controller: percentileController,
                decimal: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: remarksController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'Example: VARC was calm, DILR set choice weak.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: analysisController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mock analysis',
                  hintText:
                      'What to skip, what to solve faster, and what went wrong conceptually.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nextActionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Next actions',
                  hintText: 'Example: revise TSD, do 5 arrangement sets.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              final percentile =
                  (double.tryParse(percentileController.text.trim()) ?? 0)
                      .clamp(0, 100)
                      .toDouble();
              Navigator.pop(
                context,
                MockResult(
                  varc: int.tryParse(varcController.text.trim()) ?? 0,
                  dilr: int.tryParse(dilrController.text.trim()) ?? 0,
                  qa: int.tryParse(qaController.text.trim()) ?? 0,
                  percentile: percentile,
                  remarks: remarksController.text.trim(),
                  analysis: analysisController.text.trim(),
                  nextActions: nextActionsController.text.trim(),
                ),
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      );
    },
  );

  varcController.dispose();
  dilrController.dispose();
  qaController.dispose();
  percentileController.dispose();
  remarksController.dispose();
  analysisController.dispose();
  nextActionsController.dispose();

  if (result != null) {
    store.saveMockResult(mock.id, result);
  }
}

class _ScoreField extends StatelessWidget {
  const _ScoreField({
    required this.label,
    required this.controller,
    this.decimal = false,
  });

  final String label;
  final TextEditingController controller;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

List<MockPoint> completedMockPoints(PrepStore store) {
  final points = <MockPoint>[];
  for (final slot in store.allMockSlots) {
    final result = store.resultFor(slot.id);
    if (result != null) {
      points.add(MockPoint(slot: slot, result: result));
    }
  }
  return points;
}
