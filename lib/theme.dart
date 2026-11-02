import 'package:flutter/material.dart';

import 'models/borrow_request.dart';

const Color _brandSeed = Color(0xFF2F5BEA);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _brandSeed,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
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
