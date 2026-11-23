import 'package:flutter/material.dart';

class Usa94Colors {
  static const Color bg = Color(0xFFF6F2E8);
  static const Color paper = Color(0xFFFFFDF6);
  static const Color ink = Color(0xFF142B69);
  static const Color muted = Color(0xFF68738C);
  static const Color lime = Color(0xFFF6CE59);
  static const Color gold = Color(0xFFF6CE59);
  static const Color red = Color(0xFFD83B46);
  static const Color royal = Color(0xFF244BB6);
  static const Color blueDeep = Color(0xFF234DB7);
}

ThemeData buildUsa94Theme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: Usa94Colors.royal,
      secondary: Usa94Colors.red,
      surface: Usa94Colors.paper,
      onPrimary: Usa94Colors.paper,
      onSecondary: Usa94Colors.paper,
      onSurface: Usa94Colors.ink,
      error: Usa94Colors.red,
    ),
    scaffoldBackgroundColor: Usa94Colors.bg,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Usa94Colors.bg,
      foregroundColor: Usa94Colors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Usa94Colors.royal,
        foregroundColor: Usa94Colors.paper,
        minimumSize: const Size.fromHeight(49),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: const BorderSide(color: Usa94Colors.ink),
        ),
        elevation: 0,
        shadowColor: Usa94Colors.ink,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Usa94Colors.ink,
        backgroundColor: Usa94Colors.paper,
        minimumSize: const Size.fromHeight(49),
        side: const BorderSide(color: Usa94Colors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFAF9F3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCFD4DF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCFD4DF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Usa94Colors.royal, width: 2),
      ),
      labelStyle: const TextStyle(color: Usa94Colors.muted),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Usa94Colors.ink,
      displayColor: Usa94Colors.ink,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Usa94Colors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: Usa94Colors.ink, width: 2),
      ),
    ),
  );
}
