import 'package:flutter/material.dart';

class AppTheme {
  // Fortnite-inspired color palette
  static const Color fnBgDark = Color(0xFF1A1A1A);
  static const Color fnBgMedium = Color(0xFF2A2A2A);
  static const Color fnBgLight = Color(0xFF3C3C3C);
  static const Color fnBorderColor = Color(0xFF4A4A4A);

  static const Color fnTextPrimary = Color(0xFFFFFFFF);
  static const Color fnTextSecondary = Color(0xFFAAAAAA);
  static const Color fnTextDisabled = Color(0xFF757575);

  // Accent colors
  static const Color fortniteBlue = Color(0xFF00BFFF);
  static const Color fortnitePurple = Color(0xFF8A2BE2);
  static const Color fnAccentRed = Color(0xFFE53935);
  static const Color fnAccentGreen = Color(0xFF4CAF50);
  static const Color fnAccentOrange = Color(0xFFFF9800);

  // Font families
  static const String fontDisplay = 'BurbankBigCondensed';
  static const String fontBody = 'Lato';

  static ThemeData getThemeData({required Color primaryAccent}) {
    final Brightness accentBrightness =
        ThemeData.estimateBrightnessForColor(primaryAccent);
    final Color onPrimaryAccent =
        accentBrightness == Brightness.dark ? fnTextPrimary : fnBgDark;

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: fnBgDark,

      colorScheme: ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: fnBgMedium,
        error: fnAccentRed,
        onPrimary: onPrimaryAccent,
        onSecondary: onPrimaryAccent,
        onSurface: fnTextPrimary,
        onError: fnTextPrimary,
      ),

      fontFamily: fontBody,

      appBarTheme: AppBarTheme(
        backgroundColor: fnBgMedium,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: fnTextSecondary, size: 22),
        titleTextStyle: TextStyle(
          fontFamily: fontDisplay,
          color: fnTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 1.2,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: fontDisplay, color: fnTextPrimary, fontWeight: FontWeight.bold, fontSize: 52, letterSpacing: 1.2),
        displayMedium: TextStyle(fontFamily: fontDisplay, color: fnTextPrimary, fontWeight: FontWeight.bold, fontSize: 40, letterSpacing: 1.1),
        displaySmall: TextStyle(fontFamily: fontDisplay, color: fnTextPrimary, fontWeight: FontWeight.w600, fontSize: 32),
        headlineLarge: TextStyle(fontFamily: fontDisplay, color: fnTextPrimary, fontWeight: FontWeight.bold, fontSize: 24),
        headlineMedium: TextStyle(fontFamily: fontDisplay, color: fnTextPrimary, fontWeight: FontWeight.w600, fontSize: 22),
        headlineSmall: TextStyle(fontFamily: fontDisplay, color: fnTextPrimary, fontWeight: FontWeight.w500, fontSize: 20),
        titleLarge: TextStyle(fontFamily: fontBody, color: fnTextPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        titleMedium: TextStyle(fontFamily: fontBody, color: fnTextPrimary, fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: TextStyle(fontFamily: fontBody, color: fnTextSecondary, fontSize: 14, fontWeight: FontWeight.w400),
        bodyLarge: TextStyle(fontFamily: fontBody, color: fnTextPrimary, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontFamily: fontBody, color: fnTextSecondary, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(fontFamily: fontBody, color: fnTextSecondary, fontSize: 12, height: 1.3),
        labelLarge: TextStyle(fontFamily: fontBody, color: onPrimaryAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16),
        labelMedium: TextStyle(fontFamily: fontBody, color: fnTextSecondary, letterSpacing: 1.0, fontSize: 14),
        labelSmall: TextStyle(fontFamily: fontBody, color: fnTextSecondary, letterSpacing: 0.8, fontSize: 12),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: onPrimaryAccent,
          textStyle: TextStyle(fontFamily: fontDisplay, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          elevation: 4,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primaryAccent, width: 2),
          foregroundColor: primaryAccent,
          textStyle: TextStyle(fontFamily: fontDisplay, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryAccent,
          textStyle: TextStyle(fontFamily: fontBody, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fnBgLight.withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(color: fnTextSecondary.withOpacity(0.7), fontFamily: fontBody, fontSize: 14),
        labelStyle: TextStyle(color: fnTextSecondary, fontFamily: fontBody, fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: fnBorderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: fnBorderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: primaryAccent, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: fnAccentRed.withOpacity(0.7), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: fnAccentRed, width: 2.5),
        ),
        prefixIconColor: fnTextSecondary,
        suffixIconColor: fnTextSecondary,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryAccent,
        linearTrackColor: fnBgLight,
        circularTrackColor: fnBgLight,
        linearMinHeight: 6,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: fnBgLight,
        labelStyle: TextStyle(color: fnTextPrimary, fontFamily: fontBody, fontSize: 12),
        selectedColor: primaryAccent,
        secondarySelectedColor: primaryAccent.withOpacity(0.7),
        disabledColor: fnBorderColor.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: fnBorderColor.withOpacity(0.3)),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primaryAccent,
        unselectedLabelColor: fnTextSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryAccent, width: 3.0),
        ),
        labelStyle: TextStyle(fontFamily: fontDisplay, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.8),
        unselectedLabelStyle: TextStyle(fontFamily: fontDisplay, fontWeight: FontWeight.w500, fontSize: 16, letterSpacing: 0.8),
        indicatorSize: TabBarIndicatorSize.label,
      ),

      iconTheme: const IconThemeData(
        color: fnTextSecondary,
        size: 24,
      ),

      tooltipTheme: TooltipThemeData(
        preferBelow: false,
        textStyle: TextStyle(fontSize: 12, color: fnBgDark, fontFamily: fontBody),
        decoration: BoxDecoration(
          color: fortniteBlue.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: fnBorderColor.withOpacity(0.6),
        thickness: 1,
        space: 1,
      ),

      cardTheme: CardThemeData(
        color: fnBgMedium,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: fnBorderColor.withOpacity(0.5), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: fnTextSecondary,
        textColor: fnTextPrimary,
        tileColor: Colors.transparent,
        selectedTileColor: primaryAccent.withOpacity(0.15),
        titleTextStyle: TextStyle(fontFamily: fontBody, fontSize: 16, fontWeight: FontWeight.w600),
        subtitleTextStyle: TextStyle(fontFamily: fontBody, fontSize: 14, color: fnTextSecondary),
        minVerticalPadding: 14,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return primaryAccent;
          return fnTextSecondary.withOpacity(0.8);
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) return primaryAccent.withOpacity(0.4);
          return fnBorderColor.withOpacity(0.4);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: fnBgMedium,
        titleTextStyle: TextStyle(fontFamily: fontDisplay, color: fnTextPrimary, fontSize: 22, fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(fontFamily: fontBody, color: fnTextPrimary, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        elevation: 6,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: fnBgMedium,
          selectedItemColor: primaryAccent,
          unselectedItemColor: fnTextSecondary.withOpacity(0.8),
          selectedLabelStyle: TextStyle(fontSize: 12, fontFamily: fontDisplay, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          unselectedLabelStyle: TextStyle(fontSize: 12, fontFamily: fontDisplay, letterSpacing: 0.8),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
      ),
    );
  }
}