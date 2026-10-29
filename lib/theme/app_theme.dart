import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6D28D9),
    brightness: Brightness.light,
    surface: const Color(0xFFFFFFFF),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF8FAFF),
    fontFamily: 'Changa',
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE7E5F4))),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(color: Color(0xFF1E1B4B), fontFamily: 'Changa', fontSize: 20, fontWeight: FontWeight.w900),
      iconTheme: IconThemeData(color: Color(0xFF4338CA)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)), textStyle: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.w900)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52), side: const BorderSide(color: Color(0xFFC4B5FD)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)), textStyle: const TextStyle(fontFamily: 'Changa', fontWeight: FontWeight.w900)),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: const Size(48, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFEDE9FE),
      elevation: 8,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) => TextStyle(fontFamily: 'Changa', fontSize: 11, fontWeight: FontWeight.w900, color: states.contains(WidgetState.selected) ? const Color(0xFF5B21B6) : const Color(0xFF64748B))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF1E1B4B),
      contentTextStyle: const TextStyle(fontFamily: 'Changa', color: Colors.white, fontWeight: FontWeight.w800),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
  );
}
