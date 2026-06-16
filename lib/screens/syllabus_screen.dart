import 'package:flutter/material.dart';

import '../cat_data.dart';
import '../prep_store.dart';
import '../utils/color_utils.dart';
import '../widgets/common_widgets.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({required this.store, super.key});

  final PrepStore store;

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTopics();
    final progress = widget.store.completionFor(filtered);

    return AppPage(
      title: 'Syllabus Tracker',
      subtitle:
          'Built from the working CAT syllabus in your PDFs: RC-heavy VARC, set-selection DILR, and Arithmetic plus Algebra-led QA.',
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Topic'),
          onPressed: () => addCustomTopicDialog(context, widget.store),
        ),
        Tooltip(
          message: 'Reset progress',
          child: IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: () => _confirmReset(context),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    selected: {_filter},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _filter = selection.first;
                      });
                    },
                    segments: const [
                      ButtonSegment(
                        value: 'All',
                        label: Text('All'),
                        icon: Icon(Icons.all_inbox),
                      ),
                      ButtonSegment(
                        value: 'VARC',
                        label: Text('VARC'),
                        icon: Icon(Icons.menu_book),
                      ),
                      ButtonSegment(
                        value: 'DILR',
                        label: Text('DILR'),
                        icon: Icon(Icons.account_tree),
                      ),
                      ButtonSegment(
                        value: 'QA',
                        label: Text('QA'),
                        icon: Icon(Icons.calculate),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: progress,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.store.completedSubtopicCountFor(filtered)} of ${widget.store.totalSubtopicCountFor(filtered)} subtopics complete',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedTextColor(context),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final section in CatSection.values)
            if (_filter == 'All' || _filter == section.shortName) ...[
              _SectionTopicGroup(
                section: section,
                topics: widget.store.allTopics
                    .where((topic) => topic.section == section)
                    .toList(),
                store: widget.store,
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }

  List<PrepTopic> _filteredTopics() {
    if (_filter == 'All') {
      return widget.store.allTopics;
    }
    return widget.store.allTopics
        .where((topic) => topic.section.shortName == _filter)
        .toList();
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset dashboard progress?'),
          content: const Text(
            'This clears checked subtopics, notes, study logs, study hours, weekly study days, reminders, and mock results.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      widget.store.resetProgress();
    }
  }
}

class _SectionTopicGroup extends StatelessWidget {
  const _SectionTopicGroup({
    required this.section,
    required this.topics,
    required this.store,
  });

  final CatSection section;
  final List<PrepTopic> topics;
  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final progress = store.completionFor(topics);
    return Panel(
      title: section.shortName,
      icon: sectionIcon(section),
      trailing: Text(
        '${(progress * 100).round()}%',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: sectionColor(section),
          letterSpacing: 0,
        ),
      ),
      child: Column(
        children: [
          for (final topic in topics) ...[
            TopicTrackerTile(topic: topic, store: store),
            if (topic != topics.last) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class TopicTrackerTile extends StatelessWidget {
  const TopicTrackerTile({required this.topic, required this.store, super.key});

  final PrepTopic topic;
  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final complete = store.isTopicComplete(topic);
    final hours = store.hoursFor(topic.id);
    final progress = store.topicCompletion(topic);
    final topicNote = store.noteFor(topicNoteId(topic));
    final subtopics = store.subtopicsFor(topic);
    final isCustomTopic = store.isCustomTopic(topic.id);
    final completedUnits = subtopics.isEmpty
        ? complete
              ? 1
              : 0
        : store.completedSubtopicCount(topic);
    final totalUnits = subtopics.isEmpty ? 1 : subtopics.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: softSurfaceColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor(context)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Checkbox(
          value: complete,
          activeColor: sectionColor(topic.section),
          onChanged: (value) => store.setTopicComplete(topic, value ?? false),
        ),
        title: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              topic.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            StatusChip(
              label: topic.priority,
              color: priorityColor(topic.priority),
            ),
            if (isCustomTopic)
              StatusChip(
                label: 'Custom',
                color: Theme.of(context).colorScheme.primary,
              ),
            if (topicNote.isNotEmpty)
              StatusChip(
                label: 'Notes',
                color: Theme.of(context).colorScheme.tertiary,
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(topic.detail),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MetaChip(icon: Icons.folder_outlined, label: topic.cluster),
                  MetaChip(icon: Icons.speed_outlined, label: topic.difficulty),
                  MetaChip(
                    icon: Icons.query_stats_outlined,
                    label: topic.weight,
                  ),
                  MetaChip(
                    icon: Icons.check_circle_outline,
                    label: '$completedUnits/$totalUnits completion items',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final progressBar = ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 9,
                      value: progress.clamp(0, 1),
                      backgroundColor: sectionColor(
                        topic.section,
                      ).withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(
                        sectionColor(topic.section),
                      ),
                    ),
                  );
                  final actions = Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${(progress * 100).round()}% - ${hours.toStringAsFixed(1)}/${topic.plannedHours}h',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Tooltip(
                        message: 'Topic notes',
                        child: IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            topicNote.isEmpty
                                ? Icons.note_add_outlined
                                : Icons.sticky_note_2,
                          ),
                          onPressed: () => editNote(
                            context,
                            store,
                            topicNoteId(topic),
                            '${topic.title} notes',
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Add subtopics',
                        child: IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.playlist_add),
                          onPressed: () =>
                              addCustomSubtopicsDialog(context, store, topic),
                        ),
                      ),
                      Tooltip(
                        message: 'Remove 30 minutes',
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => store.addTopicHours(topic, -0.5),
                        ),
                      ),
                      Tooltip(
                        message: 'Add 30 minutes',
                        child: IconButton.filledTonal(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.add),
                          onPressed: () => store.addTopicHours(topic, 0.5),
                        ),
                      ),
                      if (isCustomTopic)
                        Tooltip(
                          message: 'Delete custom topic',
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                confirmRemoveCustomTopic(context, store, topic),
                          ),
                        ),
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        progressBar,
                        const SizedBox(height: 8),
                        actions,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: progressBar),
                      const SizedBox(width: 10),
                      actions,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        children: [
          if (topicNote.isNotEmpty) ...[
            NotePreview(note: topicNote),
            const SizedBox(height: 12),
          ],
          for (final subtopic in subtopics) ...[
            SubtopicTrackerTile(topic: topic, subtopic: subtopic, store: store),
            if (subtopic != subtopics.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class SubtopicTrackerTile extends StatelessWidget {
  const SubtopicTrackerTile({
    required this.topic,
    required this.subtopic,
    required this.store,
    super.key,
  });

  final PrepTopic topic;
  final PrepSubtopic subtopic;
  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    final complete = store.isSubtopicComplete(subtopic.id);
    final note = store.noteFor(subtopicNoteId(subtopic));
    final isCustomSubtopic = store.isCustomSubtopic(subtopic.id);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: complete,
            activeColor: sectionColor(topic.section),
            onChanged: (value) {
              store.setSubtopicComplete(topic, subtopic, value ?? false);
            },
          ),
          const SizedBox(width: 8),
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
                      subtopic.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    StatusChip(
                      label: subtopic.difficulty,
                      color: sectionColor(topic.section),
                    ),
                    if (isCustomSubtopic)
                      StatusChip(
                        label: 'Custom',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    if (note.isNotEmpty)
                      StatusChip(
                        label: 'Notes',
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(subtopic.about),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MetaChip(
                      icon: Icons.percent_outlined,
                      label: subtopic.weightage,
                    ),
                    MetaChip(
                      icon: Icons.history_outlined,
                      label: subtopic.pastYears,
                    ),
                    MetaChip(
                      icon: Icons.tips_and_updates_outlined,
                      label: subtopic.practiceHint,
                    ),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  NotePreview(note: note),
                ],
              ],
            ),
          ),
          Tooltip(
            message: 'Subtopic notes',
            child: IconButton(
              icon: Icon(
                note.isEmpty ? Icons.note_add_outlined : Icons.edit_note,
              ),
              onPressed: () => editNote(
                context,
                store,
                subtopicNoteId(subtopic),
                '${subtopic.title} notes',
              ),
            ),
          ),
          if (isCustomSubtopic)
            Tooltip(
              message: 'Delete custom subtopic',
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => confirmRemoveCustomSubtopic(
                  context,
                  store,
                  topic,
                  subtopic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NotePreview extends StatelessWidget {
  const NotePreview({required this.note, super.key});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> editNote(
  BuildContext context,
  PrepStore store,
  String noteId,
  String title,
) async {
  final controller = TextEditingController(text: store.noteFor(noteId));
  final saved = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            maxLines: 8,
            minLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write your formulas, traps, examples, or doubts here.',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ''),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, controller.text),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (saved != null) {
    store.saveNote(noteId, saved);
  }
}

Future<void> addCustomTopicDialog(BuildContext context, PrepStore store) async {
  var section = CatSection.varc;
  final titleController = TextEditingController();
  final clusterController = TextEditingController();
  final detailController = TextEditingController();
  final hoursController = TextEditingController(text: '4');
  final subtopicsController = TextEditingController();

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final canSave = titleController.text.trim().isNotEmpty;
          return AlertDialog(
            title: const Text('Add custom topic'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<CatSection>(
                      initialValue: section,
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final item in CatSection.values)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.shortName),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            section = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Topic name',
                        hintText: 'Example: Venn diagrams',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: clusterController,
                      decoration: const InputDecoration(
                        labelText: 'Cluster',
                        hintText: 'Example: Modern Maths',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Short detail',
                        hintText: 'What should this topic cover?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Planned hours',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subtopicsController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Subtopics',
                        hintText: 'One subtopic per line',
                        border: OutlineInputBorder(),
                      ),
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
                onPressed: canSave ? () => Navigator.pop(context, true) : null,
                icon: const Icon(Icons.add),
                label: const Text('Add topic'),
              ),
            ],
          );
        },
      );
    },
  );

  if (saved == true) {
    store.addCustomTopic(
      section: section,
      title: titleController.text,
      cluster: clusterController.text,
      detail: detailController.text,
      plannedHours: int.tryParse(hoursController.text.trim()) ?? 4,
      subtopicTitles: _linesFrom(subtopicsController.text),
    );
  }

  titleController.dispose();
  clusterController.dispose();
  detailController.dispose();
  hoursController.dispose();
  subtopicsController.dispose();
}

