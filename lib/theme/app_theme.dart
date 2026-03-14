import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App color constants following the requirements:
/// GREEN  = money received, profit, positive balance
/// RED    = money owed, alerts, delete
/// BLUE   = information, navigation, neutral actions
/// ORANGE = warnings, pending, partial
/// GRAY   = inactive, disabled
class AppColors {
  AppColors._();

  // Stitch Primary (Teal)
  static const Color primary = Color(0xFF006C75);        
  static const Color primaryLight = Color(0xFF338991);
  static const Color primaryDark = Color(0xFF00565E);

  // Semantic colors 
  static const Color moneyReceived = Color(0xFF20C997);
  static const Color moneyOwed = Color(0xFFE8596A);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFFD7E14);

  // ── Day / Sunlight Mode ──
  static const Color lightBackground = Color(0xFFF5F8F8);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightDivider    = Color(0xFFE5E7EB);

  // ── Night / Dark Mode ──
  static const Color darkBackground  = Color(0xFF0F2223);
  static const Color darkSurface     = Color(0xFF1A2A3A);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkDivider     = Color(0xFF374151);

  // Common
  static const Color textOnPrimary = Color(0xFF111827); // Dark text on gold buttons
  static const Color textOnGreen = Colors.white;
  static const Color textOnRed = Colors.white;

  // Gradients
  static const LinearGradient profitGradient = LinearGradient(
    colors: [Color(0xFF006C75), Color(0xFF00565E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Backward-compatible aliases (used by existing screens, map to dark mode) ──
  static const Color charcoal = darkBackground;
  static const Color warmBeige = lightBackground;
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceVariant = lightSurface;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color divider = darkDivider;
  static const Color disabled = Color(0xFF6B7280);
  static const Color success = moneyReceived;   // green
  static const Color error = moneyOwed;         // red
  static const Color textMain = textPrimary;    // main text

  static const LinearGradient salesGradient = LinearGradient(
    colors: [Color(0xFF2A3440), Color(0xFF354454)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient receivableGradient = LinearGradient(
    colors: [Color(0xFF198754), Color(0xFF20C997)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient payableGradient = LinearGradient(
    colors: [Color(0xFFDC3545), Color(0xFFE8596A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// App text styles — minimum 16sp for regular text, 24sp+ for amounts
class AppTextStyles {
  AppTextStyles._();

  // Urdu font
  static TextStyle urduHeading = GoogleFonts.notoNastaliqUrdu(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle urduTitle = GoogleFonts.notoNastaliqUrdu(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static TextStyle urduBody = GoogleFonts.notoNastaliqUrdu(
    fontSize: 16,
  );

  static TextStyle urduCaption = GoogleFonts.notoNastaliqUrdu(
    fontSize: 14,
  );

  // English / Number styles
  static TextStyle amountLarge = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static TextStyle amountMedium = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static TextStyle amountSmall = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle heading = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static TextStyle title = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static TextStyle subtitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 16,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 14,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}

/// App-wide dimensions & spacing
class AppDimens {
  AppDimens._();

  static const double minTouchTarget = 56.0;
  static const double mainActionTarget = 80.0;
  static const double fabSize = 64.0;
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double cardElevation = 2.0;
  static const double cardPadding = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;
}

/// Complete app theme
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        surface: AppColors.lightSurface,
        error: AppColors.moneyOwed,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoNastaliqUrdu(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textOnPrimary,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: AppDimens.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMD)),
        margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD, vertical: AppDimens.spacingSM),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, AppDimens.minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMD)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        extendedPadding: EdgeInsets.symmetric(horizontal: 24),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD, vertical: AppDimens.spacingMD),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightDivider, thickness: 1, space: 1),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        surface: AppColors.darkSurface,
        error: AppColors.moneyOwed,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoNastaliqUrdu(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: AppDimens.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMD)),
        margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD, vertical: AppDimens.spacingSM),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(double.infinity, AppDimens.minTouchTarget),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMD)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        extendedPadding: EdgeInsets.symmetric(horizontal: 24),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingMD, vertical: AppDimens.spacingMD),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkDivider, thickness: 1, space: 1),
    );
  }
}
