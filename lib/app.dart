import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/settings.dart';
import 'providers/themes.dart';
import 'screens/about_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/theme_screen.dart';
import 'services/route_observer.dart';
import 'services/system_window.dart';
import 'widgets/ripple_background.dart';
import 'widgets/solitaire_theme.dart';

class SolitaireApp extends ConsumerWidget {
  const SolitaireApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(settingsScreenOrientationProvider, (_, orientation) {
      SystemWindow.changeOrientation(orientation);
    });
    ref.listen(settingsShowStatusBarProvider, (_, visible) {
      SystemWindow.setStatusBarVisibility(visible);
    });

    ThemeMode themeMode = ref.watch(themeBaseModeProvider);
    final themeColor = ref.watch(themeBaseColorProvider);
    final coloredBackground = ref.watch(themeBackgroundColoredProvider);
    final amoledDarkTheme = ref.watch(themeBackgroundAmoledProvider);

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

    final cardStyle = SolitaireCardStyle.fromColorScheme(
      colorScheme,
      tintedCardFace: amoledDarkTheme && themeMode == ThemeMode.dark,
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SlideUpTransitionBuilder(),
          TargetPlatform.iOS: SlideUpTransitionBuilder(),
          TargetPlatform.macOS: SlideUpTransitionBuilder(),
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
        initialRoute: '/game',
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

class SlideUpTransitionBuilder extends PageTransitionsBuilder {
  const SlideUpTransitionBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    final colorScheme = Theme.of(context).colorScheme;
    final curvedAnimation =
        CurveTween(curve: Easing.emphasizedDecelerate).animate(animation);

    return Stack(
      children: [
        DecoratedBoxTransition(
          decoration: DecorationTween(
            begin: const BoxDecoration(color: Colors.transparent),
            end: BoxDecoration(color: colorScheme.surface),
          ).animate(animation),
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: const Offset(0, 0),
            ).animate(curvedAnimation),
            child: child,
          ),
        ),
      ],
    );
  }
}
