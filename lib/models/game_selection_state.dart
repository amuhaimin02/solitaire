import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'rules/klondike.dart';
import 'rules/rules.dart';
import 'rules/simple.dart';

class GameSelectionState with ChangeNotifier {
  static final allRules = [
    for (final scoring in KlondikeScoring.values)
      for (final draws in KlondikeDraws.values)
        Klondike(
          KlondikeVariant(draws: draws, scoring: scoring),
        ),
    SimpleSolitaire(),
  ];

  late final rulesCollection = _groupSelection(allRules);

  Map<String, List<SolitaireGame>> _groupSelection(
      List<SolitaireGame> rulesList) {
    return groupBy(rulesList, (rules) => rules.name);
  }

  late SolitaireGame _selectedRules = allRules.first;

  SolitaireGame get selectedRules => _selectedRules;

  set selectedRules(SolitaireGame newRules) {
    _selectedRules = newRules;
    notifyListeners();
  }

  bool _dropdownOpened = false;

  bool get dropdownOpened => _dropdownOpened;

  set dropdownOpened(bool value) {
    _dropdownOpened = value;
    notifyListeners();
  }

  List<SolitaireGame> get alternativeVariants {
    return rulesCollection[_selectedRules.name] ?? [];
  }
}
