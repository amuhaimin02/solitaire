import 'package:collection/collection.dart';

sealed class Pile {
  const Pile();
}

class Draw extends Pile {
  const Draw();

  @override
  String toString() => 'Draw';

  @override
  bool operator ==(Object other) => other is Draw;

  @override
  int get hashCode => 0;
}

class Discard extends Pile {
  const Discard();
  @override
  String toString() => 'Discard';

  @override
  bool operator ==(Object other) => other is Discard;

  @override
  int get hashCode => 0;
}

class Foundation extends Pile {
  final int index;

  const Foundation(this.index);

  @override
  bool operator ==(Object other) => other is Foundation && other.index == index;

  @override
  int get hashCode => Object.hash(index, null);

  @override
  String toString() => 'Foundation($index)';
}

class Tableau extends Pile {
  final int index;

  const Tableau(this.index);

  @override
  bool operator ==(Object other) => other is Tableau && other.index == index;

  @override
  int get hashCode => Object.hash(index, null);

  @override
  String toString() => 'Tableau($index)';
}

extension PileIteration<T extends Pile> on Iterable<T> {
  Iterable<T> roll({required Pile from}) {
    switch (T) {
      case const (Draw) || const (Discard):
        // Return as is as there is nothing to iterate
        return this;
      case const (Foundation) || const (Tableau):
        final sorted = switch (T) {
          const (Foundation) =>
            cast<Foundation>().sorted((a, b) => a.index - b.index),
          const (Tableau) =>
            cast<Tableau>().sorted((a, b) => a.index - b.index),
          _ => throw AssertionError('Should not happen'),
        };

        int startIndex = 0;
        if (from is T) {
          startIndex = sorted.indexOf(from);
        }

        final rollingIteration = [
          ...sorted.slice(startIndex, sorted.length),
          ...sorted.slice(0, startIndex),
        ].cast<T>();

        return rollingIteration;
      default:
        throw AssertionError('T is not a pile type');
    }
  }
}
