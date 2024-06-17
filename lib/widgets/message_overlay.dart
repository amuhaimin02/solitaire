import 'dart:async';

import 'package:flutter/material.dart';

import '../animations.dart';

class MessageOverlay extends StatefulWidget {
  const MessageOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<MessageOverlay> createState() => MessageOverlayState();

  static MessageOverlayState? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_MessageOverlayScope>();
    return scope?.state;
  }

  static MessageOverlayState of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No MessageOverlay found in context');
    return result!;
  }
}

class _MessageOverlayScope extends InheritedWidget {
  final MessageOverlayState state;

  const _MessageOverlayScope(
      {super.key, required super.child, required this.state});

  @override
  bool updateShouldNotify(covariant _MessageOverlayScope oldWidget) {
    return state != oldWidget.state;
  }
}

class MessageOverlayState extends State<MessageOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Widget? _overlay;
  Timer? _overlayShowTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: standardAnimation.duration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          _overlay = null;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MessageOverlayScope(
      state: this,
      child: Stack(
        children: [
          widget.child,
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _controller,
                child: child,
              );
            },
            child: Material(
              type: MaterialType.transparency,
              child: _overlay,
            ),
          )
        ],
      ),
    );
  }

  void show(Widget widget) {
    _overlayShowTimer?.cancel();
    _controller.forward(from: 0);
    setState(() {
      _overlay = widget;
    });
    _overlayShowTimer = Timer(const Duration(seconds: 2), () {
      _controller.reverse(from: 1);
    });
  }
}
