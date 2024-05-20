import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FadingEdgeListView extends StatelessWidget {
  const FadingEdgeListView(
      {super.key, required this.children, this.verticalPadding = 48});

  final List<Widget> children;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        final fadingRegionHeight = verticalPadding / rect.height;

        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [
            0,
            fadingRegionHeight,
            1 - fadingRegionHeight,
            1,
          ],
          colors: const [
            Colors.black,
            Colors.white,
            Colors.white,
            Colors.black
          ],
        ).createShader(rect);
      },
      blendMode: BlendMode.modulate,
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        children: children,
      ),
    );
  }
}
