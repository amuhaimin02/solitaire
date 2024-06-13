import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter/scheduler.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../animations.dart';
import '../../../config.dart';
import '../../../models/card.dart';
import '../../../models/card_list.dart';
import '../../../models/direction.dart';
import '../../../models/game/solitaire.dart';
import '../../../models/game_theme.dart';
import '../../../models/move_check.dart';
import '../../../models/move_record.dart';
import '../../../models/pile.dart';
import '../../../models/pile_property.dart';
import '../../../models/play_table.dart';
import '../../../utils/types.dart';
import '../../../widgets/shakeable.dart';
import '../../../widgets/shrinkable.dart';
import '../../../widgets/ticking_number.dart';
import 'card_view.dart';

// Relation of touch points to position of the card.
// (0.5, 0.5) indicates touch point at card center
const cardTouchOffset = Offset(0.5, 0.8);

class GameTable extends StatefulWidget {
  const GameTable({
    super.key,
    required this.game,
    required this.table,
    this.interactive = true,
    this.onCardTap,
    this.onCardDrop,
    this.canDragCards,
    this.highlightedCards,
    this.lastMovedCards,
    this.animateDistribute = false,
    this.animateMovement = true,
    this.fitEmptySpaces = false,
    this.orientation = Orientation.portrait,
    this.currentMoveState,
  });

  final SolitaireGame game;

  final List<PlayCard>? Function(PlayCard? card, Pile pile)? onCardTap;

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

  final MoveState? currentMoveState;

  @override
  State<GameTable> createState() => _GameTableState();
}

class _GameTableState extends State<GameTable> {
  List<PlayCard>? _shakingCards;
  List<PlayCard>? _touchingCards;
  Pile? _touchingPile;

  Timer? _touchDragTimer, _shakeCardTimer;

  bool _isDragging = false;
  bool _isDropping = false;

  Offset? _dropTouchPoint;

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

  Map<Pile, PileProperty> get _allPiles => widget.game.setup;

