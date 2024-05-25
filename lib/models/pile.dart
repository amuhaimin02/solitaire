sealed class Pile {
  const Pile();
}

class Draw extends Pile {
  const Draw();

  @override
  String toString() => "Draw";

  @override
  bool operator ==(Object other) => other is Draw;

  @override
  int get hashCode => 0;
}

class Discard extends Pile {
  const Discard();
  @override
  String toString() => "Discard";

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
  String toString() => "Foundation($index)";
}

class Tableau extends Pile {
  final int index;

  const Tableau(this.index);

  @override
  bool operator ==(Object other) => other is Tableau && other.index == index;

  @override
  int get hashCode => Object.hash(index, null);

  @override
  String toString() => "Tableau($index)";
}
