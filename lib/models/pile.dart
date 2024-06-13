import 'package:collection/collection.dart';

sealed class Pile {
  final String name;
  final int index;

  const Pile(this.name, this.index);

  @override
  String toString() => '$name($index)';

  @override
  bool operator ==(Object other) =>
      other is Pile && name == other.name && index == other.index;

  @override
  int get hashCode => Object.hash(name, index);
}

class Stock extends Pile {
  const Stock(int index) : super('Stock', index);
}

class Waste extends Pile {
  const Waste(int index) : super('Waste', index);
}

class Foundation extends Pile {
  const Foundation(int index) : super('Foundation', index);
}

class Tableau extends Pile {
  const Tableau(int index) : super('Tableau', index);
}

class Reserve extends Pile {
  const Reserve(int index) : super('Reserve', index);
}

class Grid extends Pile {
  const Grid(int x, int y) : super('Grid', x << 4 | y);

  const Grid.fromIndex(int index) : super('Grid', index);

  (int x, int y) get xy => (index >> 4, index & 0xF);

  @override
  String toString() => '$name$xy';
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
          _ => throw AssertionError(),
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
