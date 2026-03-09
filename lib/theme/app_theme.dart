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

  // Primary palette
  static const Color primary = Color(0xFF1565C0);        // Deep Blue
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);

  // Semantic colors
  static const Color moneyReceived = Color(0xFF2E7D32);  // Green — profit, received
  static const Color moneyReceivedLight = Color(0xFF66BB6A);
  static const Color moneyOwed = Color(0xFFC62828);      // Red — owed, negative
  static const Color moneyOwedLight = Color(0xFFEF5350);
  static const Color info = Color(0xFF1565C0);           // Blue — info
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color warning = Color(0xFFE65100);        // Orange — warning, pending
  static const Color warningLight = Color(0xFFFF9800);

  // Neutral
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFFAFAFA);
  static const Color disabled = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnGreen = Colors.white;
  static const Color textOnRed = Colors.white;

  // Card gradients
  static const LinearGradient salesGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient profitGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient receivableGradient = LinearGradient(
    colors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient payableGradient = LinearGradient(
    colors: [Color(0xFFC62828), Color(0xFFEF5350)],
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
    color: AppColors.textPrimary,
  );

  static TextStyle urduTitle = GoogleFonts.notoNastaliqUrdu(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle urduBody = GoogleFonts.notoNastaliqUrdu(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static TextStyle urduCaption = GoogleFonts.notoNastaliqUrdu(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // English / Number styles
  static const TextStyle amountLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    fontFamily: 'Roboto',
    letterSpacing: 0.5,
  );

  static const TextStyle amountMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    fontFamily: 'Roboto',
  );

  static const TextStyle amountSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: 'Roboto',
  );

  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

/// App-wide dimensions & spacing
class AppDimens {
  AppDimens._();

  // Touch targets (per requirements: minimum 56dp, 80dp for main actions)
  static const double minTouchTarget = 56.0;
  static const double mainActionTarget = 80.0;
  static const double fabSize = 64.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;

  // Border radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;

  // Card
  static const double cardElevation = 2.0;
  static const double cardPadding = 16.0;

  // Icon sizes
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
        surface: AppColors.surface,
        error: AppColors.moneyOwed,
      ),
      scaffoldBackgroundColor: AppColors.background,
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
      cardTheme: CardThemeData(
        elevation: AppDimens.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacingMD,
          vertical: AppDimens.spacingSM,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppDimens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.moneyReceived,
        foregroundColor: Colors.white,
        extendedPadding: EdgeInsets.symmetric(horizontal: 24),
        largeSizeConstraints: BoxConstraints(
          minWidth: AppDimens.fabSize,
          minHeight: AppDimens.fabSize,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.disabled,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.notoNastaliqUrdu(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.notoNastaliqUrdu(fontSize: 12),
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacingMD,
          vertical: AppDimens.spacingMD,
        ),
        labelStyle: const TextStyle(fontSize: 16),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSM),
        ),
      ),
    );
  }
}
