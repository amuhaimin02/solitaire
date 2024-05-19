import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter/scheduler.dart';

import '../animations.dart';
import '../models/card.dart';
import '../models/direction.dart';
import '../models/pile.dart';
import '../models/rules/rules.dart';
import 'card_view.dart';
import 'pile_marker.dart';
import 'shakeable.dart';
import 'shrinkable.dart';
import 'solitaire_theme.dart';
import 'ticking_number.dart';

class GameTable extends StatelessWidget {
  const GameTable({
    super.key,
    required this.layout,
    required this.cards,
    this.interactive = true,
    this.onCardTap,
    this.onCardDrop,
    this.onPileTap,
    this.highlightedCards,
    this.lastMovedCards,
    this.animatedDistribute = false,
  });

  final Layout layout;

  final bool Function(PlayCard card, Pile pile)? onCardTap;

  final bool Function(Pile pile)? onPileTap;
  final bool Function(PlayCard card, Pile from, Pile to)? onCardDrop;

  final bool interactive;

  final PlayCards cards;

  final PlayCardList? highlightedCards;

  final PlayCardList? lastMovedCards;

  final bool animatedDistribute;

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);

    return IgnorePointer(
      ignoring: !interactive,
      child: AspectRatio(
        aspectRatio: (layout.gridSize.width * theme.cardUnitSize.width) /
            (layout.gridSize.height * theme.cardUnitSize.height),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardSize = Size(
              constraints.minWidth / layout.gridSize.width,
              constraints.minHeight / layout.gridSize.height,
            );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                _MarkerLayer(
                  layout: layout,
                  cardSize: cardSize,
                ),
                _CardLayer(
                  layout: layout,
                  cards: cards,
                  cardSize: cardSize,
                  onCardTap: onCardTap,
                  onPileTap: onPileTap,
                  onCardDrop: onCardDrop,
                  highlightedCards: highlightedCards,
                  lastMovedCards: lastMovedCards,
                  animatedDistribute: animatedDistribute,
                ),
                if (interactive)
                  _OverlayLayer(
                    layout: layout,
                    cards: cards,
                    cardSize: cardSize,
                  ),
                // Text(status.toString()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CountIndicator extends StatelessWidget {
  const _CountIndicator({
    super.key,
    required this.count,
    required this.cardSize,
  });

  final int count;

  final Size cardSize;

  @override
  Widget build(BuildContext context) {
    return FractionalTranslation(
      translation: const Offset(0, -1),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Shrinkable(
          show: count > 0,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: cardSize.shortestSide * 0.45,
            height: cardSize.shortestSide * 0.45,
            // margin: EdgeInsets.all(layout.cardPadding),
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
                fontSize: cardSize.shortestSide * 0.25,
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
    required this.cardSize,
    required this.shake,
    required this.isMoving,
    required this.card,
    required this.layout,
    required this.cardsInPile,
    this.onTouch,
    this.onTap,
    this.highlightColor,
  });

  static const cardShowThreshold = 3;
  static const minElevation = 2.0;
  static const maxElevation = 12.0;

  final bool shake;

  final bool isMoving;

  final PlayCard card;

  final LayoutItem layout;

  final PlayCardList cardsInPile;

  final VoidCallback? onTouch;
  final VoidCallback? onTap;

  final Color? highlightColor;

  final Size cardSize;

  @override
  Widget build(BuildContext context) {
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
          size: cardSize,
          elevation: elevation,
          hideFace: hideFace,
          highlightColor: highlightColor,
        ),
      ),
    );
  }
}

class _MarkerLayer extends StatelessWidget {
  const _MarkerLayer({super.key, required this.layout, required this.cardSize});

  final Layout layout;

  final Size cardSize;

  @override
  Widget build(BuildContext context) {
    Rect measure(Rect gridRect) {
      return Rect.fromLTWH(
        gridRect.left * cardSize.width,
        gridRect.top * cardSize.height,
        gridRect.width * cardSize.width,
        gridRect.height * cardSize.height,
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
            child: PileMarker(
              pile: item.kind,
              size: cardSize,
            ),
          ),
      ],
    );
  }
}

class _CardLayer extends StatefulWidget {
  const _CardLayer({
    super.key,
    required this.cards,
    required this.cardSize,
    required this.layout,
    this.onCardTap,
    this.onCardDrop,
    this.onPileTap,
    this.highlightedCards,
    this.lastMovedCards,
    this.animatedDistribute = false,
  });

  final PlayCards cards;

  final Size cardSize;

  final bool Function(PlayCard card, Pile pile)? onCardTap;
  final bool Function(Pile pile)? onPileTap;
  final bool Function(PlayCard card, Pile from, Pile to)? onCardDrop;

  final PlayCardList? highlightedCards;

  final PlayCardList? lastMovedCards;

  final Layout layout;

