import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/game_screen.dart';

class SolitaireApp extends StatelessWidget {
  const SolitaireApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ThemeData buildTheme(ColorScheme? colorScheme) {
          return ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.dosisTextTheme(),
            colorScheme: colorScheme,
          );
        }

        return ChangeNotifierProvider(
          create: (_) => ThemeChanger(),
          builder: (context, child) {
            return MaterialApp(
              title: 'Solitaire',
              theme: buildTheme(lightDynamic),
              darkTheme: buildTheme(darkDynamic),
              themeMode: context.watch<ThemeChanger>().current,
              home: const GameScreen(),
            );
          },
        );
      },
    );
  }
}

class ThemeChanger extends ChangeNotifier {
  ThemeMode _currentThemeMode = ThemeMode.system;

  void change(ThemeMode newMode) {
    _currentThemeMode = newMode;
    notifyListeners();
  }

  ThemeMode get current => _currentThemeMode;
}
