import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'animations.dart';
import 'models/game_theme.dart';
import 'providers/settings.dart';
import 'providers/themes.dart';
import 'screens/about/about_screen.dart';
import 'screens/game_select/game_selection_screen.dart';
import 'screens/help/help_screen.dart';
import 'screens/main/game_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/statistics/statistics_screen.dart';
import 'screens/theme/theme_screen.dart';
import 'services/system_window.dart';
import 'widgets/screen_visibility.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const GameScreen(),
      routes: [
        GoRoute(
          path: 'select',
          builder: (context, state) => const GameSelectionScreen(),
        ),
        GoRoute(
          path: 'theme',
          builder: (context, state) => const ThemeScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'statistics',
          builder: (context, state) => const StatisticsScreen(),
        ),
        GoRoute(
          path: 'help',
          builder: (context, state) => const HelpScreen(),
        ),
        GoRoute(
          path: 'about',
          builder: (context, state) => const AboutScreen(),
        ),
      ],
    ),
  ],
  observers: [screenVisibilityRouteObserver],
);

class SolitaireApp extends ConsumerWidget {
  const SolitaireApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(settingsScreenOrientationProvider, (_, orientation) {
      SystemWindow.changeOrientation(orientation);
    });
    ref.listen(settingsShowStatusBarProvider, (_, visible) {
      SystemWindow.setStatusBarVisibility(visible);
    });
    ref.listen(themeBaseModeProvider, (_, themeMode) {
      SystemWindow.setStatusBarTheme(switch (themeMode) {
        ThemeMode.dark => Brightness.light,
        ThemeMode.light => Brightness.dark,
        ThemeMode.system => Brightness.dark,
      });
    });

    ThemeMode themeMode = ref.watch(themeBaseModeProvider);
    final themeColor = ref.watch(themeBaseColorProvider);
    final coloredBackground = ref.watch(themeBackgroundColoredProvider);
    final amoledDarkTheme = ref.watch(themeBackgroundAmoledProvider);

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

    final colorScheme = SeedColorScheme.fromSeeds(
      brightness: brightness,
      primaryKey: themeColor != Colors.transparent
          ? themeColor
          : themeColorPalette.first,
      // variant: FlexSchemeVariant.tonalSpot,
      tones: switch (brightness) {
        Brightness.light =>
          FlexTones.material(brightness).copyWith(primaryTone: 50),
        Brightness.dark => FlexTones.material(brightness),
      },
    );

    GameCardTheme cardTheme = GameCardTheme.from(
      colorScheme: colorScheme,
      tintedCardFace: amoledDarkTheme && themeMode == ThemeMode.dark,
      useClassicColors: ref.watch(themeUseClassicCardColorsProvider),
      contrastingFaceColors: ref.watch(themeUseContrastingCardColorsProvider),
    ).copyWith(
      compressStack: ref.watch(themeCompressCardStackProvider),
    );

    GameTheme gameTheme = GameTheme.from(
      colorScheme: colorScheme,
      coloredBackground: coloredBackground,
    );

    ThemeData appTheme = ThemeData(
      useMaterial3: true,
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
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // width: 400,
      ),
      scrollbarTheme: const ScrollbarThemeData(),
      extensions: [gameTheme, cardTheme],
    );

    appTheme = appTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(appTheme.textTheme),
    );

    if (amoledDarkTheme && themeMode == ThemeMode.dark) {
      appTheme = appTheme.copyWith(
        scaffoldBackgroundColor: Colors.black,
        extensions: [
          gameTheme.copyWith(
            tableBackgroundColor: Colors.black,
          ),
          cardTheme
        ],
      );
    }

    return MaterialApp.router(
      routerConfig: _router,
      title: 'Solitaire',
      theme: appTheme,
      themeAnimationStyle: AnimationStyle.noAnimation,
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
      child: FadeTransition(
        opacity: secondaryAnimation
            .drive(Tween(begin: 1.0, end: 0.0).chain(fadeInCurve)),
        child: child,
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
        CurveTween(curve: popupAnimation.curve).animate(animation);

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
