import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

const intMaxValue = 9007199254740991;

extension StringExtension on String {
  bool containsIgnoreCase(String substring) {
    return toLowerCase().contains(substring.toLowerCase());
  }
}

extension IterableExtension<T> on Iterable<T> {
  int count(bool Function(T) test) {
    return fold(0, (prev, item) => test(item) ? prev + 1 : prev);
  }
}

extension ListExtension<T> on List<T> {
  (List<T> a, List<T> b) partition(bool Function(T element) test) {
    final List<T> a = [];
    final List<T> b = [];

    forEach((element) => test(element) ? a.add(element) : b.add(element));

    return (a, b);
  }

  List<T> sortedByPriority(int Function(T element) getPriority) {
    return mapIndexed(
            (index, elem) => (index: index, priority: getPriority(elem)))
        .where((item) => item.priority >= 0)
        .sorted((a, b) => b.priority.compareTo(a.priority))
        .map((item) => this[item.index])
        .toList();
  }
}

extension MapExtension<K, V> on Map<K, V> {
  V get(K key) {
    final value = this[key];
    if (value == null) {
      throw ArgumentError('Key $key does not exist in map');
    }
    return value;
  }

  Iterable<(K, V)> get items {
    return entries.map((entry) => (entry.key, entry.value));
  }
}

extension PrintableDuration on Duration {
  static final maxDisplayableDuration = const Duration(minutes: 100).inSeconds;

  String toMMSSString() {
    final seconds = inSeconds;

    if (seconds >= maxDisplayableDuration) {
      return '99:59';
    }

    final minuteString = seconds ~/ 60;
    final secondString = seconds % 60;

    return '${minuteString.toString().padLeft(2, '0')}:${secondString.toString().padLeft(2, '0')}';
  }
}

extension ChunkableString on String {
  Iterable<String> chunk(int partsLength) sync* {
    assert(
      length % partsLength == 0,
      'string must be divisible by $partsLength',
    );
    for (int i = 0; i < length; i += partsLength) {
      yield substring(i, i + partsLength);
    }
  }
}

extension RectExtension on Rect {
  Rect scale(Size scaleSize) {
    return Rect.fromLTWH(
      left * scaleSize.width,
      top * scaleSize.height,
      width * scaleSize.width,
      height * scaleSize.height,
    );
  }
}

extension DateTimeExtension on DateTime {
  static final _pathFriendlyDateFormat = DateFormat('yyyy-MM-dd-HH-mm-ss');

  String toPathFriendlyString() {
    return _pathFriendlyDateFormat.format(this);
  }
}
