import 'package:collection/collection.dart';

sealed class Pile {
  const Pile();
}

class Stock extends Pile {
  const Stock();

  @override
  String toString() => 'Stock';

  @override
  bool operator ==(Object other) => other is Stock;

  @override
  int get hashCode => 0;
}

class Waste extends Pile {
  const Waste();
  @override
  String toString() => 'Waste';

  @override
  bool operator ==(Object other) => other is Waste;

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

class Reserve extends Pile {
  final int index;

  const Reserve(this.index);

  @override
  bool operator ==(Object other) => other is Reserve && other.index == index;

  @override
  int get hashCode => Object.hash(index, null);

  @override
  String toString() => 'Reserve($index)';
}

extension PileIteration<T extends Pile> on Iterable<T> {
  Iterable<T> roll({required Pile from}) {
    switch (T) {
      case const (Stock) || const (Waste):
        // Return as is as there is nothing to iterate
        return this;
      case const (Foundation) || const (Tableau) || const (Reserve):
        final sorted = switch (T) {
          const (Foundation) =>
            cast<Foundation>().sorted((a, b) => a.index - b.index),
          const (Tableau) =>
            cast<Tableau>().sorted((a, b) => a.index - b.index),
          const (Reserve) =>
            cast<Reserve>().sorted((a, b) => a.index - b.index),
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
