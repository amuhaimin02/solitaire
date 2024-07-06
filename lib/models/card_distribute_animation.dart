import '../animations.dart';
import 'pile.dart';

// TODO: Find a better name
class CardDistributeAnimationDelay {
  const CardDistributeAnimationDelay();

  Duration compute(Pile pile, int cardIndex) {
    final delayFactor = cardMoveAnimation.duration * 0.25;

    if (pile is Grid) {
      final (x, y) = pile.xy;
      return delayFactor * (x + y);
    } else if (pile is Stock || pile is Waste) {
      return Duration.zero;
    } else {
      return delayFactor * (pile.index + cardIndex);
    }
  }
}
