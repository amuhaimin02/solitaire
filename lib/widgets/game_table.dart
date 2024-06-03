import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter/scheduler.dart';

import '../animations.dart';
import '../models/card.dart';
import '../models/card_list.dart';
import '../models/direction.dart';
import '../models/game/solitaire.dart';
import '../models/pile.dart';
import '../models/pile_property.dart';
import '../models/play_table.dart';
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
    required this.game,
    required this.table,
    this.interactive = true,
    this.onCardTap,
    this.onCardDrop,
    this.onPileTap,
    this.canDragCards,
    this.highlightedCards,
    this.lastMovedCards,
    this.animateDistribute = false,
    this.animateMovement = true,
    this.fitEmptySpaces = false,
    this.orientation = Orientation.portrait,
    this.debugHighlightPileRegion = false,
  });

  final SolitaireGame game;

  final List<PlayCard>? Function(PlayCard card, Pile pile)? onCardTap;

  final List<PlayCard>? Function(Pile pile)? onPileTap;

  final List<PlayCard>? Function(PlayCard card, Pile from, Pile to)? onCardDrop;

  final bool Function(List<PlayCard> card, Pile from)? canDragCards;

  final bool interactive;

  final PlayTable table;

  final List<PlayCard>? highlightedCards;

  final List<PlayCard>? lastMovedCards;

  final bool animateDistribute;

  final bool animateMovement;

  final bool fitEmptySpaces;

  final Orientation orientation;

  final bool debugHighlightPileRegion;

  @override
  State<GameTable> createState() => _GameTableState();
}

class _GameTableState extends State<GameTable> {
  List<PlayCard>? _shakingCards;
  List<PlayCard>? _touchingCards;
  Pile? _touchingCardPile;

  Offset? _lastTouchPoint;

  Timer? _touchDragTimer, _shakeCardTimer;

