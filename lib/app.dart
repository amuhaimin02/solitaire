import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/game_state.dart';
import 'providers/settings.dart';
import 'screens/about_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
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

    ThemeData buildTheme(ColorScheme? colorScheme) {
      return ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.manropeTextTheme(),
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
        ChangeNotifierProvider(create: (_) => SettingsManager()),
      ],
      builder: (context, child) {
        final settings = context.watch<SettingsManager>();

        ThemeMode themeMode = settings.get(Settings.themeMode);
        final presetColor = settings.get(Settings.presetColor);
        final amoledDarkTheme = settings.get(Settings.amoledDarkTheme);

        ColorScheme colorScheme;

        if (themeMode == ThemeMode.system) {
          final systemThemeMode =
              WidgetsBinding.instance.platformDispatcher.platformBrightness;
          themeMode = systemThemeMode == Brightness.light
              ? ThemeMode.light
              : ThemeMode.dark;
        }

        final brightness = switch (themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          _ => throw UnimplementedError()
        };

        colorScheme = ColorScheme.fromSeed(
          brightness: brightness,
          seedColor: presetColor != Colors.transparent
              ? presetColor
              : themeColorPalette.first,
        );

        final SolitaireCardStyle cardStyle;

        if (settings.get(Settings.useStandardCardColors)) {
          cardStyle = SolitaireCardStyle(
            facePlainColor: Colors.white,
            faceAccentColor: Colors.white,
            labelPlainColor: Colors.grey.shade800,
            labelAccentColor: Colors.red,
            coverColor: colorScheme.primary,
            unitSize: const Size(2.5, 3.5),
            margin: 0.06,
            coverBorderPadding: 0.02,
            stackGap: const Offset(0.3, 0.3),
            cornerRadius: 0.1,
          );
        } else {
          cardStyle = SolitaireCardStyle.fromColorScheme(
            colorScheme,
            amoledDarkTheme: amoledDarkTheme,
          );
        }

        final themeData = SolitaireThemeData.fromColorScheme(
          colorScheme: colorScheme,
          cardStyle: cardStyle,
          amoledDarkTheme: amoledDarkTheme,
        );

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
        decoration:
            BoxDecoration(color: SolitaireTheme.of(context).backgroundColor),
        child: FadeTransition(
          opacity: secondaryAnimation
              .drive(Tween(begin: 1.0, end: 0.0).chain(fadeInCurve)),
          child: child,
        ),
      ),
    );
  }
}
