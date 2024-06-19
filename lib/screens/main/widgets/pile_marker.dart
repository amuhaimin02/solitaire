import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../models/card.dart';
import '../../../models/game_theme.dart';
import '../../../models/pile.dart';

class PileMarker extends StatelessWidget {
  const PileMarker({
    super.key,
    required this.pile,
    required this.startsWith,
    required this.canRecycle,
    required this.size,
  });

  final Pile pile;

  final Rank? startsWith;

  final bool? canRecycle;

  final Size size;

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).gameCardTheme;

    final borderOnly =
        Theme.of(context).gameTheme.tableBackgroundColor == Colors.black;

    final colorScheme = Theme.of(context).colorScheme;

    final markerColor = colorScheme.onSurface.withOpacity(0.26);
    final markerIconSize = size.shortestSide * 0.5;
    final markerTextSize = size.shortestSide * 0.5;
    //
    // IconData getFoundationIcon() {
    //   return switch (startsWith) {
    //     Rank.ace => MdiIcons.alphaACircle,
    //     Rank.two => MdiIcons.numeric2Circle,
    //     Rank.three => MdiIcons.numeric3Circle,
    //     Rank.four => MdiIcons.numeric4Circle,
    //     Rank.five => MdiIcons.numeric5Circle,
    //     Rank.six => MdiIcons.numeric6Circle,
    //     Rank.seven => MdiIcons.numeric7Circle,
    //     Rank.eight => MdiIcons.numeric8Circle,
    //     Rank.nine => MdiIcons.numeric9Circle,
    //     Rank.ten => MdiIcons.numeric10Circle,
    //     Rank.jack => MdiIcons.alphaJCircle,
    //     Rank.queen => MdiIcons.alphaQCircle,
    //     Rank.king => MdiIcons.alphaKCircle,
    //     null => MdiIcons.starCircle,
    //   };
    // }
    //
    // IconData getTableauIcon() {
    //   return switch (startsWith) {
    //     Rank.ace => MdiIcons.alphaABox,
    //     Rank.two => MdiIcons.numeric2Box,
    //     Rank.three => MdiIcons.numeric3Box,
    //     Rank.four => MdiIcons.numeric4Box,
    //     Rank.five => MdiIcons.numeric5Box,
    //     Rank.six => MdiIcons.numeric6Box,
    //     Rank.seven => MdiIcons.numeric7Box,
    //     Rank.eight => MdiIcons.numeric8Box,
    //     Rank.nine => MdiIcons.numeric9Box,
    //     Rank.ten => MdiIcons.numeric10Box,
    //     Rank.jack => MdiIcons.alphaJBox,
    //     Rank.queen => MdiIcons.alphaQBox,
    //     Rank.king => MdiIcons.alphaKBox,
    //     null => MdiIcons.starBox,
    //   };
    // }

    final Widget? label;
    switch (pile) {
      case Stock():
        if (canRecycle == null) {
          throw ArgumentError(
              'Stock pile must have canRecycle property for pile marker');
        }
        label = Icon(
          canRecycle == true ? MdiIcons.refresh : Icons.block,
          color: markerColor,
          size: markerIconSize,
        );
      case Foundation() || Tableau() when startsWith != null:
        label = Text(
          startsWith!.symbol,
          style: GoogleFonts.getFont(
            cardTheme.labelFontFamily,
            color: markerColor,
            fontSize: markerTextSize,
          ),
        );
      case Waste():
        label = Icon(
          MdiIcons.cardsPlaying,
          color: markerColor,
          size: markerIconSize,
        );
      default:
        label = null;
    }

    return Padding(
      padding: EdgeInsets.all(size.shortestSide * cardTheme.margin),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            color: borderOnly ? null : colorScheme.onSurface.withOpacity(0.12),
            borderRadius: BorderRadius.circular(
                size.shortestSide * cardTheme.cornerRadius),
            border: borderOnly
                ? Border.all(
                    color: colorScheme.onSurface.withOpacity(0.24),
                    width: 2,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: label ?? const SizedBox(),
        ),
      ),
    );
  }
}
