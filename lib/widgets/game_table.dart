import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter/scheduler.dart';

import '../animations.dart';
import '../models/card.dart';
import '../models/card_list.dart';
import '../models/direction.dart';
import '../models/pile.dart';
import '../models/play_table.dart';
import '../models/table_layout.dart';
import '../utils/types.dart';
import 'card_view.dart';
import 'pile_marker.dart';
import 'shakeable.dart';
import 'shrinkable.dart';
import 'solitaire_theme.dart';
import 'ticking_number.dart';

class GameTable extends StatefulWidget {
  const GameTable({
    super.key,
    required this.layout,
    required this.table,
    this.interactive = true,
    this.onCardTap,
    this.onCardDrop,
    this.onPileTap,
    this.highlightedCards,
    this.lastMovedCards,
    this.animateDistribute = false,
    this.animateMovement = true,
    this.fitEmptySpaces = false,
  });

  final TableLayout layout;

  final List<PlayCard>? Function(PlayCard card, Pile pile)? onCardTap;

  final List<PlayCard>? Function(Pile pile)? onPileTap;

  final List<PlayCard>? Function(PlayCard card, Pile from, Pile to)? onCardDrop;

  final bool interactive;

  final PlayTable table;

  final List<PlayCard>? highlightedCards;

  final List<PlayCard>? lastMovedCards;

  final bool animateDistribute;

  final bool animateMovement;

  final bool fitEmptySpaces;

  @override
  State<GameTable> createState() => _GameTableState();
}

class _GameTableState extends State<GameTable> {
  List<PlayCard>? _shakingCards;
  List<PlayCard>? _touchingCards;
  Pile? _touchingCardPile;

  Offset? _lastTouchPoint;

