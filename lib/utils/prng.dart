import 'dart:math';

import 'package:xrandom/xrandom.dart';

class CustomPRNG {
  static const charset = "ABCDEFGHJKLMNPQRTUVWXY23456789";

  static String generateSeed({required int length}) {
    final random = Xrandom();
    return Iterable.generate(
        length, (index) => charset[random.nextInt(charset.length)]).join();
  }

  static Random create(String seed) {
    return Xrandom(seed.hashCode);
  }
}
