import 'package:flutter/material.dart';

class BottomPadded extends StatelessWidget {
  const BottomPadded({super.key, required this.child});

  final Widget child;

  static EdgeInsets getPadding(BuildContext context) {
    return EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: BottomPadded.getPadding(context),
      child: child,
    );
  }
}
