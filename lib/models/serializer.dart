import 'dart:ui';

abstract interface class Serializer<T> {
  String serialize(T value);
  T deserialize(String raw);
}

class ColorSerializer implements Serializer<Color> {
  const ColorSerializer();

  @override
  String serialize(Color color) => color.value.toRadixString(16);

  @override
  Color deserialize(String raw) => Color(int.parse(raw, radix: 16));
}
