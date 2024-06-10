import 'package:flutter/material.dart';

import '../../../widgets/fixes.dart';

class ContinueFailedDialog extends StatelessWidget {
  const ContinueFailedDialog({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return DialogThemeFix(
      child: AlertDialog(
        title: const Text('Cannot continue'),
        content: Text(
          'Save file appears to be corrupted.\n'
          'Start with new game instead?\n\n'
          'Error message:\n$error',
        ),
        actions: [
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Another game'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('New game'),
          ),
        ],
      ),
    );
  }
}