  void _resolvePiles() {
    _resolvedRegion = _allPiles.map((pile, prop) =>
        MapEntry(pile, prop.layout.region.resolve(widget.orientation)));
  }

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).gameCardTheme;

    final Size tableSize;

    if (widget.fitEmptySpaces) {
      tableSize = _calculateConsumedTableSpace(context);
    } else {
      tableSize = widget.game.tableSize.resolve(widget.orientation);
    }

    return IgnorePointer(
      ignoring: !widget.interactive,
      child: AspectRatio(
        aspectRatio: (tableSize.width * cardTheme.unitSize.width) /
            (tableSize.height * cardTheme.unitSize.height),
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
                _buildOverlayLayer(context, gridUnit),
                _buildCardDragOverlay(context, gridUnit),
                if (debugHighlightPileRegion)
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

    bool canRecycle(Pile pile, PileProperty props) {
      final canRecyclePile = props.canTap?.findRule<CanRecyclePile>();

      final recycleLimit = canRecyclePile?.limit;
      final currentCycle = widget.currentMoveState?.recycleCounts[pile] ?? 0;

      return recycleLimit != null && currentCycle + 1 < recycleLimit;
    }

    Rank? buildRankStartingMarker(Pile pile, PileProperty props) {
      final rule = props.placeable.findRule<BuildupStartsWith>();

      if (rule != null) {
        if (rule.isRelative) {
          final refPile = rule.referencePiles
              ?.firstWhereOrNull((p) => widget.table.get(p).isNotEmpty);
          if (refPile != null) {
            final cardsInRefPile = widget.table.get(refPile);
            return cardsInRefPile.first.rank.next(
              gap: rule.rankDifference,
              wrapping: rule.wrapping,
            );
          } else {
            return null;
          }
        } else {
          return rule.rank;
        }
      } else {
        return null;
      }
    }

    return Stack(
      children: [
        for (final (pile, props) in _allPiles.items)
          if (!props.virtual &&
              props.layout.showMarker?.resolve(widget.orientation) != false)
            Positioned.fromRect(
              rect: computeMarkerPlacement(pile).scale(gridUnit),
              child: GestureDetector(
                onTap: () {
                  if (widget.table.get(pile).isEmpty) {
                    _onCardTap(context, null, pile);
                  }
                },
                child: _PileMarker(
                  pile: pile,
                  startsWith: buildRankStartingMarker(pile, props),
                  canRecycle: canRecycle(pile, props),
                  size: gridUnit,
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildDebugLayer(BuildContext context, Size gridUnit) {
    final tableSize = widget.game.tableSize.resolve(widget.orientation);
    return IgnorePointer(
      ignoring: true,
      child: Stack(
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
          for (final pile in _allPiles.keys)
            Positioned.fromRect(
              rect: _resolvedRegion.get(pile).scale(gridUnit),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.yellow,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardLayer(BuildContext context, Size gridUnit) {
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
          if (!_isDragging) {
            touchedWidgets.add(w);
          }
        } else if (widget.lastMovedCards?.contains(card) == true) {
          recentlyMovedWidgets.add(w);
        } else {
          remainingWidgets.add(w);
        }
      }

      return [...remainingWidgets, ...recentlyMovedWidgets, ...touchedWidgets];
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ...sortCardWidgets(
          [
            for (final pile in _allPiles.keys)
              ..._buildPile(context, gridUnit, pile),
          ],
        ),
      ],
    );
  }

  Widget _buildOverlayLayer(BuildContext context, Size gridUnit) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (pile, props) in _allPiles.items) ...[
          if (props.layout.showCount?.resolve(widget.orientation) == true)
            Positioned.fromRect(
              rect: Rect.fromLTWH(_resolvedRegion.get(pile).left,
                      _resolvedRegion.get(pile).top, 1, 1)
                  .scale(gridUnit),
              child: _CardCountIndicator(
                count: widget.table.get(pile).length,
                size: gridUnit,
              ),
            ),
          () {
            final recycleLimit =
                props.canTap?.findRule<CanRecyclePile>()?.limit;

            if (recycleLimit != null && recycleLimit != intMaxValue) {
              return Positioned.fromRect(
                rect: Rect.fromLTWH(_resolvedRegion.get(pile).left,
                        _resolvedRegion.get(pile).top, 1, 1)
                    .scale(gridUnit),
                child: _PileCycleIndicator(
                  cycleCount:
                      ((widget.currentMoveState?.recycleCounts[pile] ?? 0) + 1),
                  cycleLimit: recycleLimit,
                  size: gridUnit,
                ),
              );
            } else {
              return const SizedBox();
            }
          }()
        ],
      ],
    );
  }

  Widget _buildCardDragOverlay(BuildContext context, Size gridUnit) {
    return _CardDragOverlay(
        gridUnit: gridUnit,
        draggedCards: _touchingCards,
        onDrag: (touchPoint) {
          _touchDragTimer?.cancel();

          setState(() {
            _isDragging = true;
          });
        },
        onDrop: (touchPoint) {
          setState(() {
            _isDragging = false;
            _isDropping = true;
            _dropTouchPoint = touchPoint;
          });
          final point = _convertToGrid(touchPoint, gridUnit);

          // Find pile belonging to the region, also ignore virtual ones
          final dropPile = _allPiles.keys.firstWhereOrNull(
            (pile) =>
                !_allPiles.get(pile).virtual &&
                _resolvedRegion.get(pile).contains(point),
          );

          if (dropPile != null) {
            if (_touchingCards != null &&
                _touchingPile != null &&
                _touchingPile != dropPile) {
              _onCardDrop(
                  context, _touchingCards!.first, _touchingPile!, dropPile);
            }
          }

          // Wait for previous setState to finish
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _isDropping = false;
            });

            // Wait for animation to finish, this ensures cards returning to original place are still rendered on top
            _touchDragTimer =
                Timer(cardMoveAnimation.duration * 1.5 * timeDilation, () {
              setState(() {
                _touchingCards = null;
              });
            });
          });
        },
        onLift: () {
          setState(() {
            _touchingCards = null;
          });
        });
  }

  List<Widget> _buildPile(BuildContext context, Size gridUnit, Pile pile) {
    final layout = _allPiles.get(pile).layout;
    final region = _resolvedRegion.get(pile);
    final stackDirection =
        layout.stackDirection?.resolve(widget.orientation) ?? Direction.none;

    Rect computePosition(PlayCard card, Rect originalPosition) {
      if (_isDropping && _touchingCards != null) {
        final dropCardIndex = _touchingCards!.indexOf(card);
        if (dropCardIndex >= 0) {
          return (const Rect.fromLTWH(0, 0, 1, 1)
                  .translate(0, dropCardIndex * 0.3)
                  .translate(-cardTouchOffset.dx, -cardTouchOffset.dy))
              .scale(gridUnit)
              .translate(_dropTouchPoint!.dx, _dropTouchPoint!.dy);
        }
      }
      return originalPosition.scale(gridUnit);
      // }
    }

    List<PlayCard> cards = [];

    cards = widget.table.get(pile);

    DurationCurve computeAnimation(int cardIndex) {
      if (!widget.animateMovement) {
        return DurationCurve.zero;
      }

      if (widget.animateDistribute) {
        final delayFactor = cardMoveAnimation.duration * 0.25;

        if ((pile is Tableau || pile is Reserve)) {
          return cardMoveAnimation
              .delayed(delayFactor * (pile.index + cardIndex));
        } else if (pile is Grid) {
          final (x, y) = pile.xy;
          return cardMoveAnimation.delayed(delayFactor * (x + y));
        }
      }
      return cardMoveAnimation;
    }

    Color? highlightCardColor(PlayCard card) {
      if (widget.highlightedCards?.contains(card) == true) {
        return Theme.of(context).gameTheme.hintHighlightColor;
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
                  onTouch: () => _onCardTouch(context, card, pile),
                  onTap: () => _onCardTap(context, card, pile),
                  card: card,
                  stackDirection: stackDirection,
                  isFirstCard: i == 0,
                  isLastCard: i == cards.length - 1,
                  highlightColor: highlightCardColor(card),
                  hasShadow: i < 3, // Bottom 3 card will have shadow
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
                    .shift(stackGapPositions[i]),
              ),
              child: _CardWidget(
                cardSize: gridUnit,
                shake: _shakingCards?.contains(card) == true,
                onTouch: () => _onCardTouch(context, card, pile),
                onTap: () => _onCardTap(context, card, pile),
                card: card,
                stackDirection: stackDirection,
                isFirstCard: i == 0,
                isLastCard: i == cards.length - 1,
                highlightColor: highlightCardColor(card),
                hasShadow: previewCards != 0
                    // Only visible cards have shadow
                    ? i >= cards.length - 1 - previewCards
                    // All cards have shadow
                    : true,
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
    final cardTheme = Theme.of(context).gameCardTheme;
    final stackGap = cardTheme.stackGap;
    final compressStack = cardTheme.compressStack;

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

    for (final (pile, props) in _allPiles.items) {
      final layout = props.layout;
      final region = _resolvedRegion.get(pile);

      final stackDirection =
          layout.stackDirection?.resolve(widget.orientation) ?? Direction.none;

      switch (stackDirection) {
        case Direction.none:
          maxWidth = max(maxWidth, region.right);
          maxHeight = max(maxHeight, region.bottom);
        case _:
          final stackPositions = _computeStackGapPositions(
            context: context,
            cards: widget.table.get(pile),
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

    _touchingCards = null;
    if (widget.canDragCards?.call(cardsToPick, originPile) == true) {
      setState(() {
        _touchingCards = cardsToPick;
        _touchingPile = originPile;
      });
    }
  }

  void _onCardTap(BuildContext context, PlayCard? card, Pile pile) {
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
    required this.card,
    required this.isFirstCard,
    required this.isLastCard,
    required this.stackDirection,
    required this.hasShadow,
    this.isMoving = false,
    this.shake = false,
    this.onTouch,
    this.onTap,
    this.highlightColor,
  });

  final bool shake;

  final bool isMoving;

  final bool isFirstCard;

  final bool isLastCard;

  final bool hasShadow;

  final PlayCard card;

  final VoidCallback? onTouch;

  final VoidCallback? onTap;

  final Color? highlightColor;

  final Direction stackDirection;

  final Size cardSize;

  static const minElevation = 2.0;
  static const hoverElevation = 32.0;

  @override
  Widget build(BuildContext context) {
    final double elevation;
    final Alignment labelAlignment;

    elevation = hasShadow ? minElevation : 0;

    if (stackDirection == Direction.none) {
      labelAlignment = Alignment.center;
    } else {
      if (!isLastCard) {
        labelAlignment = switch (stackDirection) {
          Direction.up => Alignment.bottomCenter,
          Direction.down => Alignment.topCenter,
          Direction.left => Alignment.centerLeft,
          Direction.right => Alignment.centerRight,
          // TODO: Handle shift stack
          _ => Alignment.center,
        };
      } else {
        labelAlignment = Alignment.center;
      }
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
          highlightColor: highlightColor,
          labelAlignment: labelAlignment,
        ),
      ),
    );
  }
}

class _CardCountIndicator extends StatelessWidget {
  const _CardCountIndicator({
    super.key,
    required this.count,
    required this.size,
  });

  final int count;

  final Size size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FractionalTranslation(
      translation: const Offset(0, -1),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Shrinkable(
          show: count > 0,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: size.shortestSide * 0.5,
            height: size.shortestSide * 0.5,
            decoration: BoxDecoration(
              color: colorScheme.inverseSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: TickingNumber(
                count,
                duration: cardMoveAnimation.duration * 1.5,
                curve: cardMoveAnimation.curve,
                style: TextStyle(
                  color: colorScheme.onInverseSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: size.shortestSide * 0.25,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PileCycleIndicator extends StatelessWidget {
  const _PileCycleIndicator({
    super.key,
    required this.cycleCount,
    required this.cycleLimit,
    required this.size,
  });

  final int cycleCount;
  final int cycleLimit;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FractionalTranslation(
      translation: const Offset(0, 1),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          decoration: ShapeDecoration(
            color: colorScheme.secondaryContainer,
            shape: const StadiumBorder(),
          ),
          padding: EdgeInsets.all(size.shortestSide * 0.1),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$cycleCount / $cycleLimit',
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: size.shortestSide * 0.2,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PileMarker extends StatelessWidget {
  const _PileMarker({
    super.key,
    required this.pile,
    required this.startsWith,
    required this.canRecycle,
    required this.size,
  });

  final Pile pile;

  final Rank? startsWith;

  final bool? canRecycle;

  final Size size;

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).gameCardTheme;

    final borderOnly =
        Theme.of(context).gameTheme.tableBackgroundColor == Colors.black;

    final colorScheme = Theme.of(context).colorScheme;

    IconData getStockIcon() {
      if (canRecycle == null) {
        throw ArgumentError(
            'Stock pile must have canRecycle property for pile marker');
      }
      return canRecycle == true ? MdiIcons.refresh : Icons.block;
    }

    IconData getFoundationIcon() {
      return switch (startsWith) {
        Rank.ace => MdiIcons.alphaACircle,
        Rank.two => MdiIcons.numeric2Circle,
        Rank.three => MdiIcons.numeric3Circle,
        Rank.four => MdiIcons.numeric4Circle,
        Rank.five => MdiIcons.numeric5Circle,
        Rank.six => MdiIcons.numeric6Circle,
        Rank.seven => MdiIcons.numeric7Circle,
        Rank.eight => MdiIcons.numeric8Circle,
        Rank.nine => MdiIcons.numeric9Circle,
        Rank.ten => MdiIcons.numeric10Circle,
        Rank.jack => MdiIcons.alphaJCircle,
        Rank.queen => MdiIcons.alphaQCircle,
        Rank.king => MdiIcons.alphaKCircle,
        null => MdiIcons.starCircle,
      };
    }

    IconData getTableauIcon() {
      return switch (startsWith) {
        Rank.ace => MdiIcons.alphaABox,
        Rank.two => MdiIcons.numeric2Box,
        Rank.three => MdiIcons.numeric3Box,
        Rank.four => MdiIcons.numeric4Box,
        Rank.five => MdiIcons.numeric5Box,
        Rank.six => MdiIcons.numeric6Box,
        Rank.seven => MdiIcons.numeric7Box,
        Rank.eight => MdiIcons.numeric8Box,
        Rank.nine => MdiIcons.numeric9Box,
        Rank.ten => MdiIcons.numeric10Box,
        Rank.jack => MdiIcons.alphaJBox,
        Rank.queen => MdiIcons.alphaQBox,
        Rank.king => MdiIcons.alphaKBox,
        null => MdiIcons.starBox,
      };
    }

    final icon = switch (pile) {
      Stock() => getStockIcon(),
      Waste() => MdiIcons.cardsPlaying,
      Foundation() => getFoundationIcon(),
      Tableau() => getTableauIcon(),
      Reserve() => MdiIcons.circleOutline,
      Grid() => null,
    };

    return Container(
      padding: EdgeInsets.all(size.shortestSide * cardTheme.margin),
      child: Container(
        decoration: BoxDecoration(
          color: borderOnly ? null : colorScheme.onSurface.withOpacity(0.12),
          borderRadius:
              BorderRadius.circular(size.shortestSide * cardTheme.cornerRadius),
          border: borderOnly
              ? Border.all(
                  color: colorScheme.onSurface.withOpacity(0.24),
                  width: 2,
                )
              : null,
        ),
        child: Icon(
          icon,
          size: size.shortestSide * 0.5,
          color: colorScheme.onSurface.withOpacity(0.24),
        ),
      ),
    );
  }
}

class _CardDragOverlay extends StatefulWidget {
  const _CardDragOverlay({
    super.key,
    this.draggedCards,
    required this.gridUnit,
    required this.onDrag,
    required this.onDrop,
    required this.onLift,
  });

  final List<PlayCard>? draggedCards;

  final Size gridUnit;

  final void Function(Offset touchPoint) onDrag;

  final void Function(Offset touchPoint) onDrop;

  final void Function() onLift;

  @override
  State<_CardDragOverlay> createState() => _CardDragOverlayState();
}

class _CardDragOverlayState extends State<_CardDragOverlay> {
  bool _dragging = false;

  Offset? _touchPoint, _startTouchPoint;

  static const dragThresholdDistanceSquared = 600;

  @override
  Widget build(BuildContext context) {
    void onPointerStop(Offset position) {
      if (_dragging) {
        setState(() {
          _dragging = false;
        });
        widget.onDrop(position);
      } else {
        widget.onLift();
      }
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _startTouchPoint = event.localPosition;
      },
      onPointerMove: (event) {
        if (!_dragging &&
            (event.localPosition - _startTouchPoint!).distanceSquared >
                dragThresholdDistanceSquared) {
          setState(() {
            _dragging = true;
          });
          widget.onDrag(event.localPosition);
        }

        if (_dragging) {
          setState(() {
            _touchPoint = event.localPosition;
          });
        }
      },
      onPointerUp: (event) => onPointerStop(event.localPosition),
      onPointerCancel: (event) => onPointerStop(event.localPosition),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_dragging && _touchPoint != null && widget.draggedCards != null)
            for (final (i, card) in widget.draggedCards!.indexed)
              Positioned.fromRect(
                rect: (const Rect.fromLTWH(0, 0, 1, 1)
                        .translate(0, i * 0.3)
                        .translate(-cardTouchOffset.dx, -cardTouchOffset.dy))
                    .scale(widget.gridUnit)
                    .translate(_touchPoint!.dx, _touchPoint!.dy),
                child: _CardWidget(
                  card: card,
                  cardSize: widget.gridUnit,
                  isMoving: true,
                  stackDirection: Direction.down,
                  isFirstCard: i == 0,
                  isLastCard: i == widget.draggedCards!.length - 1,
                  hasShadow: true,
                ),
              )
        ],
      ),
    );
  }
}
