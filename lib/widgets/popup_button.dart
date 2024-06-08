import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/widgets.dart';

class PopupButton extends StatelessWidget {
  const PopupButton({
    super.key,
    required this.icon,
    this.tooltip,
    required this.builder,
  });

  final Icon icon;

  final String? tooltip;

  final List<Widget> Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () => _onPressed(context),
      icon: icon,
    );
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
                  scale: CurveTween(curve: Easing.emphasizedDecelerate)
                      .animate(animation),
                  alignment: popupAlignment,
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      vertical: buttonPosition.size.height / 2,
                      horizontal: buttonPosition.size.width / 2,
                    ),
                    width: 250,
                    alignment: popupAlignment,
                    child: Material(
                      elevation: 24,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView(
                          primary: true,
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: builder(context),
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
