import 'package:flutter/material.dart';

class AppTheme {
  static const _fontFamily = 'Segoe UI';

  // Sequel Ace inspired dark theme colors
  static const _darkBackground = Color(0xFF1E1E1E);
  static const _darkSurface = Color(0xFF252526);
  static const _darkSurfaceVariant = Color(0xFF2D2D30);
  static const _darkBorder = Color(0xFF3C3C3C);
  static const _darkText = Color(0xFFD4D4D4);
  static const _darkTextSecondary = Color(0xFF808080);
  static const _accentBlue = Color(0xFF0078D4);
  static const _accentGreen = Color(0xFF4EC9B0);
  static const _accentOrange = Color(0xFFCE9178);
  static const _accentYellow = Color(0xFFDCDCAA);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: _accentBlue,
        secondary: _accentGreen,
        surface: _darkSurface,
        onSurface: _darkText,
        outline: _darkBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkText,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _darkText,
        ),
      ),
      dividerColor: _darkBorder,
      dividerTheme: const DividerThemeData(
        color: _darkBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: _darkTextSecondary,
        size: 18,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: _darkText, fontSize: 13),
        bodyMedium: TextStyle(color: _darkText, fontSize: 12),
        bodySmall: TextStyle(color: _darkTextSecondary, fontSize: 11),
        labelLarge: TextStyle(color: _darkText, fontSize: 12),
        labelMedium: TextStyle(color: _darkTextSecondary, fontSize: 11),
        titleMedium: TextStyle(color: _darkText, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _accentBlue),
        ),
        hintStyle: const TextStyle(color: _darkTextSecondary, fontSize: 12),
        labelStyle: const TextStyle(color: _darkTextSecondary, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentBlue,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 12),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: _darkText,
        unselectedLabelColor: _darkTextSecondary,
        indicatorColor: _accentBlue,
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minVerticalPadding: 0,
        visualDensity: VisualDensity.compact,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(_darkBorder),
        thickness: WidgetStateProperty.all(8),
        radius: const Radius.circular(4),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _darkSurfaceVariant,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _darkBorder),
        ),
        textStyle: const TextStyle(color: _darkText, fontSize: 11),
      ),
    );
  }

  // Editor specific colors
  static const editorBackground = _darkSurfaceVariant;
  static const editorLineNumber = _darkTextSecondary;
  static const editorCursor = _darkText;
  static const editorSelection = Color(0xFF264F78);

  // Syntax highlighting
  static const syntaxKeyword = Color(0xFF569CD6);
  static const syntaxString = _accentOrange;
  static const syntaxNumber = Color(0xFFB5CEA8);
  static const syntaxComment = Color(0xFF6A9955);
  static const syntaxFunction = _accentYellow;
  static const syntaxType = _accentGreen;

  // Grid colors
  static const gridHeader = _darkSurface;
  static const gridRowEven = _darkBackground;
  static const gridRowOdd = Color(0xFF232323);
  static const gridBorder = _darkBorder;
  static const gridNull = Color(0xFF6C6C6C);

  // Status colors
  static const statusConnected = Color(0xFF4EC9B0);
  static const statusDisconnected = Color(0xFF808080);
  static const statusError = Color(0xFFF14C4C);
  static const statusWarning = Color(0xFFCCA700);
}
