import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/game_settings.dart';
import 'models/game_theme.dart';
import 'providers/system_orientation.dart';
import 'screens/game_screen.dart';
import 'utils/iterators.dart';

class SolitaireApp extends StatelessWidget {
  const SolitaireApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ThemeData buildTheme(ColorScheme? colorScheme) {
          return ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.dosisTextTheme(),
            colorScheme: colorScheme,
            splashFactory: InkRipple.splashFactory,
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => GameTheme()),
            ChangeNotifierProvider(create: (_) => SystemOrientationManager()),
            ChangeNotifierProvider(create: (_) => GameSettings()),
          ],
          builder: (context, child) {
            final gameTheme = context.watch<GameTheme>();
            final ColorScheme? lightColorScheme, darkColorScheme;

            if (gameTheme.usingRandomColors) {
              final presetColor = gameTheme.currentPresetColor!;
              lightColorScheme = ColorScheme.fromSeed(
                  brightness: Brightness.light, seedColor: presetColor);
              darkColorScheme = ColorScheme.fromSeed(
                  brightness: Brightness.dark, seedColor: presetColor);
            } else {
              lightColorScheme = lightDynamic;
              darkColorScheme = darkDynamic;
            }

            return MaterialApp(
              title: 'Solitaire',
              theme: buildTheme(lightColorScheme),
              darkTheme: buildTheme(darkColorScheme),
              themeMode: gameTheme.currentMode,
              home: const GameScreen(),
            );
          },
        );
      },
    );
  }
}
