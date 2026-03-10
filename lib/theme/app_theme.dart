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

  // 10% Accent Palette (Stark Black for modern contrast)
  static const Color primary = Color(0xFF000000);        // Pure Black
  static const Color primaryLight = Color(0xFF333333);
  static const Color primaryDark = Color(0xFF000000);

  // Semantic colors (High contrast, professional)
  static const Color moneyReceived = Color(0xFF198754);  // Bold Green
  static const Color moneyReceivedLight = Color(0xFF28A745);
  static const Color moneyOwed = Color(0xFFDC3545);      // Crimson Red
  static const Color moneyOwedLight = Color(0xFFE35D6A);
  static const Color info = Color(0xFF0D6EFD);           // Bold Blue
  static const Color infoLight = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFFD7E14);        // Orange
  static const Color warningLight = Color(0xFFFFA94D);

  // 60% Dominant (Whites & Off-whites) & 30% Secondary (Greys / Near Black)
  static const Color background = Color(0xFFF8F9FA); // 60% Light Background
  static const Color surface = Colors.white;         // 60% Clear White Cards
  static const Color surfaceVariant = Color(0xFFE9ECEF);
  static const Color disabled = Color(0xFFCED4DA);
  static const Color divider = Color(0xFFDEE2E6);
  
  static const Color textPrimary = Color(0xFF212529); // 30% Dark Grey (Highly readable)
  static const Color textSecondary = Color(0xFF6C757D); // 30% Medium Grey
  
  static const Color textOnPrimary = Colors.white;
  static const Color textOnGreen = Colors.white;
  static const Color textOnRed = Colors.white;

  // Modern Card gradients (Subtle, sleek)
  static const LinearGradient salesGradient = LinearGradient(
    colors: [Color(0xFF212529), Color(0xFF343A40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient profitGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF212529)],
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

  // English / Number styles (Using Inter for modern professional look)
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
    color: AppColors.textPrimary,
  );

  static TextStyle title = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle subtitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static TextStyle label = GoogleFonts.inter(
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
