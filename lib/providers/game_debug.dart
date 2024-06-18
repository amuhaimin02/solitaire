import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/action.dart';
import '../models/card.dart';
import '../models/card_list.dart';
import '../models/game/impl/klondike.dart';
import '../models/pile.dart';
import '../models/play_table.dart';
import '../services/all.dart';
import '../services/play_card_generator.dart';
import 'game_logic.dart';
import 'game_move_history.dart';

part 'game_debug.g.dart';

@riverpod
class GameDebug extends _$GameDebug {
  @override
  void build() {
    return;
  }

  void debugTestCustomLayout() {
    final game = ref.read(currentGameProvider);

    if (game.kind is! Klondike) {
      return;
    }
    final generator = services<PlayCardGenerator>();

    final presetCards = PlayTable.fromMap({
      const Stock(0): PlayCardList(const [
        PlayCard(
          Rank.jack,
          Suit.spade,
        ),
        PlayCard(
          Rank.jack,
          Suit.club,
        ),
      ]).allFaceDown,
      const Waste(0): PlayCardList(const [
        PlayCard(
          Rank.jack,
          Suit.heart,
        ),
        PlayCard(
          Rank.jack,
          Suit.diamond,
        ),
        PlayCard(
          Rank.queen,
          Suit.diamond,
        ),
      ]),
      const Foundation(0):
          generator.generateOrderedSuit(Suit.diamond, to: Rank.ten),
      const Foundation(1):
          generator.generateOrderedSuit(Suit.club, to: Rank.ten),
      const Foundation(2):
          generator.generateOrderedSuit(Suit.heart, to: Rank.ten),
      const Foundation(3):
          generator.generateOrderedSuit(Suit.spade, to: Rank.ten),
      const Tableau(0): PlayCardList(const [
        PlayCard(Rank.king, Suit.heart),
        PlayCard(Rank.queen, Suit.spade)
      ]),
      const Tableau(1): PlayCardList(const [
        PlayCard(Rank.king, Suit.spade),
        PlayCard(Rank.queen, Suit.heart)
      ]),
      const Tableau(2): PlayCardList(const [
        PlayCard(Rank.king, Suit.diamond),
        PlayCard(Rank.queen, Suit.club),
      ]),
      const Tableau(3): PlayCardList(const [
        PlayCard(Rank.king, Suit.club),
      ]),
    });

    // TODO: Change action
    ref.read(moveHistoryProvider.notifier).add(presetCards, const GameStart());
  }
}