  Timer? _touchDragTimer, _shakeCardTimer;

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);

    final Size tableSize;

    // TODO: Calculate this
    if (widget.fitEmptySpaces) {
      tableSize =
          _calculateConsumedTableSpace(context, widget.layout, widget.table);
    } else {
      tableSize = widget.layout.gridSize;
    }

    return IgnorePointer(
      ignoring: !widget.interactive,
      child: AspectRatio(
        aspectRatio: (tableSize.width * theme.cardTheme.unitSize.width) /
            (tableSize.height * theme.cardTheme.unitSize.height),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gridUnit = Size(
              constraints.minWidth / tableSize.width,
              constraints.minHeight / tableSize.height,
            );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                _buildMarkerLayer(context, gridUnit),
                _buildCardLayer(context, gridUnit),
                if (widget.interactive) _buildOverlayLayer(context, gridUnit),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMarkerLayer(BuildContext context, Size gridUnit) {
    return Stack(
      children: [
        for (final item in widget.layout.items)
          Positioned.fromRect(
            rect: Rect.fromLTWH(
              item.stackDirection.dx < 0 && item.shiftStackOnPlace
                  ? item.region.right - 1
                  : item.region.left,
              item.stackDirection.dy < 0 && item.shiftStackOnPlace
                  ? item.region.bottom - 1
                  : item.region.top,
              1,
              1,
            ).scale(gridUnit),
            child: PileMarker(
              pile: item.kind,
              size: gridUnit,
            ),
          ),
      ],
    );
  }

  Widget _buildCardLayer(BuildContext context, Size gridUnit) {
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
      final point = _convertToGrid(event.localPosition, gridUnit);

      final dropRegion = widget.layout.items
          .firstWhereOrNull((item) => item.region.contains(point));

      if (dropRegion != null) {
        if (_touchingCards != null &&
            _touchingCardPile != null &&
            _touchingCardPile != dropRegion.kind) {
          _onCardDrop(context, _touchingCards!.first, _touchingCardPile!,
              dropRegion.kind);
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
                ..._buildPile(context, gridUnit, item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayLayer(BuildContext context, Size gridUnit) {
    return Stack(
      children: [
        for (final item in widget.layout.items)
          if (item.showCountIndicator)
            Positioned.fromRect(
              rect: Rect.fromLTWH(item.region.left, item.region.top, 1, 1)
                  .scale(gridUnit),
              child: _CountIndicator(
                count: widget.table.get(item.kind).length,
                cardSize: gridUnit,
              ),
            ),
      ],
    );
  }

  Size _calculateConsumedTableSpace(
      BuildContext context, TableLayout layout, PlayTable table) {
    var maxWidth = 0.0;
    var maxHeight = 0.0;

    final theme = SolitaireTheme.of(context);

    // TODO: Improve this algorithm
    for (final item in layout.items) {
      switch (item.stackDirection) {
        case Direction.down:
          maxWidth = max(maxWidth, item.region.right);
          maxHeight = max(
            maxHeight,
            item.region.top +
                1 +
                table.get(item.kind).length * theme.cardTheme.stackGap.dy,
          );
        case Direction.none:
        default:
          maxWidth = max(maxWidth, item.region.right);
          maxHeight = max(maxHeight, item.region.bottom);
      }
    }

    return Size(maxWidth, maxHeight);
  }

  List<Widget> _buildPile(
      BuildContext context, Size gridUnit, TableLayoutItem item) {
    final theme = SolitaireTheme.of(context);

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
              index * (gridUnit.height * theme.cardTheme.stackGap.dy * 0.9)),
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
            offset, direction.dx, theme.cardTheme.stackGap.dx, region.width),
        computeOffset(
            offset, direction.dy, theme.cardTheme.stackGap.dy, region.height),
      );
    }

    List<PlayCard> cards = [];

    cards = widget.table.get(item.kind);

    DurationCurve computeAnimation(int cardIndex) {
      if (!widget.animateMovement) {
        return DurationCurve.zero;
      } else if (_lastTouchPoint != null) {
        return cardDragAnimation;
      } else if (widget.animateDistribute && item.kind is Tableau) {
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
                  cardSize: gridUnit,
                  shake: _shakingCards?.contains(card) == true,
                  isMoving: _lastTouchPoint != null &&
                      _touchingCards?.contains(card) == true,
                  onTouch: () => _onCardTouch(context, card, item.kind),
                  card: card,
                  layout: item,
                  cardsInPile: widget.table.get(item.kind),
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
                cardSize: gridUnit,
                shake: _shakingCards?.contains(card) == true,
                isMoving: _lastTouchPoint != null &&
                    _touchingCards?.contains(card) == true,
                onTouch: () => _onCardTouch(context, card, item.kind),
                onTap: () => _onCardTap(context, card, item.kind),
                card: card,
                layout: item,
                cardsInPile: widget.table.get(item.kind),
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
      final cards = widget.table.get(originPile).getLastFromCard(card);
      if (cards.isAllFacingUp) {
        _touchingCards = cards;
      }
    } else if (originPile is Discard) {
      // Always pick top most card regardless of visibility
      final topmostCard = widget.table.get(originPile).lastOrNull;
      _touchingCards = [topmostCard!];
    } else {
      _touchingCards = [card];
    }
  }

  void _onCardTap(BuildContext context, PlayCard card, Pile pile) {
    final feedback = widget.onCardTap?.call(card, pile);
    if (feedback != null) {
      _shakeCard(feedback);
    }
  }

  void _onCardDrop(BuildContext context, PlayCard card, Pile from, Pile to) {
    final feedback = widget.onCardDrop?.call(card, from, to);
    if (feedback != null) {
      _shakeCard(feedback);
    }
  }

  void _onPileTap(BuildContext context, Pile pile) {
    widget.onPileTap?.call(pile);
  }

  void _shakeCard(List<PlayCard>? cards) {
    if (cards == null) {
      return;
    }
    setState(() {
      _shakingCards = cards;
    });
    _shakeCardTimer?.cancel();
    _shakeCardTimer = Timer(cardMoveAnimation.duration * timeDilation, () {
      if (mounted) {
        setState(() {
          _shakingCards = null;
        });
      }
    });
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
  final bool shake;

  final bool isMoving;

  final PlayCard card;

  final TableLayoutItem layout;

  final List<PlayCard> cardsInPile;

  final VoidCallback? onTouch;
  final VoidCallback? onTap;

  final Color? highlightColor;

  final Size cardSize;

  static const cardShowThreshold = 3;
  static const minElevation = 2.0;
  static const hoverElevation = 32.0;

  @override
  Widget build(BuildContext context) {
    final cardPileLength = cardsInPile.length;
    final cardIndex = cardsInPile.indexOf(card);

    final double elevation;
    final bool hideFace;

    if (layout.stackDirection == Direction.none) {
      elevation =
          cardIndex > cardPileLength - 1 - cardShowThreshold ? minElevation : 0;
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
          elevation: isMoving ? hoverElevation : elevation,
          hideFace: hideFace,
          highlightColor: highlightColor,
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
