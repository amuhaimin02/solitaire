import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

const intMaxValue = 9007199254740991;

extension NumExtension on num {
  bool isInRange(int start, int end) {
    return this >= start && this <= end;
  }
}

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
  Map<K, T> mapBy<K>(K Function(T element) mapperFn) {
    return {for (var e in this) mapperFn(e): e};
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

  Map<V, K> inverseKeyValue() {
    return Map.fromEntries(entries.map((e) => MapEntry(e.value, e.key)));
  }
}

extension DurationExtension on Duration {
  static final maxDisplayableDuration = const Duration(minutes: 100).inSeconds;

  String toNaturalHMSString() {
    int hours = inHours;
    int minutes = inMinutes % 60;
    int seconds = inSeconds % 60;

    // TODO: Localize
    if (hours > 0) {
      return '$hours hr $minutes min $seconds sec';
    } else {
      return '$minutes min $seconds sec';
    }
  }

  String toSimpleHMSString() {
    int hours = inHours;
    int minutes = inMinutes % 60;
    int seconds = inSeconds % 60;

    String pad(int value) {
      return value.toString().padLeft(2, '0');
    }

    if (hours > 0) {
      return '$hours:${pad(minutes)}:${pad(seconds)}';
    } else {
      return '$minutes:${pad(seconds)}';
    }
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

  static final _naturalFormat = DateFormat.yMd().add_jm();

  String toNaturalDateTimeString() {
    return _naturalFormat.format(this);
  }
}
