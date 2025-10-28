import 'package:flutter/material.dart';

class ResponsiveUtils {
  /// Type d’écran selon la largeur
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 1200 && width < 2000;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 2000;
  }

  /// Padding responsive
  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    if (isDesktop(context)) return 32.0;
    return 48.0; // écrans 4K+
  }

  /// Marges responsives
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    } else if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 16);
    } else {
      return const EdgeInsets.symmetric(horizontal: 72, vertical: 24);
    }
  }

  /// Taille du texte en fonction de la largeur de l’écran
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) return baseFontSize * 0.85; // très petit écran
    if (screenWidth < 600) return baseFontSize * 0.95; // téléphone
    if (screenWidth < 900) return baseFontSize * 1.05; // tablette
    if (screenWidth < 1600) return baseFontSize * 1.15; // desktop
    return baseFontSize * 1.25; // très grand écran
  }

  /// Largeur maximale du contenu (utile pour centrer sur desktop)
  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) return screenWidth;
    if (isTablet(context)) return 700;
    if (isDesktop(context)) return 1100;
    return 1600;
  }

  /// Nombre de colonnes pour les grilles
  static int getGridCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 2;
    if (screenWidth < 900) return 3;
    if (screenWidth < 1400) return 4;
    if (screenWidth < 2000) return 5;
    return 6;
  }

  /// Padding en bas (gère le clavier et le safe area)
  static double getBottomPadding(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final padding = MediaQuery.of(context).padding.bottom;
    return viewInsets > 0 ? 8 : padding + 16;
  }

  /// Mise à l’échelle générique basée sur la largeur de l’écran
  static double scale(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / 375); // 375 = largeur de base iPhone 11
  }

  /// Exemple : utilisation pratique pour espacement vertical responsive
  static SizedBox verticalSpace(BuildContext context, double baseHeight) {
    return SizedBox(height: scale(context, baseHeight));
  }

  /// Exemple : pour un padding uniforme mais adaptable
  static EdgeInsets symmetricPadding(BuildContext context, {double base = 16}) {
    final scaleValue = scale(context, base);
    return EdgeInsets.symmetric(horizontal: scaleValue, vertical: scaleValue / 2);
  }
}
