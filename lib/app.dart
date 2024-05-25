import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/settings.dart';
import 'screens/about_screen.dart';
import 'screens/customize_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'services/system_orientation.dart';
import 'widgets/ripple_background.dart';
import 'widgets/solitaire_theme.dart';

class SolitaireApp extends ConsumerWidget {
  const SolitaireApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    ref.listen(appScreenOrientationProvider, (_, orientation) {
      ScreenOrientationManager.change(orientation);
    });

    ThemeMode themeMode = ref.watch(appThemeModeProvider);
    final themeColor = ref.watch(appThemeColorProvider);
    final coloredBackground = ref.watch(coloredBackgroundProvider);
    final amoledDarkTheme = ref.watch(amoledBackgroundProvider);

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

    if (ref.watch(standardCardColorProvider)) {
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
        coloredBackground: coloredBackground,
      );
    }

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
          '/customize': (context) => const CustomizeScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/stats': (context) => const StatisticsScreen(),
          '/about': (context) => const AboutScreen(),
        },
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
