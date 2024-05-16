import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/game_state.dart';
import 'models/game_theme.dart';
import 'providers/settings.dart';
import 'screens/game_screen.dart';

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
            ChangeNotifierProvider(create: (_) => Settings()),
          ],
          builder: (context, child) {
            final gameTheme = context.watch<GameTheme>();
            final settings = context.watch<Settings>();
            ColorScheme? lightColorScheme, darkColorScheme;

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

            if (settings.useStandardColors()) {
              lightColorScheme = ColorScheme.light(
                surface: Colors.white,
                primary: Colors.grey.shade800,
                primaryContainer: Colors.green.shade800,
                secondary: Colors.yellow,
                tertiary: Colors.red.shade700,
              );
              darkColorScheme =
                  lightColorScheme.copyWith(brightness: Brightness.dark);
            }

            return MaterialApp(
              title: 'Solitaire',
              theme: buildTheme(lightColorScheme),
              darkTheme: buildTheme(darkColorScheme),
              themeMode: gameTheme.currentMode,
              themeAnimationStyle: AnimationStyle.noAnimation,
              home: MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => GameState()),
                ],
                child: const GameScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
