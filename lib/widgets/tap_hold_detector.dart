import 'dart:async';

import 'package:flutter/material.dart';

class TapHoldDetector extends StatefulWidget {
  const TapHoldDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onHold,
    this.onRelease,
    this.interval = const Duration(seconds: 1),
    this.delayBeforeHold = Duration.zero,
  });

  final Widget child;

  final Duration interval;

  final Duration delayBeforeHold;

  final Function()? onTap;

  final Function(Duration holdDuration)? onHold;

  final Function()? onRelease;

  @override
  State<TapHoldDetector> createState() => _TapHoldDetectorState();
}

class _TapHoldDetectorState extends State<TapHoldDetector> {
  Timer? _holdTimer;
  Timer? _waitTimer;

  @override
  Widget build(BuildContext context) {
    onHold() {
      _holdTimer?.cancel();
      _waitTimer?.cancel();
      widget.onTap?.call();

      if (widget.onHold != null) {
        _waitTimer = Timer(widget.delayBeforeHold, () {
          widget.onHold!.call(Duration.zero);

          _holdTimer = Timer.periodic(widget.interval, (timer) {
            widget.onHold!.call(widget.interval * timer.tick);
          });
        });
      }
    }

    onRelease() {
      _holdTimer?.cancel();
      _waitTimer?.cancel();
      widget.onRelease?.call();
    }

    return Listener(
      onPointerDown: (_) => onHold(),
      onPointerUp: (_) => onRelease(),
      onPointerCancel: (_) => onRelease(),
      child: widget.child,
    );
  }
}
