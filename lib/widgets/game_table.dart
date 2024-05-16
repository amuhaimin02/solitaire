import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/card.dart';
import '../models/direction.dart';
import '../models/game_layout.dart';
import '../providers/settings.dart';
import '../models/game_state.dart';
import '../models/pile.dart';
import '../models/rules/rules.dart';
import '../utils/lists.dart';
import 'card_marker.dart';
import 'card_view.dart';
import 'shakeable.dart';
import 'shrinkable.dart';
import 'ticking_number.dart';

class GameTable extends StatefulWidget {
  const GameTable({super.key});

  @override
  State<GameTable> createState() => _GameTableState();
}

class _GameTableState extends State<GameTable> {
  // TODO: Move this out of here
  PlayCard? _touchedCard;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final gameRules = context.select<GameState, Rules>((s) => s.rules);

        const cardUnitSize = Size(2.5, 3.5);

        final options = LayoutOptions(
          orientation: orientation,
          mirror: false,
        );

        final tableLayout = gameRules.getLayout(options);

        return Center(
          child: AspectRatio(
            aspectRatio: (tableLayout.gridSize.width * cardUnitSize.width) /
                (tableLayout.gridSize.height * cardUnitSize.height),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gridUnit = Size(
                  constraints.minWidth / tableLayout.gridSize.width,
                  constraints.minHeight / tableLayout.gridSize.height,
                );

                return ProxyProvider0<GameLayout>(
                  update: (context, obj) => GameLayout(
                    gridUnit: gridUnit,
                    cardPadding: gridUnit.shortestSide * 0.06,
                    maxStackGap: const Offset(0.3, 0.3),
                    orientation: orientation,
                  ),
                  builder: (context, child) {
                    final layout = context.watch<GameLayout>();
                    final gameState = context.watch<GameState>();

                    final layers = [
                      for (final item in tableLayout.items)
                        _buildPile(context, item),
                    ];

                    List<Widget> cardWidgets =
                        layers.map((w) => w.cardLayer).flattened.toList();

                    // TODO: Using card as keys to determine widget owner

                    // Move recently moved cards on top of render stack
                    final recentAction = gameState.latestAction;

                    if (recentAction is Move &&
                        recentAction.from != const Draw() &&
                        recentAction.cards.isNotEmpty) {
                      final recentlyMovedCards = recentAction.cards;

                      final (widgetsOnTop, remainingWidgets) =
                          cardWidgets.partition((w) {
                        if (w.key is! ValueKey<PlayCard>) {
                          return false;
                        }
                        PlayCard card = (w.key as ValueKey<PlayCard>).value;

                        return recentlyMovedCards.contains(card);
                      });

                      cardWidgets = [...remainingWidgets, ...widgetsOnTop];
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final point = _convertToGrid(
                            details.localPosition, layout.gridUnit);

                        for (final item in tableLayout.items) {
                          if (item.region.contains(point)) {
                            _onPileTap(context, item.kind);
                            break;
                          }
                        }
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ...layers.map((w) => w.markerLayer).flattened,
                          ...cardWidgets,
                          ...layers.map((w) => w.overlayLayer).flattened,
                          if (gameState.canAutoSolve)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: FloatingActionButton.extended(
                                onPressed: () => _doAutoSolve(context),
                                icon: const Icon(Icons.auto_fix_high),
                                label: const Text('Auto solve'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  _WidgetLayer _buildPile(BuildContext context, LayoutItem item) {
    final layout = context.watch<GameLayout>();
    final gameState = context.watch<GameState>();

    final gridUnit = layout.gridUnit;

    final region = item.region;

    Rect measure(Rect rect) => _measure(rect, gridUnit);

    Offset calculateStackGap(int index, int stackLength, Direction direction) {
      final int visualIndex, visualLength, offset;

      if (item.numberOfCardsToShow != null) {
        visualLength = item.numberOfCardsToShow!;
        if (stackLength > visualLength) {
          visualIndex =
              max(0, item.numberOfCardsToShow! - (stackLength - index));
        } else {
          if (item.shiftStackOnPlace) {
            visualIndex = visualLength - (stackLength - index);
          } else {
            visualIndex = index;
          }
        }
      } else {
        visualLength = stackLength;
        visualIndex = index;
      }

      if (item.shiftStackOnPlace) {
        offset = visualLength - visualIndex - 1;
      } else {
        offset = visualIndex;
      }

      return Offset(
        direction.dx != 0
            ? ((offset * direction.dx) *
                    min(layout.maxStackGap.dx,
                        (region.width - 1) / (visualLength - 1)))
                .toDouble()
            : 0,
        direction.dy != 0
            ? ((offset * direction.dy) *
                    min(layout.maxStackGap.dy,
                        (region.height - 1) / (visualLength - 1)))
                .toDouble()
            : 0,
      );
    }

    PlayCardList cards = gameState.pile(item.kind);

    DurationCurve calculateAnimation(int cardIndex) {
      if (item.kind is Tableau && gameState.isOnStartingPoint) {
        final tableau = item.kind as Tableau;
        final delayFactor = cardMoveAnimation.duration * 0.3;
        return cardMoveAnimation
            .delayed(delayFactor * (tableau.index + cardIndex));
      } else {
        return cardMoveAnimation;
      }
    }

    const cardShowThreshold = 2;

    Widget buildCard({
      required PlayCard card,
      double? elevation,
      required bool hideFace,
    }) {
      return Shakeable(
        duration: cardMoveAnimation.duration,
        curve: cardMoveAnimation.curve,
        shake: card == _touchedCard,
        onAnimationEnd: () {
          setState(() {
            _touchedCard = null;
          });
        },
        child: CardView(
          card: card,
          pile: item.kind,
          elevation: elevation,
          hideFace: hideFace,
        ),
      );
    }

    switch (item.stackDirection) {
      case Direction.none:
        return _WidgetLayer(
          markerLayer: [
            Positioned.fromRect(
              rect: measure(Rect.fromLTWH(region.left, region.top, 1, 1)),
              child: _buildMarker(item),
            ),
          ],
          cardLayer: [
            if (cards.isNotEmpty)
              for (final (i, card) in cards.indexed)
                AnimatedPositioned.fromRect(
                  key: ValueKey(card),
                  duration: calculateAnimation(i).duration,
                  curve: calculateAnimation(i).curve,
                  rect: measure(Rect.fromLTWH(region.left, region.top, 1, 1)),
                  child: buildCard(
                    card: card,
                    elevation: i == cards.length - 1
                        ? cards.length.clamp(2, 24).toDouble()
                        : 0,
                    hideFace: cards.length > cardShowThreshold &&
                        cards.length - 1 - i - cardShowThreshold > 0,
                  ),
                ),
          ],
          overlayLayer: [
            if (item.showCountIndicator)
              Positioned.fromRect(
                rect: measure(Rect.fromLTWH(region.left, region.top, 1, 1)),
                child: CountIndicator(count: cards.length),
              ),
          ],
        );

      default:
        Rect markerLocation;
        if (item.shiftStackOnPlace) {
          markerLocation =
              Rect.fromLTWH(region.right - 1, region.bottom - 1, 1, 1);
        } else {
          markerLocation = Rect.fromLTWH(region.left, region.top, 1, 1);
        }

        Offset stackAnchor;
        if (item.stackDirection == Direction.left) {
          stackAnchor = Offset(region.width - 1, 0);
        } else if (item.stackDirection == Direction.up) {
          stackAnchor = Offset(0, region.height - 1);
        } else {
          stackAnchor = Offset.zero;
        }

        final cardLimit = item.numberOfCardsToShow;

        return _WidgetLayer(
          markerLayer: [
            Positioned.fromRect(
              rect: measure(markerLocation),
              child: _buildMarker(item),
            ),
          ],
          cardLayer: [
            for (final (i, card) in cards.indexed)
              AnimatedPositioned.fromRect(
                key: ValueKey(card),
                duration: calculateAnimation(i).duration,
                curve: calculateAnimation(i).curve,
                rect: measure(
                  Rect.fromLTWH(region.left, region.top, 1, 1)
                      .shift(stackAnchor)
                      .shift(calculateStackGap(
                          i, cards.length, item.stackDirection)),
                ),
                child: GestureDetector(
                  onTap: () => _onCardTap(context, card, item.kind),
                  child: buildCard(
                    card: card,
                    elevation: cardLimit != null && i < cards.length - cardLimit
                        ? 0
                        : null,
                    hideFace: cardLimit != null &&
                        i < cards.length - cardLimit - cardShowThreshold,
                  ),
                ),
              ),
          ],
          overlayLayer: [],
        );
    }
  }

  Widget _buildMarker(LayoutItem item) {
    return CardMarker(
      mark: switch (item.kind) {
        Draw() => MdiIcons.refresh,
        Discard() => MdiIcons.cardsPlaying,
        Foundation() => MdiIcons.circleOutline,
        Tableau() => MdiIcons.close,
      },
    );
  }

  Rect _measure(Rect gridRect, Size gridUnit) {
    return Rect.fromLTWH(
      gridRect.left * gridUnit.width,
      gridRect.top * gridUnit.height,
      gridRect.width * gridUnit.width,
      gridRect.height * gridUnit.height,
    );
  }

  Offset _convertToGrid(Offset point, Size gridUnit) {
    return point.scale(1 / gridUnit.width, 1 / gridUnit.height);
  }

  void _onCardTap(BuildContext context, PlayCard card, Pile pile) {
    print('card tap! $card at $pile');

    final gameState = context.read<GameState>();

    switch (pile) {
      case Tableau():
        _feedbackMoveResult(gameState.tryQuickPlace(card, pile));
        return;
      case _:
      // noop
    }

    _onPileTap(context, pile);
  }

  void _onPileTap(BuildContext context, Pile pile) {
    print('pile tap! $pile');

    final gameState = context.read<GameState>();

    switch (pile) {
      case Draw():
        final result = _feedbackMoveResult(
            gameState.tryMove(MoveIntent(const Draw(), const Discard())));
        if (result is MoveSuccess) {
          if (result.move.to == const Discard() &&
              context.read<Settings>().autoMoveOnDraw()) {
            Future.delayed(
              cardMoveAnimation.duration,
              () {
                return _feedbackMoveResult(gameState.tryQuickPlace(
                    gameState.pile(const Discard()).last, const Discard()));
              },
            );
          }
        }

      case Discard() || Foundation():
        if (gameState.pile(pile).isNotEmpty) {
          final cardToMove = gameState.pile(pile).last;
          _feedbackMoveResult(gameState.tryQuickPlace(cardToMove, pile));
        }
      case _:
      // noop
    }
  }

  void _doAutoSolve(BuildContext context) async {
    final gameState = context.read<GameState>();

    bool handled;

    do {
      handled = false;
      for (final move in gameState.rules.tryAutoSolve(gameState.pile)) {
        final result = _feedbackMoveResult(gameState.tryMove(move));
        if (result is MoveSuccess) {
          handled = true;
          if (gameState.isWinning) {
            print('Auto solve done');
            return;
          }
          await Future.delayed(cardMoveAnimation.duration * 2);
          break;
        }
      }
    } while (handled);
  }

  MoveResult _feedbackMoveResult(MoveResult result) {
    switch (result) {
      case MoveSuccess():
        switch (result.move.to) {
          case Discard():
            HapticFeedback.lightImpact();
          case Tableau():
            HapticFeedback.mediumImpact();
          case Draw() || Foundation():
            HapticFeedback.heavyImpact();
        }
      case MoveNotDone():
        setState(() {
          _touchedCard = result.card;
        });
      case MoveForbidden():
        setState(() {
          _touchedCard = result.move.card;
        });
    }
    return result;
  }
}

class _WidgetLayer {
  final List<Widget> markerLayer;
  final List<Widget> cardLayer;
  final List<Widget> overlayLayer;

  _WidgetLayer({
    required this.markerLayer,
    required this.cardLayer,
    required this.overlayLayer,
  });
}

class CountIndicator extends StatelessWidget {
  const CountIndicator({
    super.key,
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<GameLayout>();

    final size = layout.gridUnit.shortestSide;

    return FractionalTranslation(
      translation: const Offset(0, -1),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Shrinkable(
          show: count > 0,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: size * 0.45,
            height: size * 0.45,
            margin: EdgeInsets.all(layout.cardPadding),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: TickingNumber(
              count,
              duration: cardMoveAnimation.duration * 1.5,
              curve: cardMoveAnimation.curve,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.25,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
