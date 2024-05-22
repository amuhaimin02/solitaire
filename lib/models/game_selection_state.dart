import 'package:flutter/foundation.dart';

import 'rules/klondike.dart';
import 'rules/rules.dart';

class GameSelectionState with ChangeNotifier {
  late SolitaireRules rules;

  late SolitaireVariant? variant;

  GameSelectionState() {
    rules = Klondike();
    variant = KlondikeVariant.defaultVariant;
  }

  void setRules(SolitaireRules rules) {
    this.rules = rules;
    variant = rules.variant;
    notifyListeners();
  }

  void setVariant(SolitaireVariant variant) {
    this.variant = variant;
    notifyListeners();
  }
}
