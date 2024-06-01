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
import '../models/pile_info.dart';
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

  @override
  State<GameTable> createState() => _GameTableState();
}

class _GameTableState extends State<GameTable> {
  List<PlayCard>? _shakingCards;
  List<PlayCard>? _touchingCards;
  Pile? _touchingCardPile;

  Offset? _lastTouchPoint;

  Timer? _touchDragTimer, _shakeCardTimer;

  late List<Pile> _piles;
  late Map<Pile, Rect> _resolvedRegion;
  late Map<Pile, PileLayout> _layoutMap;

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

  void _resolvePiles() {
    _piles = widget.game.piles.map((p) => p.kind).toList();
    _resolvedRegion = {
      for (final pile in widget.game.piles)
        pile.kind: pile.layout.region.resolve(widget.orientation),
    };
    _layoutMap = {
      for (final pile in widget.game.piles) pile.kind: pile.layout,
    };
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
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMarkerLayer(BuildContext context, Size gridUnit) {
    Rect computeMarkerPlacement(Pile pile) {
      final layout = _layoutMap[pile]!;
      final region = _resolvedRegion[pile]!;
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
        for (final pile in _piles)
          Positioned.fromRect(
            rect: computeMarkerPlacement(pile).scale(gridUnit),
            child: PileMarker(
              pile: pile,
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

      final dropPile = _piles
          .firstWhereOrNull((pile) => _resolvedRegion[pile]!.contains(point));

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
              for (final pile in _piles) ..._buildPile(context, gridUnit, pile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayLayer(BuildContext context, Size gridUnit) {
    return Stack(
      children: [
        for (final pile in _piles)
          if (_layoutMap[pile]?.showCount?.resolve(widget.orientation) == true)
            Positioned.fromRect(
              rect: Rect.fromLTWH(_resolvedRegion[pile]!.left,
                      _resolvedRegion[pile]!.top, 1, 1)
                  .scale(gridUnit),
              child: _CountIndicator(
                count: widget.table.get(pile).length,
                cardSize: gridUnit,
              ),
            ),
      ],
    );
  }

  Size _calculateConsumedTableSpace(BuildContext context) {
    var maxWidth = 0.0;
    var maxHeight = 0.0;

    final theme = SolitaireTheme.of(context);

    for (final pile in _piles) {
      final layout = _layoutMap[pile]!;
      final region = _resolvedRegion[pile]!;

      final stackDirection =
          layout.stackDirection?.resolve(widget.orientation) ?? Direction.none;

      switch (stackDirection) {
        case Direction.down:
          maxWidth = max(maxWidth, region.right);
          maxHeight = max(
            maxHeight,
            region.top +
                1 +
                widget.table.get(pile).length * theme.cardTheme.stackGap.dy,
          );
        case Direction.none:
        default:
          maxWidth = max(maxWidth, region.right);
          maxHeight = max(maxHeight, region.bottom);
      }
    }

    return Size(maxWidth, maxHeight);
  }

  List<Widget> _buildPile(BuildContext context, Size gridUnit, Pile pile) {
    final theme = SolitaireTheme.of(context);

    final layout = _layoutMap[pile]!;
    final region = _resolvedRegion[pile]!;
    final stackDirection =
        layout.stackDirection?.resolve(widget.orientation) ?? Direction.none;

    Rect measure(Rect gridRect) {
      return Rect.fromLTWH(
        gridRect.left * gridUnit.width,
        gridRect.top * gridUnit.height,
        gridRect.width * gridUnit.width,
        gridRect.height * gridUnit.height,
      );
    }

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
      final shiftStack =
          layout.shiftStack?.resolve(widget.orientation) ?? false;
      final previewCards =
          layout.previewCards?.resolve(widget.orientation) ?? 0;

      if (layout.previewCards != null) {
        visualLength = previewCards;
        if (stackLength > visualLength) {
          visualIndex = max(0, previewCards - (stackLength - index));
        } else {
          if (shiftStack) {
            visualIndex = visualLength - (stackLength - index);
          } else {
            visualIndex = index;
          }
        }
      } else {
        visualLength = stackLength;
        visualIndex = index;
      }

      if (shiftStack) {
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

    cards = widget.table.get(pile);

    DurationCurve computeAnimation(int cardIndex) {
      if (!widget.animateMovement) {
        return DurationCurve.zero;
      } else if (_lastTouchPoint != null) {
        return cardDragAnimation;
      } else if (widget.animateDistribute && pile is Tableau) {
        final tableau = pile;
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
                    .shift(calculateStackGap(i, cards.length, stackDirection)),
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

  void _onCardTouch(BuildContext context, PlayCard card, Pile originPile) {
    final cardsToPick = widget.table.get(originPile).getLastFromCard(card);

    if (widget.canDragCards?.call(cardsToPick, originPile) == true) {
      _touchingCards = cardsToPick;
      _touchingCardPile = originPile;
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
