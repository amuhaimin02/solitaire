import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class CelebrationEffect extends StatefulWidget {
  const CelebrationEffect(
      {super.key, required this.child, this.enabled = true});

  final Widget child;

  final bool enabled;

  @override
  State<CelebrationEffect> createState() => _CelebrationEffectState();
}

class _CelebrationEffectState extends State<CelebrationEffect> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CelebrationEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final confettiSize = MediaQuery.of(context).size.shortestSide * 0.03;
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: const Alignment(0, -0.5),
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: -pi / 2,
            maxBlastForce: 20, // set a lower max blast force
            minBlastForce: 1, // set a lower min blast force
            emissionFrequency: 0.5,
            numberOfParticles: 50,
            gravity: 0.1,
            minimumSize: Size.square(confettiSize * 0.5),
            maximumSize: Size.square(confettiSize),
          ),
        ),
      ],
    );
  }
}
