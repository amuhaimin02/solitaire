import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter/scheduler.dart';
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

class GameTable extends StatelessWidget {
  const GameTable({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final gameRules =
            context.select<GameState, SolitaireRules>((s) => s.rules);

        const cardUnitSize = Size(2.5, 3.5);

        final options = LayoutOptions(
          orientation: orientation,
          mirror: false,
        );

        final tableLayout = gameRules.getLayout(options);

        return AspectRatio(
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
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _MarkerLayer(layout: tableLayout),
                    _CardLayer(layout: tableLayout),
                    _OverlayLayer(layout: tableLayout),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CountIndicator extends StatelessWidget {
  const _CountIndicator({
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

  static const cardShowThreshold = 3;
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
    final colorScheme = Theme.of(context).colorScheme;

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

    final latestAction =
        context.select<GameState, Action?>((s) => s.latestAction);

    final showMoveHighlight = context.select<SettingsManager, bool>(
        (s) => s.get(Settings.showMoveHighlight));

    final hintedCards =
        context.select<GameState, PlayCardList?>((s) => s.hintedCards);

    Color? highlightColor;

    if (hintedCards?.contains(card) == true) {
      highlightColor = colorScheme.error;
    } else if (showMoveHighlight &&
        latestAction is Move &&
        latestAction.from is! Draw &&
        latestAction.to is! Draw &&
        latestAction.cards.contains(card)) {
      highlightColor = colorScheme.secondary;
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
          elevation: elevation,
          hideFace: hideFace,
          highlightColor: highlightColor,
        ),
      ),
    );
  }
}

class _MarkerLayer extends StatelessWidget {
  const _MarkerLayer({super.key, required this.layout});

  final Layout layout;

  @override
  Widget build(BuildContext context) {
    final gameLayout = context.watch<GameLayout>();
    final gridUnit = gameLayout.gridUnit;

    Rect measure(Rect gridRect) {
      return Rect.fromLTWH(
        gridRect.left * gridUnit.width,
        gridRect.top * gridUnit.height,
        gridRect.width * gridUnit.width,
        gridRect.height * gridUnit.height,
      );
    }

    return Stack(
      children: [
        for (final item in layout.items)
          Positioned.fromRect(
            rect: measure(
              Rect.fromLTWH(
                item.stackDirection.dx < 0 && item.shiftStackOnPlace
                    ? item.region.right - 1
                    : item.region.left,
                item.stackDirection.dy < 0 && item.shiftStackOnPlace
                    ? item.region.bottom - 1
                    : item.region.top,
                1,
                1,
              ),
            ),
            child: PileMarker(pile: item.kind),
          ),
      ],
    );
  }
}

class _CardLayer extends StatefulWidget {
  const _CardLayer({super.key, required this.layout});

  final Layout layout;

  @override
  State<_CardLayer> createState() => _CardLayerState();
}

class _CardLayerState extends State<_CardLayer> {
  PlayCard? _shakingCard;
  PlayCardList? _touchingCards;
  Pile? _touchingCardPile;

  Offset? _lastTouchPoint;

  Timer? _touchDragTimer, _shakeCardTimer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gameState = context.watch<GameState>();
    final gameLayout = context.watch<GameLayout>();

    void onPointerCancel() {
      // Reset touch point, indicating that cards are no longer held
      setState(() {
        _lastTouchPoint = null;
      });
      // However, wait for animation to finish before we remove references to touched cards list.
      // Using a timer to it is possible to cancel is a touch event comes again when waiting for the above.
      _touchDragTimer = Timer(cardMoveAnimation.duration * timeDilation, () {
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
      setState(() {});
    }

    void onPointerUp(PointerUpEvent event) {
      final point = _convertToGrid(event.localPosition, gameLayout.gridUnit);

      final dropRegion = widget.layout.items
          .firstWhereOrNull((item) => item.region.contains(point));

      if (dropRegion != null) {
        if (_touchingCards != null &&
            _touchingCardPile != null &&
            _touchingCardPile != dropRegion.kind) {
          _feedbackMoveResult(
            gameState.tryMove(
              MoveIntent(
                  _touchingCardPile!, dropRegion.kind, _touchingCards!.first),
            ),
          );
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
          _lastTouchPoint = event.localPosition;
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

      return [...remainingWidgets, ...recentlyMovedWidgets, ...touchedWidgets];
    }

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: onPointerDown,
      onPointerUp: onPointerUp,
      onPointerMove: onPointerMove,
      onPointerCancel: (_) => onPointerCancel(),
      child: Stack(
        clipBehavior: Clip.none,
        children: sortCardWidgets([
          for (final item in widget.layout.items) ..._buildPile(context, item),
        ]),
      ),
    );
  }

  List<Widget> _buildPile(BuildContext context, LayoutItem item) {
    final layout = context.watch<GameLayout>();
    final gameState = context.watch<GameState>();

    Rect measure(Rect gridRect) {
      return Rect.fromLTWH(
        gridRect.left * layout.gridUnit.width,
        gridRect.top * layout.gridUnit.height,
        gridRect.width * layout.gridUnit.width,
        gridRect.height * layout.gridUnit.height,
      );
    }

    final gridUnit = layout.gridUnit;

    final region = item.region;

    Rect computePosition(PlayCard card, Rect originalPosition) {
      if (_touchingCards != null &&
          _touchingCards!.contains(card) &&
          _lastTouchPoint != null) {
        final newRect = (_lastTouchPoint! & gridUnit);
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
      if (_lastTouchPoint != null) {
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
        return [
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
                  isMoving: _lastTouchPoint != null &&
                      _touchingCards?.contains(card) == true,
                  onTouch: () => _onCardTouch(context, card, item.kind),
                  card: card,
                  layout: item,
                  getPile: gameState.pile,
                ),
              ),
        ];

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

        return [
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
                isMoving: _lastTouchPoint != null &&
                    _touchingCards?.contains(card) == true,
                onTouch: () => _onCardTouch(context, card, item.kind),
                onTap: () => _onCardTap(context, card, item.kind),
                card: card,
                layout: item,
                getPile: gameState.pile,
              ),
            ),
        ];
    }
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
        _feedbackMoveResult(
            gameState.tryMove(MoveIntent(const Draw(), const Discard())));

      case Discard() || Foundation():
        if (gameState.pile(pile).isNotEmpty) {
          final cardToMove = gameState.pile(pile).last;
          _feedbackMoveResult(gameState.tryQuickPlace(cardToMove, pile));
        }
      case _:
      // noop
    }
  }

  MoveResult _feedbackMoveResult(
    MoveResult result, {
    bool shakeOnError = true,
  }) {
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
        if (shakeOnError) {
          _shakeCard(result.card);
        }
      case MoveForbidden():
        if (shakeOnError) {
          _shakeCard(result.move.card);
        }
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
    _shakeCardTimer = Timer(cardMoveAnimation.duration * timeDilation, () {
      if (mounted) {
        setState(() {
          _shakingCard = null;
        });
      }
    });
  }
}

class _OverlayLayer extends StatelessWidget {
  const _OverlayLayer({super.key, required this.layout});

  final Layout layout;

  @override
  Widget build(BuildContext context) {
    final gameLayout = context.watch<GameLayout>();
    final gridUnit = gameLayout.gridUnit;
    final gameState = context.watch<GameState>();
    final colorScheme = Theme.of(context).colorScheme;

    Rect measure(Rect gridRect) {
      return Rect.fromLTWH(
        gridRect.left * gridUnit.width,
        gridRect.top * gridUnit.height,
        gridRect.width * gridUnit.width,
        gridRect.height * gridUnit.height,
      );
    }

    return Stack(
      children: [
        for (final item in layout.items)
          if (item.showCountIndicator)
            Positioned.fromRect(
              rect: measure(
                  Rect.fromLTWH(item.region.left, item.region.top, 1, 1)),
              child: _CountIndicator(count: gameState.pile(item.kind).length),
            ),
        Center(
          child: _UserActionIndicator(userAction: gameState.userAction),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: _AutoSolveButton(),
        )
      ],
    );
  }
}

class _UserActionIndicator extends StatelessWidget {
  const _UserActionIndicator({super.key, this.userAction});

  final UserAction? userAction;

  static const userActionIcon = {
    UserAction.undoMultiple: Icons.fast_rewind,
    UserAction.redoMultiple: Icons.fast_forward,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedSwitcher(
      duration: cardMoveAnimation.duration,
      child: userAction != null
          ? Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: colorScheme.onSecondaryFixed.withOpacity(0.5),
              ),
              child: Icon(userActionIcon[userAction],
                  size: 72, color: colorScheme.secondaryFixed),
            )
          : null,
    );
  }
}

