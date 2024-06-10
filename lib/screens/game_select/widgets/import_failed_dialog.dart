import 'package:flutter/material.dart';

import '../../../widgets/fixes.dart';

class ImportFailedDialog extends StatelessWidget {
  const ImportFailedDialog({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return DialogThemeFix(
      child: AlertDialog(
        title: const Text('Import failed'),
        titleTextStyle:
            textTheme.headlineSmall!.copyWith(color: colorScheme.error),
        content: Text(
          'Could not load the save file.\n'
          'Please ensure the file you chose is correct and compatible.\n\n'
          'Error message:\n$error',
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
}
