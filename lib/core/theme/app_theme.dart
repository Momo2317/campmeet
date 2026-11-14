import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFFF2D9B), Color(0xFF9B30FF), Color(0xFF5B2BF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [Color(0xFF9B30FF), Color(0xFF5B2BF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F0B24),
      Color(0xFF0F0B24),
      Color(0xFF0F0B24),
    ],
  );

  static const backgroundColor = Color(0xFF0F0B24);
  static const cardColor = Color(0xFF1A1536);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: const Color(0xFF9B30FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9B30FF),
        secondary: Color(0xFF9B30FF),
        surface: cardColor,
      ),
      textTheme: ThemeData.dark().textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  static const lightBackgroundColor = Color(0xFFF7F6FB);
  static const lightCardColor = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackgroundColor,
      primaryColor: const Color(0xFF9B30FF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF9B30FF),
        secondary: Color(0xFF9B30FF),
        surface: lightCardColor,
      ),
      textTheme: ThemeData.light().textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF21262E)),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF21262E),
        ),
      ),
    );
  }
}

/// Theme-abhängige Farben statt fester Weiß/Dunkel-Werte.
extension AppColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Seitenhintergrund
  Color get bg =>
      isDark ? AppTheme.backgroundColor : AppTheme.lightBackgroundColor;

  /// Karten / Flächen
  Color get card => isDark ? AppTheme.cardColor : AppTheme.lightCardColor;

  /// Haupttext (im Dunkeln weiß, im Hellen fast schwarz)
  Color get fg => isDark ? Colors.white : const Color(0xFF21262E);

  /// Abgeschwächte Text-/Linienfarbe mit Deckkraft [a]
  Color fgA(double a) => fg.withValues(alpha: a);

  /// Dialoge / Sheets
  Color get surface => isDark ? const Color(0xFF231D45) : Colors.white;
}

const _kThemeModeKey = 'campmeet_theme_mode';

/// Hell / Dunkel / Auto (System), gespeichert auf dem Gerät.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_kThemeModeKey);
      state = ThemeMode.values.firstWhere(
        (m) => m.name == v,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {}
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeModeKey, mode.name);
    } catch (_) {}
  }
}
