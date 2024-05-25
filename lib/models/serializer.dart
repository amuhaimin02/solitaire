import 'dart:ui';

abstract interface class Serializer<T> {
  T from(String raw);

  String to(T value);
}

class ColorSerializer implements Serializer<Color> {
  const ColorSerializer();

  @override
  Color from(String raw) => Color(int.parse(raw, radix: 16));

  @override
  String to(Color color) => color.value.toRadixString(16);
}
