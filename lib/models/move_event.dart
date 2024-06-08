import 'pile.dart';

sealed class MoveEvent {
  const MoveEvent();
}

class MoveMade extends MoveEvent {
  const MoveMade({required this.from, required this.to});

  final Pile from;
  final Pile to;

  @override
  String toString() => 'MoveMade($from, $to)';
}

class TableauReveal extends MoveEvent {
  const TableauReveal();
  @override
  String toString() => 'TableauReveal';
}

class RecycleMade extends MoveEvent {
  const RecycleMade();
  @override
  String toString() => 'RecycleMade';
}
