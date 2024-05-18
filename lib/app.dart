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
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/loading_screen.dart';
import 'widgets/background.dart';

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
              textTheme: GoogleFonts.robotoSlabTextTheme(),
              colorScheme: colorScheme,
              splashFactory: InkRipple.splashFactory,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: FadeOutInTransitionBuilder(),
                  TargetPlatform.iOS: FadeOutInTransitionBuilder(),
                  TargetPlatform.macOS: FadeOutInTransitionBuilder(),
                },
              ));
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
                  brightness: Brightness.light, seedColor: presetColor);
              darkColorScheme = ColorScheme.fromSeed(
                  brightness: Brightness.dark, seedColor: presetColor);
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
              child: MaterialApp(
                title: 'Solitaire',
                theme: buildTheme(lightColorScheme),
                darkTheme: buildTheme(darkColorScheme),
                themeMode: settings.get(Settings.themeMode),
                themeAnimationStyle: AnimationStyle.noAnimation,
                initialRoute: '/home',
                routes: {
                  '/home': (context) => const HomeScreen(),
                  '/game': (context) => const GameScreen(),
                },
                builder: (context, currentScreen) {
                  final isSettingsLoaded = context
                      .select<SettingsManager, bool>((s) => s.isPreloaded);

                  return isSettingsLoaded && currentScreen != null
                      ? currentScreen
                      : const LoadingScreen();
                },
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
        color: colorScheme.primaryContainer,
        child: FadeTransition(
          opacity: secondaryAnimation
              .drive(Tween(begin: 1.0, end: 0.0).chain(fadeInCurve)),
          child: child,
        ),
      ),
    );
  }
}
