import 'package:flutter/material.dart';

enum StackingStyle { topDown, bottomSheet, newPage }

class TwoPane extends StatefulWidget {
  const TwoPane({
    super.key,
    required this.primaryBuilder,
    required this.secondaryBuilder,
    required this.stackingStyleOnPortrait,
    this.primaryRatioOnPortrait = 0.5,
    this.primaryRatioOnLandscape = 0.5,
  });

  final WidgetBuilder primaryBuilder;

  final WidgetBuilder secondaryBuilder;

  final StackingStyle stackingStyleOnPortrait;

  final double primaryRatioOnPortrait;

  final double primaryRatioOnLandscape;

  @override
  State<TwoPane> createState() => TwoPaneState();

  static TwoPaneState? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TwoPaneScope>();
    return scope?.state;
  }

  static TwoPaneState of(BuildContext context) {
    final TwoPaneState? result = maybeOf(context);
    assert(result != null, 'No TwoPane found in context');
    return result!;
  }
}

class _TwoPaneScope extends InheritedWidget {
  const _TwoPaneScope({super.key, required super.child, required this.state});

  final TwoPaneState state;

  @override
  bool updateShouldNotify(covariant _TwoPaneScope oldWidget) {
    return state != oldWidget.state;
  }
}

class TwoPaneState extends State<TwoPane> {
  late bool isActive;

  @override
  Widget build(BuildContext context) {
    return _TwoPaneScope(
      state: this,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          if (isWide) {
            isActive = true;
            return Row(
              children: [
                Expanded(
                  flex: (widget.primaryRatioOnLandscape * 100).truncate(),
                  child: widget.primaryBuilder(context),
                ),
                Expanded(
                  flex: ((1 - widget.primaryRatioOnLandscape) * 100).truncate(),
                  child: widget.secondaryBuilder(context),
                ),
              ],
            );
          } else if (widget.stackingStyleOnPortrait == StackingStyle.topDown) {
            isActive = false;
            return Column(
              children: [
                Expanded(
                  flex: (widget.primaryRatioOnPortrait * 100).truncate(),
                  child: widget.primaryBuilder(context),
                ),
                Expanded(
                  flex: ((1 - widget.primaryRatioOnPortrait) * 100).truncate(),
                  child: widget.secondaryBuilder(context),
                ),
              ],
            );
          } else {
            isActive = false;
            return widget.primaryBuilder(context);
          }
        },
      ),
    );
  }

  void pushSecondary() {
    if (!isActive) {
      switch (widget.stackingStyleOnPortrait) {
        case StackingStyle.topDown:
          break;
        case StackingStyle.bottomSheet:
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => SingleChildScrollView(
              child: Wrap(
                children: [
                  _TwoPaneScope(
                    state: this,
                    child: widget.secondaryBuilder(context),
                  ),
                ],
              ),
            ),
          );
        case StackingStyle.newPage:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _TwoPaneScope(
                state: this,
                child: widget.secondaryBuilder(context),
              ),
            ),
          );
      }
    }
  }

  void popSecondary() {
    if (!isActive && widget.stackingStyleOnPortrait != StackingStyle.topDown) {
      Navigator.pop(context);
    }
  }
}
