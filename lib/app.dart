import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/settings.dart';
import 'providers/themes.dart';
import 'screens/about_screen.dart';
import 'screens/theme_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'services/route_observer.dart';
import 'services/system_orientation.dart';
import 'widgets/ripple_background.dart';
import 'widgets/solitaire_theme.dart';

class SolitaireApp extends ConsumerWidget {
  const SolitaireApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    ref.listen(settingsScreenOrientationProvider, (_, orientation) {
      ScreenOrientationManager.change(orientation);
    });

    ThemeMode themeMode = ref.watch(themeBaseModeProvider);
    final themeColor = ref.watch(themeBaseColorProvider);
    final coloredBackground = ref.watch(themeBackgroundColoredProvider);
    final amoledDarkTheme = ref.watch(themeBackgroundAmoledProvider);
    final cardThemeMode = ref.watch(themeCardModeProvider);
    final cardColor = ref.watch(themeCardColorProvider);

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
      seedColor: themeColor != Colors.transparent
          ? themeColor
          : themeColorPalette.first,
    );

    final SolitaireCardStyle cardStyle;

    final ColorScheme cardColorScheme;

    if (cardThemeMode != ThemeMode.system || cardColor != Colors.transparent) {
      cardColorScheme = ColorScheme.fromSeed(
        seedColor: cardColor != Colors.transparent ? cardColor : themeColor,
        brightness: switch (cardThemeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => colorScheme.brightness,
        },
      );
    } else {
      cardColorScheme = colorScheme;
    }

    cardStyle = SolitaireCardStyle.fromColorScheme(
      cardColorScheme,
      tintedCardFace: ref.watch(themeCardTintedFaceProvider),
    );

    final solitaireThemeData = SolitaireThemeData.fromColorScheme(
      colorScheme: colorScheme,
      cardStyle: cardStyle,
      amoledDarkTheme: amoledDarkTheme,
      coloredBackground: coloredBackground,
    );

    final textTheme = GoogleFonts.manropeTextTheme();

    final themeData = ThemeData(
      useMaterial3: true,
      textTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeOutInTransitionBuilder(),
          TargetPlatform.iOS: FadeOutInTransitionBuilder(),
          TargetPlatform.macOS: FadeOutInTransitionBuilder(),
        },
      ),
      tooltipTheme: const TooltipThemeData(preferBelow: false),
      chipTheme: ChipThemeData(
        backgroundColor: solitaireThemeData.appBackgroundColor,
      ),
      dialogTheme: DialogTheme(
        titleTextStyle: textTheme.headlineSmall!
            .copyWith(color: colorScheme.onPrimaryContainer),
        contentTextStyle:
            textTheme.bodyMedium!.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );

    return SolitaireTheme(
      data: solitaireThemeData,
      child: MaterialApp(
        title: 'Solitaire',
        theme: themeData,
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
        navigatorObservers: [routeObserver],
      ),
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

    return FadeTransition(
      opacity: animation.drive(fadeOutCurve),
      child: RippleBackground(
        decoration:
            BoxDecoration(color: SolitaireTheme.of(context).appBackgroundColor),
        child: FadeTransition(
          opacity: secondaryAnimation
              .drive(Tween(begin: 1.0, end: 0.0).chain(fadeInCurve)),
          child: child,
        ),
      ),
    );
  }
}
