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
        PlayCard(Suit.spade, Rank.jack),
        PlayCard(Suit.club, Rank.jack),
      ]).allFaceDown,
      const Waste(0): PlayCardList(const [
        PlayCard(Suit.heart, Rank.jack),
        PlayCard(Suit.diamond, Rank.jack),
        PlayCard(Suit.diamond, Rank.queen),
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
        PlayCard(Suit.heart, Rank.king),
        PlayCard(Suit.spade, Rank.queen)
      ]),
      const Tableau(1): PlayCardList(const [
        PlayCard(Suit.spade, Rank.king),
        PlayCard(Suit.heart, Rank.queen)
      ]),
      const Tableau(2): PlayCardList(const [
        PlayCard(Suit.diamond, Rank.king),
        PlayCard(Suit.club, Rank.queen),
      ]),
      const Tableau(3): PlayCardList(const [
        PlayCard(Suit.club, Rank.king),
      ]),
    });

    // TODO: Change action
    ref.read(moveHistoryProvider.notifier).add(presetCards, const GameStart());
  }
}
