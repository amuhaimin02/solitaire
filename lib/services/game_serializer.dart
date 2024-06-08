import 'dart:convert';

import 'package:quiver/collection.dart';

import '../models/action.dart';
import '../models/card.dart';
import '../models/game/solitaire.dart';
import '../models/move_record.dart';
import '../models/pile.dart';
import '../models/play_data.dart';
import '../models/play_table.dart';
import '../models/serializer.dart';
import '../utils/types.dart';

const _maxRadixSize = 36;

class GameDataSerializer implements Serializer<GameData> {
  const GameDataSerializer({required this.resolveGameTag});

  final SolitaireGame Function(String tag) resolveGameTag;

  @override
  String serialize(GameData gameData) {
    final buffer = StringBuffer();
    buffer.writeln(GameMetadataSerializer(resolveGameTag: resolveGameTag)
        .serialize(gameData.metadata));
    buffer.writeln(const GameStateSerializer().serialize(gameData.state));
    buffer
        .writeln(const MoveRecordListSerializer().serialize(gameData.history));

    return buffer.toString();
  }

  @override
  GameData deserialize(String raw) {
    final lines = LineSplitter.split(raw).iterator;

    lines.moveNext();
    final metadata = GameMetadataSerializer(resolveGameTag: resolveGameTag)
        .deserialize(lines.current);
    lines.moveNext();
    final state = const GameStateSerializer().deserialize(lines.current);

    // TODO: This creates additional buffer, is there a better way?
    final buffer = StringBuffer();
    while (lines.moveNext()) {
      buffer.writeln(lines.current);
    }
    final history =
        const MoveRecordListSerializer().deserialize(buffer.toString());

    return GameData(
      metadata: metadata,
      state: state,
      history: history,
    );
  }
}

class GameMetadataSerializer implements Serializer<GameMetadata> {
  const GameMetadataSerializer({required this.resolveGameTag});

  final SolitaireGame Function(String tag) resolveGameTag;

  @override
  String serialize(GameMetadata metadata) {
    return '${metadata.game.tag}:${metadata.randomSeed}:${metadata.startedTime.millisecondsSinceEpoch}';
  }

  @override
  GameMetadata deserialize(String raw) {
    final [val1, val2, val3] = raw.split(':');
    final game = resolveGameTag(val1);
    final randomSeed = val2;
    final startedTime = DateTime.fromMillisecondsSinceEpoch(int.parse(val3));

    return GameMetadata(
      game: game,
      randomSeed: randomSeed,
      startedTime: startedTime,
    );
  }
}

class GameStateSerializer implements Serializer<GameState> {
  const GameStateSerializer();

  @override
  String serialize(GameState state) {
    return '${state.playTime.inMilliseconds}:${state.moveCursor}';
  }

  @override
  GameState deserialize(String raw) {
    final [val1, val2] = raw.split(':');
    final playTime = Duration(milliseconds: int.parse(val1));
    final moveCursor = int.parse(val2);

    return GameState(playTime: playTime, moveCursor: moveCursor);
  }
}

class MoveRecordListSerializer implements Serializer<List<MoveRecord>> {
  const MoveRecordListSerializer();

  @override
  String serialize(List<MoveRecord> records) {
    final buffer = StringBuffer();

    for (final record in records) {
      buffer.write('@');
      buffer.writeln(const ActionSerializer().serialize(record.action));
      buffer.writeln(const MoveStateSerializer().serialize(record.state));
      buffer.write(const PlayTableSerializer().serialize(record.table));
    }

    return buffer.toString();
  }

  @override
  List<MoveRecord> deserialize(String raw) {
    final moveParts = raw.split('@');

    // Skip first part as it will be empty from the split results
    return moveParts.skip(1).map((part) {
      final firstNewLine = part.indexOf('\n');
      final secondNewLine = part.indexOf('\n', firstNewLine + 1);
      final actionString = part.substring(0, firstNewLine);
      final stateString = part.substring(firstNewLine + 1, secondNewLine);
      final playTableString = part.substring(secondNewLine + 1);
      return MoveRecord(
        action: const ActionSerializer().deserialize(actionString),
        state: const MoveStateSerializer().deserialize(stateString),
        table: const PlayTableSerializer().deserialize(playTableString),
      );
    }).toList();
  }
}

class ActionSerializer implements Serializer<Action> {
  const ActionSerializer();

  @override
  String serialize(Action action) {
    switch (action) {
      case GameStart():
        return 'GS';
      case Move(:final cards, :final from, :final to):
        final fromString = const PileSerializer().serialize(from);
        final toString = const PileSerializer().serialize(to);
        final cardsString = const PlayCardListSerializer().serialize(cards);
        return 'MV:$fromString:$toString:$cardsString';
      case Deal(:final cards, :final pile):
        final pileString = const PileSerializer().serialize(pile);
        final cardsString = const PlayCardListSerializer().serialize(cards);
        return 'DL:$pileString:$cardsString';
      default:
        throw ArgumentError('Cannot save this action: $action');
    }
  }

  @override
  Action deserialize(String raw) {
    switch (raw.substring(0, 2)) {
      case 'GS':
        return const GameStart();
      case 'MV':
        final [_, from, to, cards] = raw.split(':');
        return Move(
          const PlayCardListSerializer().deserialize(cards),
          const PileSerializer().deserialize(from),
          const PileSerializer().deserialize(to),
        );
      case 'DL':
        final [_, pile, cards] = raw.split(':');
        return Deal(
          const PlayCardListSerializer().deserialize(cards),
          const PileSerializer().deserialize(pile),
        );
      default:
        throw ArgumentError('Invalid action token: $raw');
    }
  }
}

