import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'rules/klondike.dart';
import 'rules/rules.dart';

class GameSelectionState with ChangeNotifier {
  static final allRules = [
    for (final scoring in KlondikeScoring.values)
      for (final draws in KlondikeDraws.values)
        Klondike(
          KlondikeVariant(draws: draws, scoring: scoring),
        ),
  ];

  late final rulesCollection = _groupSelection(allRules);

  Map<String, List<SolitaireRules>> _groupSelection(
      List<SolitaireRules> rulesList) {
    return groupBy(rulesList, (rules) => rules.name);
  }

  late SolitaireRules _selectedRules = allRules.first;

  SolitaireRules get selectedRules => _selectedRules;

  set selectedRules(SolitaireRules newRules) {
    _selectedRules = newRules;
    notifyListeners();
  }

  bool _dropdownOpened = false;

  bool get dropdownOpened => _dropdownOpened;

  set dropdownOpened(bool value) {
    _dropdownOpened = value;
    notifyListeners();
  }

  List<SolitaireRules> get alternativeVariants {
    return rulesCollection[_selectedRules.name] ?? [];
  }
}
