import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../animations.dart';
import '../models/card.dart';
import '../models/direction.dart';
import '../models/game_layout.dart';
import '../models/game_rules.dart';
import '../models/game_state.dart';
import 'card_marker.dart';
import 'card_view.dart';

class GameTable extends StatelessWidget {
  const GameTable({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final gameRules =
            context.select<GameState, GameRules>((s) => s.gameRules);

        const cardUnitSize = Size(2.5, 3.5);

        final options = TableLayoutOptions(
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

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final point = _convertToGrid(
                            details.localPosition, layout.gridUnit);

                        for (final item in tableLayout.items) {
                          if (item.region.contains(point)) {
                            _onPileTap(context, item.type);
                            break;
                          }
                        }
                      },
                      child: Stack(
                        children: [
                          for (final item in tableLayout.items)
                            ..._buildPile(context, item),
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

  List<Widget> _buildPile(BuildContext context, TableItem item) {
    final layout = context.watch<GameLayout>();
    final gameState = context.watch<GameState>();

    final gridUnit = layout.gridUnit;

    final region = item.region;

    Rect measure(Rect rect) => _measure(rect, gridUnit);

    Offset calculateStackGap(int index, int stackLength, Direction direction) {
      final int offset;

      if (item.shiftStackOnPlace) {
        offset = stackLength - index - 1;
      } else {
        offset = index;
      }

      return Offset(
        direction.dx != 0
            ? (offset *
                    direction.dx *
                    min(layout.maxStackGap.dx,
                        (region.width - 1) / (stackLength - 1)))
                .toDouble()
            : 0,
        direction.dy != 0
            ? (offset *
                    direction.dy *
                    min(layout.maxStackGap.dy,
                        (region.height - 1) / (stackLength - 1)))
                .toDouble()
            : 0,
      );
    }

    PlayCardList cards = gameState.pile(item.type);

    if (item.numberOfCardsToShow != null) {
      cards = cards
          .getRange(
              max(cards.length - item.numberOfCardsToShow!, 0), cards.length)
          .toList();
    }

    switch (item.stackDirection) {
      case Direction.none:
        return [
          Positioned.fromRect(
            rect: measure(Rect.fromLTWH(region.left, region.top, 1, 1)),
            child: _buildMarker(item),
          ),
          if (cards.isNotEmpty) ...[
            for (final (i, card) in cards.indexed)
              AnimatedPositioned.fromRect(
                key: ValueKey(card),
                duration: cardMoveAnimation.duration,
                curve: cardMoveAnimation.curve,
                rect: measure(Rect.fromLTWH(region.left, region.top, 1, 1)),
                child: CardView(
                  card: card,
                  elevation: i == cards.length - 1
                      ? cards.length.clamp(2, 24).toDouble()
                      : 0,
                ),
              ),
            if (item.showCountIndicator)
              Positioned.fromRect(
                rect: measure(Rect.fromLTWH(region.left, region.top, 1, 1)),
                child: CountIndicator(count: cards.length),
              ),
          ],
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
          Positioned.fromRect(
            rect: measure(markerLocation),
            child: _buildMarker(item),
          ),
          for (final (i, card) in cards.indexed)
            AnimatedPositioned.fromRect(
              key: ValueKey(card),
              duration: cardMoveAnimation.duration,
              curve: cardMoveAnimation.curve,
              rect: measure(
                Rect.fromLTWH(region.left, region.top, 1, 1)
                    .shift(stackAnchor)
                    .shift(calculateStackGap(
                        i, cards.length, item.stackDirection)),
              ),
              child: GestureDetector(
                onTap: () => _onCardTap(context, card, item.type),
                child: CardView(card: card),
              ),
            ),
        ];
    }
  }

  Widget _buildMarker(TableItem item) {
    return CardMarker(
      mark: switch (item) {
        DrawPileItem() => MdiIcons.refresh,
        DiscardPileItem() => MdiIcons.cardsPlaying,
        FoundationPileItem() => MdiIcons.circleOutline,
        TableauPileItem() => MdiIcons.close,
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

  void _onCardTap(BuildContext context, PlayCard card, CardLocation location) {
    print('card tap! $card at $location');

    final gameState = context.read<GameState>();

    switch (location) {
      case Tableau():
        _feedbackOnPlace(gameState.tryQuickPlace(card, location));
        return;
      case _:
      // noop
    }

    _onPileTap(context, location);
  }

  void _onPileTap(BuildContext context, CardLocation location) {
    print('pile tap! $location');

    final gameState = context.read<GameState>();

    switch (location) {
      case Draw():
        if (gameState.pile(location).isNotEmpty) {
          gameState.pickFromDrawPile();
          _feedbackOnPlace(Discard());

          Future.delayed(
            cardMoveAnimation.duration,
            () {
              _feedbackOnPlace(gameState.tryQuickPlace(
                  gameState.pile(Discard()).last, Discard()));
            },
          );
        } else {
          gameState.refreshDrawPile();
          _feedbackOnPlace(Draw());
        }
      case Discard():
        if (gameState.pile(location).isNotEmpty) {
          _feedbackOnPlace(
              gameState.tryQuickPlace(gameState.pile(location).last, location));
        }
      case Foundation():
        if (gameState.pile(location).isNotEmpty) {
          _feedbackOnPlace(
              gameState.tryQuickPlace(gameState.pile(location).last, location));
        }
      case _:
      // noop
    }
  }

  void _feedbackOnPlace(CardLocation? location) {
    switch (location) {
      case Discard():
        HapticFeedback.lightImpact();
      case Tableau():
        HapticFeedback.mediumImpact();
      case Draw() || Foundation():
        HapticFeedback.heavyImpact();
      case null:
      // noop
    }
  }
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

    return Align(
      alignment: const Alignment(0, -0.75),
      child: Container(
        padding: EdgeInsets.all(size * 0.15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: Text(
          count.toString(),
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}
