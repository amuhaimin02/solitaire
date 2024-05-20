import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'animations.dart';
import 'models/game_state.dart';
import 'models/game_theme.dart';
import 'providers/settings.dart';
import 'screens/about_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/theme_screen.dart';
import 'widgets/ripple_background.dart';
import 'widgets/solitaire_theme.dart';

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
            textTheme: GoogleFonts.interTextTheme(),
            colorScheme: colorScheme,
            splashColor: Colors.transparent,
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeOutInTransitionBuilder(),
                TargetPlatform.iOS: FadeOutInTransitionBuilder(),
                TargetPlatform.macOS: FadeOutInTransitionBuilder(),
              },
            ),
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => GameTheme()),
            ChangeNotifierProvider(create: (_) => SettingsManager()),
          ],
          builder: (context, child) {
            final settings = context.watch<SettingsManager>();

            ThemeMode themeMode = settings.get(Settings.themeMode);
            final useDynamicColors = settings.get(Settings.useDynamicColors);
            final presetColor = settings.get(Settings.presetColor);
            ColorScheme colorScheme;

            if (themeMode == ThemeMode.system) {
              final systemThemeMode =
                  WidgetsBinding.instance.platformDispatcher.platformBrightness;
              themeMode = systemThemeMode == Brightness.light
                  ? ThemeMode.light
                  : ThemeMode.dark;
            }

            if (themeMode == ThemeMode.light) {
              if (useDynamicColors && lightDynamic != null) {
                colorScheme = lightDynamic;
              } else {
                colorScheme = ColorScheme.fromSeed(
                    brightness: Brightness.light, seedColor: presetColor);
              }
            } else {
              if (useDynamicColors && darkDynamic != null) {
                colorScheme = darkDynamic;
              } else {
                colorScheme = ColorScheme.fromSeed(
                    brightness: Brightness.dark, seedColor: presetColor);
              }
            }

            final SolitaireThemeData themeData;
            if (settings.get(Settings.useStandardColors)) {
              themeData = SolitaireThemeData(
                backgroundColor: Colors.green.shade800,
                backgroundSecondaryColor: Colors.green.shade900,
                foregroundColor: Colors.white,
                winningBackgroundColor: Colors.green.shade500,
                cardCoverColor: Colors.blueGrey,
                cardFaceColor: Colors.white,
                cardLabelPlainColor: Colors.grey.shade800,
                cardLabelAccentColor: Colors.red,
                pileMarkerColor: Colors.white,
                hintHighlightColor: Colors.yellow,
                lastMoveHighlightColor: Colors.orangeAccent,
                cardUnitSize: const Size(2.5, 3.5),
                cardPadding: 0.06,
                cardStackGap: const Offset(0.3, 0.3),
                cardCornerRadius: 0.1,
              );
            } else {
              themeData = SolitaireThemeData.fromColorScheme(
                colorScheme: colorScheme,
                cardUnitSize: const Size(2.5, 3.5),
                cardPadding: 0.06,
                cardStackGap: const Offset(0.3, 0.3),
                cardCornerRadius: 0.1,
                useGradientBackground:
                    settings.get(Settings.useGradientBackground),
                useColoredBackground: settings.get(Settings.coloredBackground),
              );
            }

            return MultiProvider(
              providers: [
                ChangeNotifierProxyProvider<SettingsManager, GameState>(
                  create: (_) => GameState(),
                  update: (_, settings, state) {
                    state!.autoMoveLevel = settings.get(Settings.autoMoveLevel);
                    return state;
                  },
                ),
              ],
              child: SolitaireTheme(
                data: themeData,
                child: MaterialApp(
                  title: 'Solitaire',
                  theme: buildTheme(colorScheme),
                  themeAnimationStyle: AnimationStyle.noAnimation,
                  initialRoute: '/home',
                  routes: {
                    '/home': (context) => const HomeScreen(),
                    '/game': (context) => const GameScreen(),
                    '/theme': (context) => const ThemeScreen(),
                    '/settings': (context) => const SettingsScreen(),
                    '/stats': (context) => const StatisticsScreen(),
                    '/about': (context) => const AboutScreen(),
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class FadeOutInTransitionBuilder extends PageTransitionsBuilder {
  const FadeOutInTransitionBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    final fadeInCurve =
        CurveTween(curve: const Interval(0, 0.5, curve: Curves.linear));
    final fadeOutCurve =
        CurveTween(curve: const Interval(0.5, 1, curve: Curves.linear));
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: animation.drive(fadeOutCurve),
      child: RippleBackground(
        decoration: SolitaireTheme.of(context).generateBackgroundDecoration(),
        child: FadeTransition(
          opacity: secondaryAnimation
              .drive(Tween(begin: 1.0, end: 0.0).chain(fadeInCurve)),
          child: child,
        ),
      ),
    );
  }
}
