import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../animations.dart';
import '../../../models/action.dart';
import '../../../models/card.dart';
import '../../../models/card_list.dart';
import '../../../models/game_status.dart';
import '../../../models/move_check.dart';
import '../../../models/move_result.dart';
import '../../../models/pile.dart';
import '../../../providers/game_logic.dart';
import '../../../providers/game_move_history.dart';
import '../../../providers/settings.dart';
import '../../../utils/types.dart';
import '../../../widgets/message_overlay.dart';
import 'auto_solve_button.dart';
import 'game_table.dart';
import 'user_action_indicator.dart';

class PlayArea extends ConsumerStatefulWidget {
  const PlayArea({super.key, required this.orientation});

  final Orientation orientation;

  @override
  ConsumerState<PlayArea> createState() => _PlayAreaState();
}

class _PlayAreaState extends ConsumerState<PlayArea> {
  PlayCard? _selectedCard;
  Pile? _selectedPile;

  void _clearSelection() {
    setState(() {
      _selectedCard = null;
      _selectedPile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(currentGameProvider);
    final table = ref.watch(currentTableProvider);
    final status = ref.watch(gameControllerProvider);
    final highlightedCards = ref.watch(hintedCardsProvider);
    final oneTapMoveEnabled = ref.watch(settingsUseOneTapMoveProvider);
    final twoTapMoveEnabled = ref.watch(settingsUseTwoTapMoveProvider);

    ref.listen(gameControllerProvider, (_, __) {
      _clearSelection();
    });
    ref.listen(settingsUseOneTapMoveProvider, (_, enabled) {
      if (enabled) {
        _clearSelection();
      }
    });

    return OrientationBuilder(
      builder: (context, localOrientation) {
        final showAutoSolveButton =
            ref.watch(settingsShowAutoSolveButtonProvider);

        return Stack(
          alignment: Alignment.center,
          children: [
            GameTable(
              table: table,
              game: game.kind,
              orientation: localOrientation,
              highlightedCards: highlightedCards,
              selectedCards:
                  _selectedCard != null ? PlayCardList([_selectedCard!]) : null,
              lastMovedCards: ref.watch(lastMoveProvider)?.action.move?.cards,
              animateDistribute: status == GameStatus.preparing,
              animateMovement: true,
              currentMoveState: ref.watch(currentMoveProvider)?.state,
              canDragCards: (cards, from) {
                // Avoid dragging card that are stuck behind another cards on bottom
                // (typically in Pyramid-style setup)
                final pileIsExposed = game.kind.setup
                    .get(from)
                    .pickable
                    .findRule<PileIsExposed>();

                if (pileIsExposed != null) {
                  return pileIsExposed
                      .check(MoveCheckArgs(pile: from, table: table));
                }
                return cards.isAllFacingUp;
              },
              onCardTap: (card, pile) async {
                print('card tap $card $pile');
                ScaffoldMessenger.of(context).clearSnackBars();
                final controller = ref.read(gameControllerProvider.notifier);

                final pileInfo = game.kind.setup.get(pile);
                if (pileInfo.onTap != null) {
                  final result = controller.tryMove(MoveIntent(pile, pile));
                  if (result is MoveForbidden) {
                    _showMoveForbiddenSnackbar(context, result);
                  }
                  _clearSelection();
                  return null;
                }

                if (oneTapMoveEnabled && card != null) {
                  final result = controller.tryQuickMove(card, pile);
                  return result is MoveSuccess ? null : PlayCardList([card]);
                }

                if (twoTapMoveEnabled) {
                  if (_selectedCard == null) {
                    if (card != null) {
                      setState(() {
                        _selectedCard = card;
                        _selectedPile = pile;
                      });
                    }
                    return null;
                  } else {
                    MoveResult result;
                    if (_selectedCard == card) {
                      // Card was double tapped. Try to quick move
                      result = controller.tryQuickMove(
                          _selectedCard!, _selectedPile!);
                    } else {
                      result = controller.tryMove(MoveIntent(
                        _selectedPile!,
                        pile,
                        _selectedCard!,
                      ));
                    }

                    if (result is MoveSuccess) {
                      _clearSelection();
                      return null;
                    } else {
                      final firstSelectedCard = _selectedCard;
                      _clearSelection();
                      return PlayCardList([
                        firstSelectedCard!,
                        if (card != null) card,
                      ]);
                    }
                  }
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final overlay = Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(32),
        child: Material(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              move.reason,
              style: textTheme.bodyMedium!.copyWith(color: colorScheme.onError),
            ),
          ),
        ),
      ),
    );

    MessageOverlay.of(context).show(overlay);
  }
}
