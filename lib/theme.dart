import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/borrow_request.dart';

/// Brand colors.
const Color brandBlue = Color(0xFF3556C8);
const Color brandIndigo = Color(0xFF5B3FD0);
const Color brandSky = Color(0xFF2FA7E8);

/// The gradient used on banners and headers.
const LinearGradient brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [brandBlue, brandIndigo],
);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandBlue,
    brightness: brightness,
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: brightness,
  );
  final isDark = brightness == Brightness.dark;
  final pageColor = isDark ? const Color(0xFF101218) : const Color(0xFFF4F6FB);
  final cardColor = isDark ? const Color(0xFF1A1D26) : Colors.white;

  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
    scaffoldBackgroundColor: pageColor,
    appBarTheme: AppBarTheme(
      backgroundColor: pageColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? const Color(0xFF262A36) : const Color(0xFFE6E9F2),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: cardColor,
      indicatorColor: scheme.primaryContainer,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Color used for each request status (chips, timeline, summary).
Color statusColor(RequestStatus status, ColorScheme scheme) {
  return switch (status) {
    RequestStatus.pending => const Color(0xFFD98E04),
    RequestStatus.approved => const Color(0xFF2E7DD7),
    RequestStatus.borrowed => const Color(0xFF7B4FD6),
    RequestStatus.returned => const Color(0xFF2E9D57),
    RequestStatus.rejected => scheme.error,
  };
}

IconData statusIcon(RequestStatus status) {
  return switch (status) {
    RequestStatus.pending => Icons.hourglass_top_rounded,
    RequestStatus.approved => Icons.thumb_up_alt_outlined,
    RequestStatus.borrowed => Icons.inventory_2_outlined,
    RequestStatus.returned => Icons.assignment_turned_in_outlined,
    RequestStatus.rejected => Icons.block_rounded,
  };
}

/// Icon and color for an equipment category. Unknown categories get a
/// color picked from the palette by name, so each one stays consistent.
class CategoryStyle {
  const CategoryStyle(this.icon, this.color);

  final IconData icon;
  final Color color;

  static const List<Color> _palette = [
    Color(0xFF3556C8),
    Color(0xFF0E9F8E),
    Color(0xFFE0703A),
    Color(0xFF7B4FD6),
    Color(0xFFD6457A),
    Color(0xFF2FA7E8),
  ];

  static CategoryStyle of(String category) {
    final name = category.toLowerCase();
    if (name.contains('computer') || name.contains('laptop')) {
      return const CategoryStyle(Icons.laptop_mac_rounded, Color(0xFF3556C8));
    }
    if (name.contains('photo') || name.contains('camera')) {
      return const CategoryStyle(Icons.photo_camera_rounded, Color(0xFF0E9F8E));
    }
    if (name.contains('audio-visual') || name.contains('projector')) {
      return const CategoryStyle(Icons.videocam_rounded, Color(0xFFE0703A));
    }
    if (name.contains('audio') || name.contains('sound')) {
      return const CategoryStyle(Icons.mic_rounded, Color(0xFFD6457A));
    }
    if (name.contains('cable') || name.contains('accessor')) {
      return const CategoryStyle(Icons.cable_rounded, Color(0xFF7B4FD6));
    }
    var hash = 0;
    for (final unit in name.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return CategoryStyle(
      Icons.category_rounded,
      _palette[hash % _palette.length],
    );
  }
}
