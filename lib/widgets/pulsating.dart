import 'package:flutter/material.dart';

class Pulsating extends StatefulWidget {
  const Pulsating({super.key, required this.child});

  final Widget child;

  @override
  State<Pulsating> createState() => _PulsatingState();
}

class _PulsatingState extends State<Pulsating>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInQuad, // For a slow start
        ),
      ),
      child: widget.child,
    );
  }
}