Future<void> addCustomSubtopicsDialog(
  BuildContext context,
  PrepStore store,
  PrepTopic topic,
) async {
  final controller = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final canSave = _linesFrom(controller.text).isNotEmpty;
          return AlertDialog(
            title: Text('Add subtopics - ${topic.title}'),
            content: SizedBox(
              width: 520,
              child: TextField(
                controller: controller,
                minLines: 5,
                maxLines: 8,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Subtopics',
                  hintText: 'One subtopic per line',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: canSave ? () => Navigator.pop(context, true) : null,
                icon: const Icon(Icons.playlist_add),
                label: const Text('Add subtopics'),
              ),
            ],
          );
        },
      );
    },
  );

  if (saved == true) {
    store.addCustomSubtopics(topic, _linesFrom(controller.text));
  }
  controller.dispose();
}

Future<void> confirmRemoveCustomTopic(
  BuildContext context,
  PrepStore store,
  PrepTopic topic,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete custom topic?'),
        content: Text(
          'This removes "${topic.title}" and its custom subtopics from your tracker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      );
    },
  );
  if (confirmed == true) {
    store.removeCustomTopic(topic);
  }
}

Future<void> confirmRemoveCustomSubtopic(
  BuildContext context,
  PrepStore store,
  PrepTopic topic,
  PrepSubtopic subtopic,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete custom subtopic?'),
        content: Text('This removes "${subtopic.title}" from ${topic.title}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      );
    },
  );
  if (confirmed == true) {
    store.removeCustomSubtopic(topic, subtopic);
  }
}

List<String> _linesFrom(String raw) {
  return raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

String topicNoteId(PrepTopic topic) => 'topic:${topic.id}';

String subtopicNoteId(PrepSubtopic subtopic) => 'subtopic:${subtopic.id}';
