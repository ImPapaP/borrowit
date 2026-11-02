import 'package:flutter/material.dart';

import '../models/borrow_request.dart';
import '../models/equipment.dart';
import '../theme.dart';

/// The BorrowIT logo mark.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.devices_other_rounded,
        color: scheme.onPrimary,
        size: size * 0.55,
      ),
    );
  }
}

/// Picture of a piece of equipment. Accepts a file name from
/// assets/equipment/ or a full https:// link, with a placeholder fallback.
class EquipmentImage extends StatelessWidget {
  const EquipmentImage(
    this.image, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String image;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = _ImagePlaceholder(width: width, height: height);
    if (image.isEmpty) return placeholder;

    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    final path = image.startsWith('assets/') ? image : 'assets/equipment/$image';
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.devices_other_outlined,
        color: scheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }
}

/// Colored pill showing a request status.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// "3 available" in green, or "Unavailable" in red.
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge(this.equipment, {super.key});

  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = equipment.isAvailable;
    final color = available ? const Color(0xFF2E9D57) : scheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          available ? '${equipment.quantityAvailable} available' : 'Unavailable',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Centered icon + message, used for empty, error and "not found" states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Small bold heading used inside forms and detail pages.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