class MoveStateSerializer implements Serializer<MoveState> {
  const MoveStateSerializer();

  @override
  String serialize(MoveState state) {
    final recycleCountString = state.recycleCounts.entries.map(
      (item) {
        final pileString = const PileSerializer().serialize(item.key);
        final countString = item.value.toRadixString(_maxRadixSize);
        return '$pileString$countString';
      },
    ).join(',');

    return '${state.moveNumber}:${state.score}:$recycleCountString';
  }

  @override
  MoveState deserialize(String raw) {
    final [val1, val2, val3] = raw.split(':');

    final moveNumber = int.parse(val1);
    final score = int.parse(val2);

    final recycleCounts = <Pile, int>{};

    for (final item in val3.split(',')) {
      if (item.isNotEmpty) {
        final pile = const PileSerializer().deserialize(item.substring(0, 2));
        final count = int.parse(item.substring(2), radix: _maxRadixSize);
        recycleCounts[pile] = count;
      }
    }

    return MoveState(
      moveNumber: moveNumber,
      score: score,
      recycleCounts: recycleCounts,
    );
  }
}

class PlayTableSerializer implements Serializer<PlayTable> {
  const PlayTableSerializer();

  @override
  String serialize(PlayTable table) {
    final buffer = StringBuffer();

    for (final (pile, cards) in table.allCards.items) {
      buffer.write(const PileSerializer().serialize(pile));
      buffer.write(':');
      buffer.write(const PlayCardListSerializer().serialize(cards));
      buffer.write('\n');
    }

    return buffer.toString();
  }

  @override
  PlayTable deserialize(String raw) {
    final tableMap = <Pile, List<PlayCard>>{};
    final lines = LineSplitter.split(raw);

    for (final line in lines) {
      if (line.isEmpty) {
        continue;
      }
      final pile = const PileSerializer().deserialize(line.substring(0, 2));
      final cards =
          const PlayCardListSerializer().deserialize(line.substring(3));
      tableMap[pile] = cards;
    }
    return PlayTable.fromMap(tableMap);
  }
}

class PlayCardListSerializer implements Serializer<List<PlayCard>> {
  const PlayCardListSerializer();

  @override
  String serialize(List<PlayCard> cards) {
    final buffer = StringBuffer();
    for (final card in cards) {
      buffer.write(const PlayCardSerializer().serialize(card));
    }

    return buffer.toString();
  }

  @override
  List<PlayCard> deserialize(String raw) {
    return raw
        .chunk(4)
        .map((chunk) => const PlayCardSerializer().deserialize(chunk))
        .toList();
  }
}

class PileSerializer implements Serializer<Pile> {
  const PileSerializer();

  @override
  String serialize(Pile pile) {
    return switch (pile) {
      Stock() => 'S0',
      Waste() => 'W0',
      Foundation(:final index) => 'F$index',
      Tableau(:final index) => 'T$index',
      Reserve(:final index) => 'R$index'
    };
  }

  @override
  Pile deserialize(String raw) {
    assert(raw.length == 2, 'pile token must be exactly 2 characters');
    final type = raw[0];
    final index = int.parse(raw[1], radix: _maxRadixSize);
    return switch (type) {
      'S' => const Stock(),
      'W' => const Waste(),
      'F' => Foundation(index),
      'T' => Tableau(index),
      'R' => Reserve(index),
      _ => throw ArgumentError('unknown pile token: $raw')
    };
  }
}

class PlayCardSerializer implements Serializer<PlayCard> {
  static final _playCardSuitSymbols = BiMap<Suit, String>()
    ..addAll({
      Suit.diamond: 'D',
      Suit.club: 'C',
      Suit.heart: 'H',
      Suit.spade: 'S',
    });

  static final _playCardRankSymbols = BiMap<Rank, String>()
    ..addAll({
      Rank.ace: 'A',
      Rank.two: '2',
      Rank.three: '3',
      Rank.four: '4',
      Rank.five: '5',
      Rank.six: '6',
      Rank.seven: '7',
      Rank.eight: '8',
      Rank.nine: '9',
      Rank.ten: 'T',
      Rank.jack: 'J',
      Rank.queen: 'Q',
      Rank.king: 'K',
    });

  const PlayCardSerializer();

  @override
  String serialize(PlayCard card) {
    final buffer = StringBuffer();

    buffer.write(_playCardRankSymbols[card.rank]);
    buffer.write(_playCardSuitSymbols[card.suit]);

    final deck = card.deck;
    if (deck >= _maxRadixSize) {
      throw ArgumentError(
          'Cannot store deck number greater than $_maxRadixSize');
    }
    buffer.write(deck.toRadixString(_maxRadixSize));
    buffer.write(card.flipped ? '-' : '+');

    return buffer.toString();
  }

  @override
  PlayCard deserialize(String raw) {
    assert(raw.length == 4, 'card token must be exactly 4 characters');
    return PlayCard(
      // Rank comes before suit
      _playCardSuitSymbols.inverse[raw[1]]!,
      _playCardRankSymbols.inverse[raw[0]]!,
      deck: int.parse(raw[2], radix: _maxRadixSize),
      flipped: switch (raw[3]) {
        '-' => true,
        '+' => false,
        _ => throw ArgumentError('unknown card token: $raw')
      },
    );
  }
}
