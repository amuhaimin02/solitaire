import 'package:flutter/material.dart';

import '../animations.dart';

class FastPageView extends StatefulWidget {
  const FastPageView(
      {super.key, required this.itemBuilder, required this.itemCount});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<FastPageView> createState() => _FastPageViewState();
}

class _FastPageViewState extends State<FastPageView> {
  int _currentIndex = 0;
  Offset _direction = Offset.zero;

  static const _left = Offset(-1, 0);
  static const _right = Offset(1, 0);

  static const _swipeVelocityThreshold = 300;

  bool _lockChange = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.chevron_left),
              ),
              Flexible(
                child: AnimatedSwitcher(
                  duration: standardAnimation.duration,
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    final isReversing =
                        animation.status == AnimationStatus.completed;

                    final slideTween = Tween(
                        begin: (isReversing
                                ? const Offset(0.5, 0)
                                : const Offset(-0.5, 0))
                            .scale(_direction.dx, _direction.dy),
                        end: Offset.zero);

                    return SlideTransition(
                      position: slideTween.animate(animation),
                      child: FadeTransition(
                        opacity: CurveTween(curve: const Interval(0.5, 1))
                            .animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: widget.itemBuilder(context, _currentIndex),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity;
              if (velocity != null &&
                  velocity.abs() > _swipeVelocityThreshold) {
                _move(Offset(velocity.sign, 0));
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _move(_left),
                    child: const SizedBox.expand(),
                  ),
                ),
                const Spacer(),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _move(_right),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _move(Offset direction) {
    _throttle(() {
      if (direction == _left) {
        if (_currentIndex > 0) {
          setState(() {
            _currentIndex--;
            _direction = _left;
          });
        }
      } else if (direction == _right) {
        if (_currentIndex < widget.itemCount - 1) {
          setState(() {
            _currentIndex++;
            _direction = _right;
          });
        }
      }
    });
  }

  void _throttle(VoidCallback fn) {
    if (_lockChange) {
      return;
    }
    _lockChange = true;

    fn();

    Future.delayed(standardAnimation.duration, () {
      _lockChange = false;
    });
  }
}
