import 'package:flutter/material.dart';

class ProtocoloZColors {
  // Tons de Cinza (Bunker, Concreto, Aço e Cinzas)
  static const Color bgDarkest = Color(0xFF0E1311);
  static const Color bgBunker = Color(0xFF151C19);
  static const Color surfaceGray = Color(0xFF1E2723);
  static const Color cardGray = Color(0xFF26312C);
  static const Color borderGray = Color(0xFF3A4A42);
  static const Color steelGray = Color(0xFF78909C);
  static const Color textPrimary = Color(0xFFECEFF1);
  static const Color textMuted = Color(0xFF90A4AE);

  // Tons de Verde (Bio-Radar, Sobrevivência, Suprimentos e Zona Segura)
  static const Color radarGreen = Color(0xFF00E676);
  static const Color tacticalGreen = Color(0xFF2E7D32);
  static const Color mossGreen = Color(0xFF43A047);
  static const Color darkGreen = Color(0xFF1B3B24);
  static const Color acidGreen = Color(0xFF76FF03);

  // Tons de Vermelho (Alerta de Horda, Sangue, Risco Alto e Perigo)
  static const Color hordeRed = Color(0xFFFF1744);
  static const Color crimsonRed = Color(0xFFD32F2F);
  static const Color bloodRed = Color(0xFF8E0000);
  static const Color darkRedSurface = Color(0xFF2D1215);

  static Color parseHex(String hexString, {Color fallback = radarGreen}) {
    try {
      final clean = hexString.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }
}

class AppTheme {
  static ThemeData get darkSurvivalTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ProtocoloZColors.bgDarkest,
      primaryColor: ProtocoloZColors.radarGreen,
      colorScheme: const ColorScheme.dark(
        primary: ProtocoloZColors.radarGreen,
        onPrimary: ProtocoloZColors.bgDarkest,
        secondary: ProtocoloZColors.crimsonRed,
        onSecondary: Colors.white,
        tertiary: ProtocoloZColors.steelGray,
        surface: ProtocoloZColors.surfaceGray,
        onSurface: ProtocoloZColors.textPrimary,
        error: ProtocoloZColors.hordeRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ProtocoloZColors.bgBunker,
        foregroundColor: ProtocoloZColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ProtocoloZColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: ProtocoloZColors.cardGray,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: ProtocoloZColors.borderGray, width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ProtocoloZColors.bgBunker,
        labelStyle: const TextStyle(color: ProtocoloZColors.textMuted),
        hintStyle: const TextStyle(color: ProtocoloZColors.steelGray),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ProtocoloZColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ProtocoloZColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ProtocoloZColors.radarGreen,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ProtocoloZColors.hordeRed,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ProtocoloZColors.tacticalGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: ProtocoloZColors.radarGreen, width: 1),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ProtocoloZColors.cardGray,
        contentTextStyle: const TextStyle(
          color: ProtocoloZColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: ProtocoloZColors.radarGreen),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: ProtocoloZColors.borderGray,
        thickness: 1,
      ),
    );
  }
}
