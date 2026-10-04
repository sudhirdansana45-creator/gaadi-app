import 'package:flutter/material.dart';

class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color background;
  final Color canvasLow;
  final Color canvasSub;
  final Color surfaceCard;
  final Color surfaceHover;
  final Color surfaceSheet;
  final Color surfaceHigh;
  final Color borderHairline;
  final Color borderSubtle;
  final Color borderFocused;
  final Color primaryCyan;
  final Color primaryCyanLight;
  final Color primaryBlue;
  final Color primaryBlueLight;
  final Color successGreen;
  final Color successGreenDark;
  final Color successBg;
  final Color successBorder;
  final Color warningAmber;
  final Color warningAmberDark;
  final Color warningBg;
  final Color warningBorder;
  final Color criticalRed;
  final Color criticalRedDark;
  final Color criticalBg;
  final Color criticalBorder;
  final Color infoBlue;
  final Color infoBg;
  final Color infoBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDark;
  final LinearGradient primaryGradient;
  final LinearGradient cyanGlowGradient;
  final LinearGradient cardGradient;

  const AppColorScheme({
    required this.background,
    required this.canvasLow,
    required this.canvasSub,
    required this.surfaceCard,
    required this.surfaceHover,
    required this.surfaceSheet,
    required this.surfaceHigh,
    required this.borderHairline,
    required this.borderSubtle,
    required this.borderFocused,
    required this.primaryCyan,
    required this.primaryCyanLight,
    required this.primaryBlue,
    required this.primaryBlueLight,
    required this.successGreen,
    required this.successGreenDark,
    required this.successBg,
    required this.successBorder,
    required this.warningAmber,
    required this.warningAmberDark,
    required this.warningBg,
    required this.warningBorder,
    required this.criticalRed,
    required this.criticalRedDark,
    required this.criticalBg,
    required this.criticalBorder,
    required this.infoBlue,
    required this.infoBg,
    required this.infoBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDark,
    required this.primaryGradient,
    required this.cyanGlowGradient,
    required this.cardGradient,
  });

  static const dark = AppColorScheme(
    background: Color(0xFF0B101B),
    canvasLow: Color(0xFF111827),
    canvasSub: Color(0xFF161F30),
    surfaceCard: Color(0xFF1B2538),
    surfaceHover: Color(0xFF202D45),
    surfaceSheet: Color(0xFF25334E),
    surfaceHigh: Color(0xFF2E3D5C),
    borderHairline: Color(0x1AFFFFFF),
    borderSubtle: Color(0xFF2A3854),
    borderFocused: Color(0xFF06B6D4),
    primaryCyan: Color(0xFF06B6D4),
    primaryCyanLight: Color(0xFF4CD7F6),
    primaryBlue: Color(0xFF2563EB),
    primaryBlueLight: Color(0xFF3B82F6),
    successGreen: Color(0xFF10B981),
    successGreenDark: Color(0xFF059669),
    successBg: Color(0x1F10B981),
    successBorder: Color(0x4010B981),
    warningAmber: Color(0xFFF59E0B),
    warningAmberDark: Color(0xFFD97706),
    warningBg: Color(0x1FF59E0B),
    warningBorder: Color(0x40F59E0B),
    criticalRed: Color(0xFFEF4444),
    criticalRedDark: Color(0xFFDC2626),
    criticalBg: Color(0x1FEF4444),
    criticalBorder: Color(0x40EF4444),
    infoBlue: Color(0xFF3B82F6),
    infoBg: Color(0x1F3B82F6),
    infoBorder: Color(0x403B82F6),
    textPrimary: Color(0xFFDEE2F2),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    textDark: Color(0xFF0B101B),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cyanGlowGradient: LinearGradient(
      colors: [Color(0xFF4CD7F6), Color(0xFF06B6D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF1B2538), Color(0xFF161F30)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const light = AppColorScheme(
    background: Color(0xFFF8FAFC),
    canvasLow: Color(0xFFF1F5F9),
    canvasSub: Color(0xFFE2E8F0),
    surfaceCard: Color(0xFFFFFFFF),
    surfaceHover: Color(0xFFF1F5F9),
    surfaceSheet: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE2E8F0),
    borderHairline: Color(0x1F000000),
    borderSubtle: Color(0xFFE2E8F0),
    borderFocused: Color(0xFF0284C7),
    primaryCyan: Color(0xFF0284C7),
    primaryCyanLight: Color(0xFF0284C7),
    primaryBlue: Color(0xFF2563EB),
    primaryBlueLight: Color(0xFF2563EB),
    successGreen: Color(0xFF059669),
    successGreenDark: Color(0xFF047857),
    successBg: Color(0xFFECFDF5),
    successBorder: Color(0xFFA7F3D0),
    warningAmber: Color(0xFFD97706),
    warningAmberDark: Color(0xFFB45309),
    warningBg: Color(0xFFFFFBEB),
    warningBorder: Color(0xFFFDE68A),
    criticalRed: Color(0xFFDC2626),
    criticalRedDark: Color(0xFFB91C1C),
    criticalBg: Color(0xFFFEF2F2),
    criticalBorder: Color(0xFFFECACA),
    infoBlue: Color(0xFF2563EB),
    infoBg: Color(0xFFEFF6FF),
    infoBorder: Color(0xFFBFDBFE),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    textDark: Color(0xFFFFFFFF),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cyanGlowGradient: LinearGradient(
      colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  @override
  AppColorScheme copyWith({
    Color? background,
    Color? canvasLow,
    Color? canvasSub,
    Color? surfaceCard,
    Color? surfaceHover,
    Color? surfaceSheet,
    Color? surfaceHigh,
    Color? borderHairline,
    Color? borderSubtle,
    Color? borderFocused,
    Color? primaryCyan,
    Color? primaryCyanLight,
    Color? primaryBlue,
    Color? primaryBlueLight,
    Color? successGreen,
    Color? successGreenDark,
    Color? successBg,
    Color? successBorder,
    Color? warningAmber,
    Color? warningAmberDark,
    Color? warningBg,
    Color? warningBorder,
    Color? criticalRed,
    Color? criticalRedDark,
    Color? criticalBg,
    Color? criticalBorder,
    Color? infoBlue,
    Color? infoBg,
    Color? infoBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDark,
    LinearGradient? primaryGradient,
    LinearGradient? cyanGlowGradient,
    LinearGradient? cardGradient,
  }) {
    return AppColorScheme(
      background: background ?? this.background,
      canvasLow: canvasLow ?? this.canvasLow,
      canvasSub: canvasSub ?? this.canvasSub,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      surfaceSheet: surfaceSheet ?? this.surfaceSheet,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      borderHairline: borderHairline ?? this.borderHairline,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderFocused: borderFocused ?? this.borderFocused,
      primaryCyan: primaryCyan ?? this.primaryCyan,
      primaryCyanLight: primaryCyanLight ?? this.primaryCyanLight,
      primaryBlue: primaryBlue ?? this.primaryBlue,
      primaryBlueLight: primaryBlueLight ?? this.primaryBlueLight,
      successGreen: successGreen ?? this.successGreen,
      successGreenDark: successGreenDark ?? this.successGreenDark,
      successBg: successBg ?? this.successBg,
      successBorder: successBorder ?? this.successBorder,
      warningAmber: warningAmber ?? this.warningAmber,
      warningAmberDark: warningAmberDark ?? this.warningAmberDark,
      warningBg: warningBg ?? this.warningBg,
      warningBorder: warningBorder ?? this.warningBorder,
      criticalRed: criticalRed ?? this.criticalRed,
      criticalRedDark: criticalRedDark ?? this.criticalRedDark,
      criticalBg: criticalBg ?? this.criticalBg,
      criticalBorder: criticalBorder ?? this.criticalBorder,
      infoBlue: infoBlue ?? this.infoBlue,
      infoBg: infoBg ?? this.infoBg,
      infoBorder: infoBorder ?? this.infoBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDark: textDark ?? this.textDark,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      cyanGlowGradient: cyanGlowGradient ?? this.cyanGlowGradient,
      cardGradient: cardGradient ?? this.cardGradient,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      background: Color.lerp(background, other.background, t)!,
      canvasLow: Color.lerp(canvasLow, other.canvasLow, t)!,
      canvasSub: Color.lerp(canvasSub, other.canvasSub, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      surfaceSheet: Color.lerp(surfaceSheet, other.surfaceSheet, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      borderHairline: Color.lerp(borderHairline, other.borderHairline, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderFocused: Color.lerp(borderFocused, other.borderFocused, t)!,
      primaryCyan: Color.lerp(primaryCyan, other.primaryCyan, t)!,
      primaryCyanLight: Color.lerp(primaryCyanLight, other.primaryCyanLight, t)!,
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      primaryBlueLight: Color.lerp(primaryBlueLight, other.primaryBlueLight, t)!,
      successGreen: Color.lerp(successGreen, other.successGreen, t)!,
      successGreenDark: Color.lerp(successGreenDark, other.successGreenDark, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warningAmber: Color.lerp(warningAmber, other.warningAmber, t)!,
      warningAmberDark: Color.lerp(warningAmberDark, other.warningAmberDark, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      criticalRed: Color.lerp(criticalRed, other.criticalRed, t)!,
      criticalRedDark: Color.lerp(criticalRedDark, other.criticalRedDark, t)!,
      criticalBg: Color.lerp(criticalBg, other.criticalBg, t)!,
      criticalBorder: Color.lerp(criticalBorder, other.criticalBorder, t)!,
      infoBlue: Color.lerp(infoBlue, other.infoBlue, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      infoBorder: Color.lerp(infoBorder, other.infoBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      cyanGlowGradient: LinearGradient.lerp(cyanGlowGradient, other.cyanGlowGradient, t)!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
    );
  }
}

class AppColors {
  // Static const values (Dark default fallback for const constructors)
  static const Color background = Color(0xFF0B101B);
  static const Color canvasLow = Color(0xFF111827);
  static const Color canvasSub = Color(0xFF161F30);
  static const Color surfaceCard = Color(0xFF1B2538);
  static const Color surfaceHover = Color(0xFF202D45);
  static const Color surfaceSheet = Color(0xFF25334E);
  static const Color surfaceHigh = Color(0xFF2E3D5C);
  static const Color borderHairline = Color(0x1AFFFFFF);
  static const Color borderSubtle = Color(0xFF2A3854);
  static const Color borderFocused = Color(0xFF06B6D4);
  static const Color primaryCyan = Color(0xFF06B6D4);
  static const Color primaryCyanLight = Color(0xFF4CD7F6);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueLight = Color(0xFF3B82F6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenDark = Color(0xFF059669);
  static const Color successBg = Color(0x1F10B981);
  static const Color successBorder = Color(0x4010B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberDark = Color(0xFFD97706);
  static const Color warningBg = Color(0x1FF59E0B);
  static const Color warningBorder = Color(0x40F59E0B);
  static const Color criticalRed = Color(0xFFEF4444);
  static const Color criticalRedDark = Color(0xFFDC2626);
  static const Color criticalBg = Color(0x1FEF4444);
  static const Color criticalBorder = Color(0x40EF4444);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoBg = Color(0x1F3B82F6);
  static const Color infoBorder = Color(0x403B82F6);
  static const Color textPrimary = Color(0xFFDEE2F2);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0B101B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGlowGradient = LinearGradient(
    colors: [Color(0xFF4CD7F6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1B2538), Color(0xFF161F30)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dynamic context-based theme color getter
  static AppColorScheme of(BuildContext context) {
    return Theme.of(context).extension<AppColorScheme>() ??
        (Theme.of(context).brightness == Brightness.light ? AppColorScheme.light : AppColorScheme.dark);
  }
}
