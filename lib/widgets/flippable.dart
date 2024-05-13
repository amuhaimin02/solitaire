import 'package:flutter/material.dart';

import '../animations.dart';

class Flippable extends StatefulWidget {
  const Flippable({
    super.key,
    required this.flipped,
    required this.front,
    required this.back,
  });

  final bool flipped;
  final Widget front;
  final Widget back;

  @override
  State<Flippable> createState() => _FlippableState();
}

class _FlippableState extends State<Flippable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late Widget _currentChild;

  bool _childChanged = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: cardMoveAnimation.duration,
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);
    _currentChild = _getVisibleChild();
  }

  @override
  void didUpdateWidget(Flippable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.flipped != oldWidget.flipped) {
      print('ANIMATE!');
      _startAnimation();
    } else if (widget.front != oldWidget.front ||
        widget.back != oldWidget.back) {
      setState(() {
        _currentChild = _getVisibleChild();
      });
    }
  }

  Future<void> _startAnimation() async {
    _controller.reset();
    _childChanged = false;

    _controller.addListener(() {
      if (_animation.value > 0.5 && _childChanged) {
        print('child change');
        setState(() {
          _currentChild = _getVisibleChild();
          _childChanged = true;
        });
      }
    });
    _controller.forward(from: 0.0);
  }

  Widget _getVisibleChild() {
    return widget.flipped ? widget.back : widget.front;
  }

  @override
  Widget build(BuildContext context) {
    // return MatrixTransition(
    //   alignment: Alignment.center,
    //   animation: TweenSequence([
    //     TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
    //     TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
    //   ]).animate(_controller),
    //   onTransform: (value) {
    //     print('scale $value');
    //     return Matrix4.identity()..scale(value);
    //   },
    //   child: _currentChild,
    // );
    return _getVisibleChild();
  }
}
