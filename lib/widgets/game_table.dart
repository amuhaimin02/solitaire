import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/card.dart';
import '../models/direction.dart';
import '../models/game_layout.dart';
import '../models/game_state.dart';
import '../models/pile.dart';
import '../models/rules/rules.dart';
import '../providers/settings.dart';
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
  PlayCard? _shakingCard;
  PlayCardList? _touchingCards;
  Pile? _touchingCardPile;

  bool _isAutoSolving = false;

  Offset? _touchPoint;

  Timer? _touchDragTimer, _shakeCardTimer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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

                    void onPointerCancel() {
                      // Reset touch point, indicating that cards are no longer held
                      setState(() {
                        _touchPoint = null;
                      });
                      // However, wait for animation to finish before we remove references to touched cards list.
                      // Using a timer to it is possible to cancel is a touch event comes again when waiting for the above.
                      _touchDragTimer = Timer(cardMoveAnimation.duration, () {
                        if (mounted) {
                          setState(() {
                            _touchingCards = null;
                            _touchingCardPile = null;
                          });
                        }
                      });
                    }

                    void onPointerDown(PointerDownEvent event) {
                      _touchDragTimer?.cancel();
                    }

                    void onPointerUp(PointerUpEvent event) {
                      final point =
                          _convertToGrid(event.localPosition, layout.gridUnit);

                      final dropRegion = tableLayout.items.firstWhereOrNull(
                          (item) => item.region.contains(point));

                      if (dropRegion != null) {
                        if (_touchingCards != null &&
                            _touchingCardPile != null &&
                            _touchingCardPile != dropRegion.kind) {
                          final result = gameState.tryMove(
                            MoveIntent(_touchingCardPile!, dropRegion.kind,
                                _touchingCards!.first),
                          );
                          if (result is MoveSuccess) {
                            _feedbackMoveResult(result);
                          }
                        } else {
                          // Register as a normal tap (typically when user taps a tableau region not covered by cards)
                          _onPileTap(context, dropRegion.kind);
                        }
                      }

                      onPointerCancel();
                    }

                    void onPointerMove(PointerMoveEvent event) {
                      if (_touchingCards != null) {
                        setState(() {
                          _touchPoint = event.localPosition;
                        });
                      }
                    }

                    List<Widget> sortCardWidgets(Iterable<Widget> cardWidgets) {
                      if (_shakingCard != null) {
                        return cardWidgets.toList();
                      }

                      final recentlyMovedWidgets = <Widget>[];
                      final touchedWidgets = <Widget>[];
                      final remainingWidgets = <Widget>[];

                      // TODO: Using card as keys to determine widget owner
                      // Move recently moved cards on top of render stack
                      final recentAction = gameState.latestAction;
                      final recentlyMovedCards =
                          recentAction is Move ? recentAction.cards : null;

                      for (final widget in cardWidgets) {
                        final key = widget.key;
                        if (key is! ValueKey<PlayCard>) {
                          throw ArgumentError(
                              'Card widgets should have a ValueKey containing a PlayCard instance');
                        }
                        final card = key.value;

                        if (_touchingCards?.contains(card) == true) {
                          touchedWidgets.add(widget);
                        } else if (recentlyMovedCards?.contains(card) == true) {
                          recentlyMovedWidgets.add(widget);
                        } else {
                          remainingWidgets.add(widget);
                        }
                      }

                      return [
                        ...remainingWidgets,
                        ...recentlyMovedWidgets,
                        ...touchedWidgets
                      ];
                    }

                    return Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: onPointerDown,
                      onPointerUp: onPointerUp,
                      onPointerMove: onPointerMove,
                      onPointerCancel: (_) => onPointerCancel(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ...layers.map((w) => w.markerLayer).flattened,
                          ...sortCardWidgets(
                              layers.map((w) => w.cardLayer).flattened),
                          ...layers.map((w) => w.overlayLayer).flattened,
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Shrinkable(
                              show: gameState.canAutoSolve,
                              child: FloatingActionButton.extended(
                                backgroundColor: colorScheme.tertiary,
                                foregroundColor: colorScheme.onTertiary,
                                onPressed: _isAutoSolving
                                    ? null
                                    : () => _doAutoSolve(context),
                                icon: const Icon(Icons.auto_fix_high),
                                label: _isAutoSolving
                                    ? const Text('Auto solving...')
                                    : const Text('Auto solve'),
                              ),
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

    Rect computePosition(PlayCard card, Rect originalPosition) {
      if (_touchingCards != null &&
          _touchingCards!.contains(card) &&
          _touchPoint != null) {
        final newRect = (_touchPoint! & gridUnit);
        final index = _touchingCards!.indexOf(card);
        return newRect.translate(
          -(gridUnit.width * 0.5),
          -(gridUnit.height * 0.75 -
              index * (gridUnit.height * layout.maxStackGap.dy * 0.9)),
        );
      } else {
        return measure(originalPosition);
      }
    }

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

      double computeOffset(int offset, int directionComponent,
          double maxStackGap, double regionSize) {
        return directionComponent != 0
            ? (offset *
                directionComponent *
                min(maxStackGap, (regionSize - 1) / (visualLength - 1)))
            : 0;
      }

      return Offset(
        computeOffset(
            offset, direction.dx, layout.maxStackGap.dx, region.width),
        computeOffset(
            offset, direction.dy, layout.maxStackGap.dy, region.height),
      );
    }

    PlayCardList cards = gameState.pile(item.kind);

    DurationCurve computeAnimation(int cardIndex) {
      if (_touchPoint != null) {
        return cardDragAnimation;
      } else if (item.kind is Tableau && gameState.isPreparing) {
        final tableau = item.kind as Tableau;
        final delayFactor = cardMoveAnimation.duration * 0.3;
        return cardMoveAnimation
            .delayed(delayFactor * (tableau.index + cardIndex));
      } else {
        return cardMoveAnimation;
      }
    }

    switch (item.stackDirection) {
      case Direction.none:
        return _WidgetLayer(
          markerLayer: [
            Positioned.fromRect(
              rect: measure(Rect.fromLTWH(region.left, region.top, 1, 1)),
              child: PileMarker(pile: item.kind),
            ),
          ],
          cardLayer: [
            if (cards.isNotEmpty)
              for (final (i, card) in cards.indexed)
                AnimatedPositioned.fromRect(
                  key: ValueKey(card),
                  duration: computeAnimation(i).duration,
                  curve: computeAnimation(i).curve,
                  rect: computePosition(
                      card, Rect.fromLTWH(region.left, region.top, 1, 1)),
                  child: _CardWidget(
                    shake: _shakingCard == card,
                    isMoving: _touchPoint != null &&
                        _touchingCards?.contains(card) == true,
                    onTouch: () => _onCardTouch(context, card, item.kind),
                    card: card,
                    layout: item,
                    getPile: gameState.pile,
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

        return _WidgetLayer(
          markerLayer: [
            Positioned.fromRect(
              rect: measure(markerLocation),
              child: PileMarker(pile: item.kind),
            ),
          ],
          cardLayer: [
            for (final (i, card) in cards.indexed)
              AnimatedPositioned.fromRect(
                key: ValueKey(card),
                duration: computeAnimation(i).duration,
                curve: computeAnimation(i).curve,
                rect: computePosition(
                  card,
                  Rect.fromLTWH(region.left, region.top, 1, 1)
                      .shift(stackAnchor)
                      .shift(calculateStackGap(
                          i, cards.length, item.stackDirection)),
                ),
                child: _CardWidget(
                  shake: _shakingCard == card,
                  isMoving: _touchPoint != null &&
                      _touchingCards?.contains(card) == true,
                  onTouch: () => _onCardTouch(context, card, item.kind),
                  onTap: () => _onCardTap(context, card, item.kind),
                  card: card,
                  layout: item,
                  getPile: gameState.pile,
                ),
              ),
          ],
          overlayLayer: [],
        );
    }
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

  void _onCardTouch(BuildContext context, PlayCard card, Pile originPile) {
    final gameState = context.read<GameState>();

    _touchingCardPile = originPile;

    if (originPile is Tableau) {
      _touchingCards = gameState.pile(originPile).getUntilLast(card);
    } else if (originPile is Discard) {
      // Always pick top most card regardless of visibility
      final topmostCard = gameState.pile(originPile).lastOrNull;
      _touchingCards = [topmostCard!];
    } else {
      _touchingCards = [card];
    }
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

    // _onPileTap(context, pile);
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
                final autoMoveResult = gameState.tryQuickPlace(
                    gameState.pile(const Discard()).last, const Discard());
                if (autoMoveResult is MoveSuccess) {
                  _feedbackMoveResult(autoMoveResult);
                }
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

    try {
      bool handled;

      setState(() {
        _isAutoSolving = true;
      });
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
            await Future.delayed(cardMoveAnimation.duration * 0.5);
            break;
          }
        }
      } while (handled);
    } finally {
      setState(() {
        _isAutoSolving = false;
      });
    }
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
        _shakeCard(result.card);
      case MoveForbidden():
        _shakeCard(result.move.card);
    }
    return result;
  }

  void _shakeCard(PlayCard? card) {
    if (card == null) {
      return;
    }
    setState(() {
      _shakingCard = card;
    });
    _shakeCardTimer?.cancel();
    _shakeCardTimer = Timer(cardMoveAnimation.duration, () {
      if (mounted) {
        setState(() {
          _shakingCard = null;
        });
      }
    });
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
    final isPreparing = context.select<GameState, bool>((s) => s.isPreparing);

    final size = layout.gridUnit.shortestSide;

    return FractionalTranslation(
      translation: const Offset(0, -1),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Shrinkable(
          show: !isPreparing && count > 0,
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

class _CardWidget extends StatelessWidget {
  const _CardWidget({
    required this.shake,
    required this.isMoving,
    required this.card,
    required this.layout,
    required this.getPile,
    this.onTouch,
    this.onTap,
  });

  static const cardShowThreshold = 2;
  static const minElevation = 2.0;
  static const maxElevation = 12.0;

  final bool shake;

  final bool isMoving;

  final PlayCard card;

  final LayoutItem layout;

  final PileGetter getPile;

  final VoidCallback? onTouch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardsInPile = getPile(layout.kind);
    final cardPileLength = cardsInPile.length;
    final cardIndex = cardsInPile.indexOf(card);

    final double elevation;
    final bool hideFace;

    if (layout.stackDirection == Direction.none) {
      elevation = cardIndex == cardPileLength - 1
          ? (cardIndex / 2).clamp(minElevation, maxElevation).toDouble()
          : 0;
      hideFace = cardPileLength > cardShowThreshold &&
          cardPileLength - 1 - cardIndex - cardShowThreshold > 0;
    } else {
      final cardLimit = layout.numberOfCardsToShow;
      if (cardLimit != null && cardIndex < cardPileLength - cardLimit) {
        elevation = 0;
      } else {
        elevation = minElevation;
      }
      hideFace = cardLimit != null &&
          cardIndex < cardPileLength - cardLimit - cardShowThreshold;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onTouch?.call(),
      onTap: onTap,
      child: Shakeable(
        duration: cardMoveAnimation.duration,
        curve: cardMoveAnimation.curve,
        shake: shake,
        child: CardView(
          card: card,
          pile: layout.kind,
          elevation: elevation,
          hideFace: hideFace,
        ),
      ),
    );
  }
}
