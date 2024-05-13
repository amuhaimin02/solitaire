import 'package:flutter/material.dart';

// https://stackoverflow.com/questions/43916323/how-do-i-create-an-animated-number-counter

class TickingNumber extends ImplicitlyAnimatedWidget {
  final int number;
  final TextStyle? style;

  const TickingNumber(
    this.number, {
    super.key,
    super.curve,
    required super.duration,
    this.style,
  });

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _AnimatedCountState();
}

class _AnimatedCountState extends AnimatedWidgetBaseState<TickingNumber> {
  IntTween _numberTween = IntTween(begin: 0, end: 0);

  @override
  void initState() {
    super.initState();
    _numberTween = IntTween(begin: widget.number, end: widget.number);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _numberTween.evaluate(animation).toString(),
      style: widget.style,
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _numberTween =
        visitor(_numberTween, widget.number, (value) => IntTween(begin: value))
            as IntTween;
  }
}
