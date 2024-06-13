import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/action.dart';
import '../../../models/card_list.dart';
import '../../../models/game_status.dart';
import '../../../models/move_check.dart';
import '../../../models/move_result.dart';
import '../../../providers/game_logic.dart';
import '../../../providers/game_move_history.dart';
import '../../../providers/settings.dart';
import '../../../utils/types.dart';
import 'auto_solve_button.dart';
import 'game_table.dart';
import 'user_action_indicator.dart';

class PlayArea extends ConsumerWidget {
  const PlayArea({super.key, required this.orientation});

  final Orientation orientation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(currentGameProvider);
    final table = ref.watch(currentTableProvider);
    final status = ref.watch(gameControllerProvider);
    final highlightedCards = ref.watch(hintedCardsProvider);

    return OrientationBuilder(
      builder: (context, localOrientation) {
        final showLastMoves = ref.watch(settingsShowLastMoveProvider);

        final showAutoSolveButton =
            ref.watch(settingsShowAutoSolveButtonProvider);

        return Stack(
          alignment: Alignment.center,
          children: [
            GameTable(
              table: table,
              game: game.game,
              orientation: localOrientation,
              highlightedCards: highlightedCards,
              lastMovedCards: ref.watch(lastMoveProvider)?.action.move?.cards,
              showLastMovedCards: showLastMoves,
              animateDistribute: status == GameStatus.preparing,
              animateMovement: true,
              currentMoveState: ref.watch(currentMoveProvider)?.state,
              canDragCards: (cards, from) {
                // Avoid dragging card that are stuck behind another cards on bottom
                // (typically in Pyramid-style setup)
                final pileIsExposed = game.game.setup
                    .get(from)
                    .pickable
                    .findRule<PileIsExposed>();

                if (pileIsExposed != null) {
                  return pileIsExposed
                      .check(MoveCheckArgs(pile: from, table: table));
                }
                return cards.isAllFacingUp;
              },
              onCardTap: (card, pile) {
                print('card tap $card $pile');
                ScaffoldMessenger.of(context).clearSnackBars();
                final controller = ref.read(gameControllerProvider.notifier);

                final pileInfo = game.game.setup.get(pile);
                if (pileInfo.onTap != null) {
                  final result = controller.tryMove(MoveIntent(pile, pile));
                  if (result is MoveForbidden) {
                    _showMoveForbiddenSnackbar(context, result);
                  }
                  return null;
                }
                if (card != null) {
                  final result = controller.tryQuickMove(card, pile);
                  return result is MoveSuccess ? null : [card];
                }
                return null;
              },
              onCardDrop: (card, from, to) {
                final controller = ref.read(gameControllerProvider.notifier);

                final result = controller.tryMove(MoveIntent(from, to, card));

                ScaffoldMessenger.of(context).clearSnackBars();
                if (result is MoveForbidden) {
                  _showMoveForbiddenSnackbar(context, result);
                }
                return null;
              },
            ),
            const Positioned.fill(
              child: UserActionIndicator(),
            ),
            if (showAutoSolveButton)
              const Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AutoSolveButton(),
                ),
              )
          ],
        );
      },
    );
  }

  void _showMoveForbiddenSnackbar(BuildContext context, MoveForbidden move) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(move.reason),
    ));
  }
}