  final bool animatedDistribute;

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
    }

    void onPointerUp(PointerUpEvent event) {
      final point = _convertToGrid(event.localPosition, widget.cardSize);

      final dropRegion = widget.layout.items
          .firstWhereOrNull((item) => item.region.contains(point));

      if (dropRegion != null) {
        if (_touchingCards != null &&
            _touchingCardPile != null &&
            _touchingCardPile != dropRegion.kind) {
          final handled = widget.onCardDrop?.call(
              _touchingCards!.first, _touchingCardPile!, dropRegion.kind);
          if (handled == false) {
            _shakeCard(_touchingCards!.first);
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
          _lastTouchPoint = event.localPosition;
        });
      }
    }

    List<Widget> sortCardWidgets(Iterable<Widget> cardWidgets) {
      final recentlyMovedWidgets = <Widget>[];
      final touchedWidgets = <Widget>[];
      final remainingWidgets = <Widget>[];

      // TODO: Using card as keys to determine widget owner
      // Move recently moved cards on top of render stack
      for (final w in cardWidgets) {
        final key = w.key;
        if (key is! ValueKey<PlayCard>) {
          throw ArgumentError(
              'Card widgets should have a ValueKey containing a PlayCard instance');
        }
        final card = key.value;

        if (_touchingCards?.contains(card) == true) {
          touchedWidgets.add(w);
        } else if (widget.lastMovedCards?.contains(card) == true) {
          recentlyMovedWidgets.add(w);
        } else {
          remainingWidgets.add(w);
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
        children: [
          ...sortCardWidgets(
            [
              for (final item in widget.layout.items)
                ..._buildPile(context, item),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPile(BuildContext context, LayoutItem item) {
    final theme = SolitaireTheme.of(context);

    final gridUnit = widget.cardSize;

    Rect measure(Rect gridRect) {
      return Rect.fromLTWH(
        gridRect.left * gridUnit.width,
        gridRect.top * gridUnit.height,
        gridRect.width * gridUnit.width,
        gridRect.height * gridUnit.height,
      );
    }

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
              index * (gridUnit.height * theme.cardStackGap.dy * 0.9)),
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
            offset, direction.dx, theme.cardStackGap.dx, region.width),
        computeOffset(
            offset, direction.dy, theme.cardStackGap.dy, region.height),
      );
    }

    PlayCardList cards = [];

    cards = widget.cards(item.kind);

    DurationCurve computeAnimation(int cardIndex) {
      if (_lastTouchPoint != null) {
        return cardDragAnimation;
      } else if (widget.animatedDistribute && item.kind is Tableau) {
        final tableau = item.kind as Tableau;
        final delayFactor = cardMoveAnimation.duration * 0.3;
        // return cardMoveAnimation.timeScaled(10);

        return cardMoveAnimation
            .delayed(delayFactor * (tableau.index + cardIndex));
      } else {
        return cardMoveAnimation;
      }
    }

    Color? highlightCardColor(PlayCard card) {
      if (widget.highlightedCards?.contains(card) == true) {
        return theme.hintHighlightColor;
      } else if (widget.lastMovedCards?.contains(card) == true) {
        return theme.lastMoveHighlightColor;
      }
      return null;
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
                  cardSize: widget.cardSize,
                  shake: _shakingCard == card,
                  isMoving: _lastTouchPoint != null &&
                      _touchingCards?.contains(card) == true,
                  onTouch: () => _onCardTouch(context, card, item.kind),
                  card: card,
                  layout: item,
                  cardsInPile: widget.cards(item.kind),
                  highlightColor: highlightCardColor(card),
                ),
              ),
        ];

      default:
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
                cardSize: widget.cardSize,
                shake: _shakingCard == card,
                isMoving: _lastTouchPoint != null &&
                    _touchingCards?.contains(card) == true,
                onTouch: () => _onCardTouch(context, card, item.kind),
                onTap: () => _onCardTap(context, card, item.kind),
                card: card,
                layout: item,
                cardsInPile: widget.cards(item.kind),
                highlightColor: highlightCardColor(card),
              ),
            ),
        ];
    }
  }

  Offset _convertToGrid(Offset point, Size gridUnit) {
    return point.scale(1 / gridUnit.width, 1 / gridUnit.height);
  }

  void _onCardTouch(BuildContext context, PlayCard card, Pile originPile) {
    _touchingCardPile = originPile;

    if (originPile is Tableau) {
      _touchingCards = widget.cards(originPile).getUntilLast(card);
    } else if (originPile is Discard) {
      // Always pick top most card regardless of visibility
      final topmostCard = widget.cards(originPile).lastOrNull;
      _touchingCards = [topmostCard!];
    } else {
      _touchingCards = [card];
    }
  }

  void _onCardTap(BuildContext context, PlayCard card, Pile pile) {
    final handled = widget.onCardTap?.call(card, pile);
    if (handled == false) {
      _shakeCard(card);
    }
  }

  void _onPileTap(BuildContext context, Pile pile) {
    widget.onPileTap?.call(pile);
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
  const _OverlayLayer(
      {super.key, required this.layout, this.cards, required this.cardSize});

  final Layout layout;

  final PlayCards? cards;

  final Size cardSize;

  @override
  Widget build(BuildContext context) {
    Rect measure(Rect gridRect) {
      final gridUnit = cardSize;

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
              child: _CountIndicator(
                count: cards!(item.kind).length,
                cardSize: cardSize,
              ),
            ),
      ],
    );
  }
}

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
