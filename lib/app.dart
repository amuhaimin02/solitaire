import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/game_state.dart';
import 'models/game_theme.dart';
import 'providers/settings.dart';
import 'screens/game_screen.dart';
import 'screens/loading_screen.dart';

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
            ChangeNotifierProvider(create: (_) => SettingsManager()),
          ],
          builder: (context, child) {
            final settings = context.watch<SettingsManager>();
            ColorScheme? lightColorScheme, darkColorScheme;

            if (settings.get(Settings.useDynamicColors)) {
              lightColorScheme = lightDynamic;
              darkColorScheme = darkDynamic;
            } else {
              final presetColor = settings.get(Settings.presetColor);
              lightColorScheme = ColorScheme.fromSeed(
                  brightness: Brightness.light, seedColor: Color(presetColor));
              darkColorScheme = ColorScheme.fromSeed(
                  brightness: Brightness.dark, seedColor: Color(presetColor));
            }

            return MaterialApp(
              title: 'Solitaire',
              theme: buildTheme(lightColorScheme),
              darkTheme: buildTheme(darkColorScheme),
              themeMode: settings.get(Settings.themeMode),
              themeAnimationStyle: AnimationStyle.noAnimation,
              home: MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => GameState()),
                ],
                builder: (context, child) {
                  final isSettingsLoaded = context
                      .select<SettingsManager, bool>((s) => s.isPreloaded);

                  if (isSettingsLoaded) {
                    return const GameScreen();
                  } else {
                    return const LoadingScreen();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
