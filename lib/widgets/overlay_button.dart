import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animations.dart';
import '../utils/widgets.dart';

class OverlayButton extends StatelessWidget {
  const OverlayButton({
    super.key,
    required this.overlayBuilder,
    required this.buttonBuilder,
  });

  factory OverlayButton.icon({
    required String tooltip,
    required Widget icon,
    required List<Widget> Function(BuildContext context) overlayBuilder,
  }) {
    return OverlayButton(
      buttonBuilder: (context, trigger) {
        return IconButton(
          tooltip: tooltip,
          icon: icon,
          onPressed: trigger,
        );
      },
      overlayBuilder: overlayBuilder,
    );
  }

  final List<Widget> Function(BuildContext context) overlayBuilder;
  final Widget Function(BuildContext context, VoidCallback trigger)
      buttonBuilder;

  @override
  Widget build(BuildContext context) {
    return buttonBuilder(context, () => _onPressed(context));
  }

  Future<void> _onPressed(BuildContext context) async {
    final buttonPosition = context.globalPaintBounds!;
    HapticFeedback.mediumImpact();

    final screenSize = MediaQuery.of(context).size;
    final screenCenter = screenSize.center(Offset.zero);

    final popupAlignment = Alignment(
      buttonPosition.center.dx > screenCenter.dx ? 1 : -1,
      buttonPosition.center.dy > screenCenter.dy ? 1 : -1,
    );

    final dialogAnchor = switch (popupAlignment) {
      Alignment.topLeft => buttonPosition.topLeft,
      Alignment.topRight => buttonPosition.topRight,
      Alignment.bottomLeft => buttonPosition.bottomLeft,
      Alignment.bottomRight => buttonPosition.bottomRight,
      _ => throw UnimplementedError(),
    };

    final dialogViewport = switch (popupAlignment) {
      Alignment.topLeft => Rect.fromLTRB(dialogAnchor.dx, dialogAnchor.dy,
          screenSize.width, screenSize.height),
      Alignment.topRight =>
        Rect.fromLTRB(0, dialogAnchor.dy, dialogAnchor.dx, screenSize.height),
      Alignment.bottomLeft =>
        Rect.fromLTRB(dialogAnchor.dx, 0, screenSize.width, dialogAnchor.dy),
      Alignment.bottomRight =>
        Rect.fromLTRB(0, 0, dialogAnchor.dx, dialogAnchor.dy),
      _ => throw UnimplementedError(),
    };

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black26,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: <Widget>[
            Positioned.fromRect(
              rect: dialogViewport,
              child: Align(
                alignment: popupAlignment,
                child: ScaleTransition(
                  scale: CurveTween(curve: popupAnimation.curve)
                      .animate(animation),
                  alignment: popupAlignment,
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      vertical: buttonPosition.size.height / 2,
                      horizontal: buttonPosition.size.width / 2,
                    ),
                    width: 224,
                    alignment: popupAlignment,
                    child: Material(
                      elevation: 24,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: MediaQuery.removePadding(
                          // Remove extraneous padding on children ListTiles caused by internal SafeArea
                          context: context,
                          removeLeft: true,
                          removeRight: true,
                          child: ListView(
                            primary: true,
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: overlayBuilder(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