  late Map<Pile, Rect> _resolvedRegion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolvePiles();
  }

  @override
  void didUpdateWidget(covariant GameTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolvePiles();
  }

  Map<Pile, PileProperty> get _allPiles => widget.game.piles;

  void _resolvePiles() {
    _resolvedRegion = _allPiles.map((pile, prop) =>
        MapEntry(pile, prop.layout.region.resolve(widget.orientation)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = SolitaireTheme.of(context);

    final Size tableSize;

    if (widget.fitEmptySpaces) {
      tableSize = _calculateConsumedTableSpace(context);
    } else {
      tableSize = widget.game.tableSize.resolve(widget.orientation);
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
                if (widget.debugHighlightPileRegion)
                  _buildDebugLayer(context, gridUnit),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMarkerLayer(BuildContext context, Size gridUnit) {
    Rect computeMarkerPlacement(Pile pile) {
      final layout = _allPiles.get(pile).layout;
      final region = _resolvedRegion.get(pile);
      final shiftStack =
          layout.shiftStack?.resolve(widget.orientation) ?? false;
      final stackDirection =
          layout.stackDirection?.resolve(widget.orientation) ?? Direction.none;

      final rect = Rect.fromLTWH(
        stackDirection.dx < 0 && shiftStack ? region.right - 1 : region.left,
        stackDirection.dy < 0 && shiftStack ? region.bottom - 1 : region.top,
        1,
        1,
      );

      return rect;
    }

    return Stack(
      children: [
        for (final item in _allPiles.entries)
          if (!item.value.virtual &&
              item.value.layout.showMarker?.resolve(widget.orientation) !=
                  false)
            Positioned.fromRect(
              rect: computeMarkerPlacement(item.key).scale(gridUnit),
              child: PileMarker(
                pile: item.key,
                size: gridUnit,
              ),
            ),
      ],
    );
  }

  Widget _buildDebugLayer(BuildContext context, Size gridUnit) {
    final tableSize = widget.game.tableSize.resolve(widget.orientation);
    return Stack(
      children: [
        Positioned.fromRect(
          rect: (Offset.zero & tableSize).scale(gridUnit),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 2,
              ),
            ),
          ),
        ),
        for (final item in _allPiles.entries)
          Positioned.fromRect(
            rect: _resolvedRegion.get(item.key).scale(gridUnit),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.yellow,
                  width: 2,
                ),
              ),
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

      // Find pile belonging to the region, also ignore virtual ones
      final dropPile = _allPiles.keys.firstWhereOrNull(
        (pile) =>
            !_allPiles.get(pile).virtual &&
            _resolvedRegion.get(pile).contains(point),
      );

      if (dropPile != null) {
        if (_touchingCards != null &&
            _touchingCardPile != null &&
            _touchingCardPile != dropPile) {
          _onCardDrop(
              context, _touchingCards!.first, _touchingCardPile!, dropPile);
        } else {
          // Register as a normal tap (typically when user taps a tableau region not covered by cards)
          _onPileTap(context, dropPile);
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
              for (final pile in _allPiles.keys)
                ..._buildPile(context, gridUnit, pile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayLayer(BuildContext context, Size gridUnit) {
    return Stack(
      children: [
        for (final item in _allPiles.entries)
          if (item.value.layout.showCount?.resolve(widget.orientation) == true)
            Positioned.fromRect(
              rect: Rect.fromLTWH(_resolvedRegion.get(item.key).left,
                      _resolvedRegion.get(item.key).top, 1, 1)
                  .scale(gridUnit),
              child: _CountIndicator(
                count: widget.table.get(item.key).length,
                cardSize: gridUnit,
              ),
            ),
      ],
    );
  }

  List<Widget> _buildPile(BuildContext context, Size gridUnit, Pile pile) {
    final theme = SolitaireTheme.of(context);

    final layout = _allPiles.get(pile).layout;
    final region = _resolvedRegion.get(pile);
    final stackDirection =
        layout.stackDirection?.resolve(widget.orientation) ?? Direction.none;

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
        return originalPosition.scale(gridUnit);
      }
    }

    List<PlayCard> cards = [];

    cards = widget.table.get(pile);

    DurationCurve computeAnimation(int cardIndex) {
      if (!widget.animateMovement) {
        return DurationCurve.zero;
      } else if (_lastTouchPoint != null) {
        return cardDragAnimation;
      } else if (widget.animateDistribute && pile is Tableau) {
        final tableau = pile;
        final delayFactor = cardMoveAnimation.duration * 0.3;

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

    switch (stackDirection) {
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
                  onTouch: () => _onCardTouch(context, card, pile),
                  card: card,
                  layout: layout,
                  stackDirection: stackDirection,
                  orientation: widget.orientation,
                  cardsInPile: widget.table.get(pile),
                  highlightColor: highlightCardColor(card),
                ),
              ),
        ];

      default:
        Offset stackAnchor;
        if (stackDirection == Direction.left) {
          stackAnchor = Offset(region.width - 1, 0);
        } else if (stackDirection == Direction.up) {
          stackAnchor = Offset(0, region.height - 1);
        } else {
          stackAnchor = Offset.zero;
        }

        final shiftStack =
            layout.shiftStack?.resolve(widget.orientation) ?? false;
        final previewCards =
            layout.previewCards?.resolve(widget.orientation) ?? 0;

        final stackGapPositions = _computeStackGapPositions(
          context: context,
          cards: cards,
          region: region,
          stackDirection: stackDirection,
          previewCards: previewCards,
          shiftStack: shiftStack,
        );

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
                    // .shift(computeStackGap(i, cards.length, stackDirection)),
                    .shift(stackGapPositions[i]),
              ),
              child: _CardWidget(
                cardSize: gridUnit,
                shake: _shakingCards?.contains(card) == true,
                isMoving: _lastTouchPoint != null &&
                    _touchingCards?.contains(card) == true,
                onTouch: () => _onCardTouch(context, card, pile),
                onTap: () => _onCardTap(context, card, pile),
                card: card,
                layout: layout,
                stackDirection: stackDirection,
                orientation: widget.orientation,
                cardsInPile: widget.table.get(pile),
                highlightColor: highlightCardColor(card),
              ),
            ),
        ];
    }
  }

  Offset _convertToGrid(Offset point, Size gridUnit) {
    return point.scale(1 / gridUnit.width, 1 / gridUnit.height);
  }

  List<Offset> _computeStackGapPositions({
    required BuildContext context,
    required List<PlayCard> cards,
    required Rect region,
    required Direction stackDirection,
    int? previewCards,
    bool? shiftStack,
  }) {
    final theme = SolitaireTheme.of(context);
    final stackGap = theme.cardTheme.stackGap;
    final compressStack = theme.cardTheme.compressStack;

    final halfStack = stackGap.scale(0.5, 0.5);

    if (cards.isEmpty) {
      return [];
    }

    List<Offset> points = <Offset>[];
    Offset lastGap = Offset.zero;

    for (final card in cards) {
      points.add(lastGap);

      final Offset nextOffset;
      if (compressStack) {
        nextOffset = card.isFacingDown ? halfStack : stackGap;
      } else {
        nextOffset = stackGap;
      }
      // Only shift in one direction, either x or y
      if (stackDirection.dx != 0) {
        lastGap = lastGap.translate(nextOffset.dx, 0);
      } else if (stackDirection.dy != 0) {
        lastGap = lastGap.translate(0, nextOffset.dy);
      }
    }

    // If preview card is enabled, hide the non-preview cards under the stack
    if (previewCards != null &&
        previewCards > 0 &&
        points.length > previewCards) {
      final remainingHiddenCards = points.length - previewCards;
      final firstPoint = points[remainingHiddenCards];
      points = [
        ...Iterable.generate(remainingHiddenCards, (_) => Offset.zero),
        ...points.slice(remainingHiddenCards, points.length).map(
              (p) => p - firstPoint,
            )
      ];
    }

    // If shift stack is enable, move every card so the last card be placed on origin location
    // (instead of first card)
    if (shiftStack == true) {
      final lastPoint = points.last;
      points = points.map((p) => p - lastPoint).toList();
    }

    // Adjust spacing to fill in the parent region
    final consumedSpace = points.last;
    if (consumedSpace.dx > (region.width - 1) ||
        consumedSpace.dy > (region.height - 1)) {
      final ratioX =
          consumedSpace.dx > 0 ? consumedSpace.dx / (region.width - 1) : 1;
      final ratioY =
          consumedSpace.dy > 0 ? consumedSpace.dy / (region.height - 1) : 1;
      final adjustedPoints =
          points.map((p) => p.scale(1 / ratioX, 1 / ratioY)).toList();
      return adjustedPoints;
    } else {
      return points;
    }
  }

  Size _calculateConsumedTableSpace(BuildContext context) {
    var maxWidth = 0.0;
    var maxHeight = 0.0;

    for (final item in _allPiles.entries) {
      final layout = item.value.layout;
      final region = _resolvedRegion.get(item.key);

      final stackDirection =
          layout.stackDirection?.resolve(widget.orientation) ?? Direction.none;

      switch (stackDirection) {
        case Direction.none:
          maxWidth = max(maxWidth, region.right);
          maxHeight = max(maxHeight, region.bottom);
        case _:
          final stackPositions = _computeStackGapPositions(
            context: context,
            cards: widget.table.get(item.key),
            region: region,
            stackDirection: stackDirection,
            previewCards: layout.previewCards?.resolve(widget.orientation),
            shiftStack: layout.shiftStack?.resolve(widget.orientation),
          );
          final lastPoint = stackPositions.lastOrNull ?? Offset.zero;

          maxWidth = max(maxWidth, region.left + lastPoint.dx + 1);
          maxHeight = max(maxHeight, region.top + lastPoint.dy + 1);
      }
    }

    return Size(maxWidth, maxHeight);
  }

  void _onCardTouch(BuildContext context, PlayCard card, Pile originPile) {
    final cardsToPick = widget.table.get(originPile).getLastFromCard(card);

    if (widget.canDragCards?.call(cardsToPick, originPile) == true) {
      _touchingCards = cardsToPick;
      _touchingCardPile = originPile;
    }
  }

  void _onCardTap(BuildContext context, PlayCard card, Pile pile) {
    if (_allPiles.get(pile).virtual) {
      return;
    }

    final feedback = widget.onCardTap?.call(card, pile);
    if (feedback != null) {
      _shakeCard(feedback);
    }
  }

  void _onCardDrop(BuildContext context, PlayCard card, Pile from, Pile to) {
    if (_allPiles.get(to).virtual) {
      return;
    }

    final feedback = widget.onCardDrop?.call(card, from, to);
    if (feedback != null) {
      _shakeCard(feedback);
    }
  }

  void _onPileTap(BuildContext context, Pile pile) {
    if (_allPiles.get(pile).virtual) {
      return;
    }
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
    required this.stackDirection,
    required this.orientation,
    this.onTouch,
    this.onTap,
    this.highlightColor,
  });

  final bool shake;

  final bool isMoving;

  final PlayCard card;

  final PileLayout layout;

  final List<PlayCard> cardsInPile;

  final VoidCallback? onTouch;

  final VoidCallback? onTap;

  final Color? highlightColor;

  final Direction stackDirection;

  final Orientation orientation;

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

    if (stackDirection == Direction.none) {
      elevation =
          cardIndex > cardPileLength - 1 - cardShowThreshold ? minElevation : 0;
      hideFace = cardPileLength > cardShowThreshold &&
          cardPileLength - 1 - cardIndex - cardShowThreshold > 0;
    } else {
      final cardLimit = layout.previewCards?.resolve(orientation);
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
    final colorScheme = Theme.of(context).colorScheme;
    return FractionalTranslation(
      translation: const Offset(0, -0.7),
      child: Center(
        child: Shrinkable(
          show: count > 0,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: cardSize.shortestSide * 0.5,
            height: cardSize.shortestSide * 0.5,
            // margin: EdgeInsets.all(layout.cardPadding),
            decoration: BoxDecoration(
              color: colorScheme.inverseSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: TickingNumber(
              count,
              duration: cardMoveAnimation.duration * 1.5,
              curve: cardMoveAnimation.curve,
              style: TextStyle(
                color: colorScheme.onInverseSurface,
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
