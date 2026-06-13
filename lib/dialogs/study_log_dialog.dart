import 'package:flutter/material.dart';

import '../prep_store.dart';
import '../utils/date_utils.dart';

Future<void> editStudyLog(
  BuildContext context,
  PrepStore store,
  DateTime date,
) async {
  var studied = store.isStudyDay(date);
  final controller = TextEditingController(text: store.studyLogFor(date));
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Study log - ${longDate(date)}'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: studied,
                    onChanged: (value) {
                      setDialogState(() {
                        studied = value ?? false;
                      });
                    },
                    title: const Text('I studied on this date'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    enabled: studied,
                    maxLines: 7,
                    minLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'What did you study?',
                      hintText:
                          'Example: 2 RC passages, percentage drill, 1 DILR table set, error-log review.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
  if (saved == true) {
    store.saveStudyLog(date, studied, controller.text);
  }
  controller.dispose();
}
