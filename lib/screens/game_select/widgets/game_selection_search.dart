import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/game/solitaire.dart';
import '../../../providers/game_selection.dart';
import '../../../utils/types.dart';
import '../../../widgets/bottom_padded.dart';
import '../../../widgets/two_pane.dart';
import 'game_list_tile.dart';

class GameSelectionSearch extends ConsumerStatefulWidget {
  const GameSelectionSearch({
    super.key,
    required this.onCancel,
  });

  final VoidCallback onCancel;

  @override
  ConsumerState<GameSelectionSearch> createState() =>
      _GameSelectionSearchState();
}

class _GameSelectionSearchState extends ConsumerState<GameSelectionSearch> {
  late final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: widget.onCancel,
        ),
        title: TextField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: 'Search games...',
          ),
          autofocus: true,
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                setState(() => _textController.clear());
              } else {
                widget.onCancel();
              }
            },
            icon: const Icon(Icons.close),
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _textController,
        builder: (context, searchQuery, child) {
          if (searchQuery.text.isEmpty) {
            return Container();
          }

          final matchedGame = ref
              .read(allSolitaireGamesProvider)
              .where((game) => game.name.containsIgnoreCase(searchQuery.text))
              .toList();

          return ListView.builder(
            key: const PageStorageKey('search'),
            padding: BottomPadded.getPadding(context),
            itemCount: matchedGame.length,
            itemBuilder: (context, index) {
              final game = matchedGame[index];
              return GameListTile(
                game: game,
                onTap: () => _onListTap(context, ref, game),
              );
            },
          );
        },
      ),
    );
  }

  void _onListTap(BuildContext context, WidgetRef ref, SolitaireGame game) {
    ref.read(selectedGameProvider.notifier).select(game);
    TwoPane.of(context).pushSecondary();
  }
}