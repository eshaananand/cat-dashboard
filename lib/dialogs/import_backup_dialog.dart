import 'package:flutter/material.dart';

import '../prep_store.dart';

Future<void> importBackup(BuildContext context, PrepStore store) async {
  final controller = TextEditingController();
  final imported = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Import backup JSON'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            maxLines: 10,
            minLines: 5,
            decoration: const InputDecoration(
              hintText: 'Paste the backup JSON here.',
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
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Import'),
          ),
        ],
      );
    },
  );

  if (imported == true && context.mounted) {
    final ok = store.importBackupJson(controller.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Backup imported' : 'Backup JSON was not valid'),
      ),
    );
  }
  controller.dispose();
}
