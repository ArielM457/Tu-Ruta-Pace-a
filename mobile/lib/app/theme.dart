import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class CableCarLineColors {
  static const Color red = Color(0xFFD32F2F);
  static const Color yellow = Color(0xFFF9A825);
  static const Color green = Color(0xFF2E7D32);
  static const Color blue = Color(0xFF1565C0);
  static const Color skyBlue = Color(0xFF4FC3F7);
  static const Color orange = Color(0xFFEF6C00);
  static const Color white = Color(0xFFECEFF1);
  static const Color purple = Color(0xFF6A1B9A);
  static const Color brown = Color(0xFF5D4037);
  static const Color silver = Color(0xFF90A4AE);
}

abstract final class ChasquiColors {
  static const Color yellow50 = Color(0xFFFFFBE8);
  static const Color yellow100 = Color(0xFFFFF7D0);
  static const Color yellow200 = Color(0xFFFFF2B9);
  static const Color yellow300 = Color(0xFFFFEEA2);
  static const Color yellow400 = Color(0xFFFFE673);
  static const Color yellow500 = Color(0xFFFFDD45);
  static const Color yellow600 = Color(0xFFFFD516);
  static const Color yellow700 = Color(0xFFCCAA12);
  static const Color yellow800 = Color(0xFF99800D);

  static const Color orange300 = Color(0xFFF9BFA5);
  static const Color orange400 = Color(0xFFF79E79);
  static const Color orange500 = Color(0xFFF47E4C);
  static const Color orange600 = Color(0xFFF15E1F);
  static const Color orange700 = Color(0xFFC14B19);
  static const Color orange800 = Color(0xFF913813);

  static const Color warm200 = Color(0xFFF7DFC3);
  static const Color warm300 = Color(0xFFF4D4AF);
  static const Color warm400 = Color(0xFFEEBF88);
  static const Color warm500 = Color(0xFFE9A960);
  static const Color warm600 = Color(0xFFE39438);
  static const Color warm700 = Color(0xFFB6762D);
  static const Color warm800 = Color(0xFF885922);

  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFEFEFEF);
  static const Color neutral200 = Color(0xFFDCDCDC);
  static const Color neutral300 = Color(0xFFBDBDBD);
  static const Color neutral400 = Color(0xFF989898);
  static const Color neutral500 = Color(0xFF7C7C7C);
  static const Color neutral600 = Color(0xFF656565);
  static const Color neutral700 = Color(0xFF525252);
  static const Color neutral800 = Color(0xFF464646);
  static const Color neutral900 = Color(0xFF3D3D3D);
  static const Color neutral950 = Color(0xFF292929);

  static const Color success = Color(0xFF38A169);
  static const Color successText = Color(0xFF276749);
  static const Color successSurface = Color(0xFFDCF5E7);

  static const Color cardShadow = Color(0x0D000000);
}

abstract final class AppTheme {
  static ThemeData light() => _chasquiTheme();

  static ThemeData dark() => _chasquiTheme();

  static ThemeData _chasquiTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: ChasquiColors.yellow600,
      onPrimary: ChasquiColors.neutral950,
      primaryContainer: ChasquiColors.yellow200,
      onPrimaryContainer: ChasquiColors.yellow800,
      secondary: ChasquiColors.orange600,
      onSecondary: Colors.white,
      secondaryContainer: ChasquiColors.warm200,
      onSecondaryContainer: ChasquiColors.warm800,
      tertiary: ChasquiColors.warm600,
      onTertiary: Colors.white,
      error: ChasquiColors.orange600,
      onError: Colors.white,
      errorContainer: ChasquiColors.warm200,
      onErrorContainer: ChasquiColors.orange700,
      surface: Colors.white,
      onSurface: ChasquiColors.neutral950,
      surfaceContainerHighest: ChasquiColors.neutral100,
      onSurfaceVariant: ChasquiColors.neutral500,
      outline: ChasquiColors.neutral200,
      outlineVariant: ChasquiColors.neutral100,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: ChasquiColors.neutral950,
      onInverseSurface: Colors.white,
      inversePrimary: ChasquiColors.yellow300,
    );

    final textTheme = _nunitoSansTextTheme();

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ChasquiColors.neutral50,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ChasquiColors.neutral950,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: ChasquiColors.neutral950,
        ),
        shape: const Border(
          bottom: BorderSide(color: ChasquiColors.neutral100),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ChasquiColors.neutral100),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ChasquiColors.yellow600,
          foregroundColor: ChasquiColors.neutral950,
          disabledBackgroundColor: ChasquiColors.neutral100,
          disabledForegroundColor: ChasquiColors.neutral400,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ChasquiColors.neutral950,
          side: const BorderSide(color: ChasquiColors.neutral200),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ChasquiColors.yellow800,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ChasquiColors.neutral50,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: ChasquiColors.neutral400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChasquiColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ChasquiColors.yellow600,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChasquiColors.orange600),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ChasquiColors.orange600,
            width: 1.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ChasquiColors.neutral50,
        selectedColor: ChasquiColors.yellow600,
        side: const BorderSide(color: ChasquiColors.neutral200),
        labelStyle: textTheme.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: ChasquiColors.neutral900,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ChasquiColors.neutral950,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ChasquiColors.neutral100,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: ChasquiColors.neutral500,
        textColor: ChasquiColors.neutral950,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ChasquiColors.yellow600,
        foregroundColor: ChasquiColors.neutral950,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ChasquiColors.yellow700,
      ),
    );
  }

  static TextTheme _nunitoSansTextTheme() {
    final base = GoogleFonts.nunitoSansTextTheme();
    return base
        .apply(
          bodyColor: ChasquiColors.neutral950,
          displayColor: ChasquiColors.neutral950,
        )
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: ChasquiColors.neutral950,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: ChasquiColors.neutral950,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: ChasquiColors.neutral950,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: ChasquiColors.neutral950,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: ChasquiColors.neutral950,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            color: ChasquiColors.neutral900,
          ),
          bodySmall: base.bodySmall?.copyWith(
            color: ChasquiColors.neutral500,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: ChasquiColors.neutral400,
          ),
        );
  }
}