class _AutoSolveButton extends StatefulWidget {
  const _AutoSolveButton({super.key});

  @override
  State<_AutoSolveButton> createState() => _AutoSolveButtonState();
}

class _AutoSolveButtonState extends State<_AutoSolveButton> {
  @override
  Widget build(BuildContext context) {
    final canAutoSolve = context.select<GameState, bool>((s) => s.canAutoSolve);
    final status = context.select<GameState, GameStatus>((s) => s.status);
    final colorScheme = Theme.of(context).colorScheme;

    return Shrinkable(
      show: canAutoSolve && status != GameStatus.autoSolving,
      child: FloatingActionButton.extended(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        onPressed: () {
          context.read<GameState>().startAutoSolve();
        },
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Auto solve'),
      ),
    );
  }
}

//
// class _CardDragOverlay extends StatefulWidget {
//   const _CardDragOverlay({
//     super.key,
//     required this.draggedCards,
//     required this.onStartDrag,
//     required this.onStopDrag,
//   });
//
//   final PlayCardList? draggedCards;
//
//   final PlayCardList? Function() onStartDrag;
//
//   final Function(PlayCardList? cards) onStopDrag;
//
//   @override
//   State<_CardDragOverlay> createState() => _CardDragOverlayState();
// }
//
// class _CardDragOverlayState extends State<_CardDragOverlay> {
//   Offset? _touchPoint;
//
//   PlayCardList? _draggedCards;
//
//   @override
//   Widget build(BuildContext context) {
//     final layout = context.watch<GameLayout>();
//
//     _draggedCards = widget.draggedCards;
//
//     return Listener(
//       behavior: HitTestBehavior.translucent,
//       onPointerMove: (event) {
//         setState(() {
//           _touchPoint = event.localPosition;
//         });
//       },
//       onPointerUp: (_) {
//         setState(() {
//           _touchPoint = null;
//         });
//       },
//       onPointerCancel: (_) {
//         setState(() {
//           _touchPoint = null;
//         });
//       },
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           if (_touchPoint != null && _draggedCards != null)
//             for (final (i, card) in _draggedCards!.indexed)
//               Positioned.fromRect(
//                 rect: (_touchPoint! & layout.gridUnit).shift(
//                   Offset(0, i * layout.gridUnit.height * layout.maxStackGap.dy),
//                 ),
//                 child: CardView(card: card),
//               )
//         ],
//       ),
//     );
//   }
// }
