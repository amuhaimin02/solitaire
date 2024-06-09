import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../providers/game_selection.dart';
import '../../../services/play_table_generator.dart';
import '../../../utils/prng.dart';
import '../../../widgets/empty_screen.dart';
import '../../../widgets/solitaire_theme.dart';
import '../../../widgets/two_pane.dart';
import '../../main/widgets/game_table.dart';
import 'game_selection_options.dart';

class GameSelectionDetail extends ConsumerWidget {
  const GameSelectionDetail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final selectedGame = ref.watch(selectedGameProvider);
    final randomSeed = CustomPRNG.generateSeed(length: 12);

    if (selectedGame == null) {
      return EmptyScreen(
        icon: Icon(MdiIcons.cardsPlaying),
        title: const Text('Select a game'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) {
                  final isInModal = !TwoPane.of(context).isActive;

                  final gameTableWidget = Container(
                    color: SolitaireTheme.of(context).backgroundColor,
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: GameTable(
                        key: ValueKey(selectedGame),
                        game: selectedGame,
                        table: PlayTableGenerator.generateSampleSetup(
                          selectedGame,
                          randomSeed,
                        ),
                        orientation: isInModal
                            ? Orientation.portrait
                            : Orientation.landscape,
                        fitEmptySpaces: true,
                        animateDistribute: false,
                        animateMovement: false,
                        interactive: false,
                      ),
                    ),
                  );
                  if (isInModal) {
                    return gameTableWidget;
                  } else {
                    return Expanded(child: gameTableWidget);
                  }
                },
              ),
              ClipRect(
                clipBehavior: Clip.hardEdge,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        selectedGame.name,
                        style: textTheme.titleLarge!.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Details of gameplay will be available here. '
                        'Details of gameplay will be available here. '
                        'Details of gameplay will be available here. '
                        'Details of gameplay will be available here. ',
                        style: textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 24),
                      GameSelectionOptions(
                        singleLine: constraints.maxHeight <= 500,
                        game: selectedGame,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
