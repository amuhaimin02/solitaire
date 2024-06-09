import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_selection.dart';
import '../../widgets/two_pane.dart';
import 'widgets/game_selection_detail.dart';
import 'widgets/game_selection_list.dart';
import 'widgets/game_selection_search.dart';

class GameSelectionScreen extends ConsumerStatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  ConsumerState<GameSelectionScreen> createState() =>
      _GameSelectionScreenState();
}

class _GameSelectionScreenState extends ConsumerState<GameSelectionScreen> {
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectedGameProvider.notifier).deselect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearching,
      child: TwoPane(
        primaryBuilder: (context) {
          if (_isSearching) {
            return GameSelectionSearch(
              onCancel: () {
                setState(() => _isSearching = false);
              },
            );
          } else {
            return GameSelectionList(
              onSearchButtonPressed: () {
                setState(() => _isSearching = true);
              },
            );
          }
        },
        secondaryBuilder: (context) => const GameSelectionDetail(),
        stackingStyleOnPortrait: StackingStyle.bottomSheet,
      ),
    );
  }
}
