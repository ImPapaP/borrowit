import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// Shared layout for the sign-in and sign-up pages: a gradient panel with
/// the equipment pictures, and the form in a card. Side by side on wide
/// screens, stacked on phones.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final form = Card(
      elevation: wide ? 0 : 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );

    final back = showBack
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filledTonal(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          )
        : const SizedBox.shrink();

    if (wide) {
      return Scaffold(
        body: Stack(
          children: [
            Row(
              children: [
                const Expanded(flex: 5, child: _AuthHero(large: true)),
                Expanded(
                  flex: 4,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: form,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            back,
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 300 + MediaQuery.paddingOf(context).top,
                  child: const _AuthHero(large: false),
                ),
                Transform.translate(
                  offset: const Offset(0, -36),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: form,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          back,
        ],
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({required this.large});

  final bool large;

  static const _pictures = [
    'laptop.png',
    'camera.png',
    'projector.png',
    'microphone.png',
    'speaker.png',
    'tripod.png',
  ];

  @override
  Widget build(BuildContext context) {
    final tileSize = large ? 112.0 : 64.0;
    final pictures = large ? _pictures : _pictures.take(4).toList();
    return Container(
      decoration: const BoxDecoration(gradient: brandGradient),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -60,
            child: _Glow(size: large ? 360 : 220),
          ),
          Positioned(
            left: -60,
            bottom: -90,
            child: _Glow(size: large ? 280 : 160),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: _content(pictures, tileSize),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(List<String> pictures, double tileSize) {
    return Padding(
              padding: EdgeInsets.fromLTRB(
                large ? 48 : 24,
                large ? 40 : 20,
                large ? 48 : 24,
                large ? 40 : 52,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: large
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: large ? 52 : 40,
                        height: large ? 52 : 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.devices_other_rounded,
                          color: brandBlue,
                          size: large ? 30 : 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'BorrowIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: large ? 30 : 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: large ? 28 : 16),
                  Text(
                    'Borrow school equipment\nin a few taps.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: large ? 34 : 20,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (large) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Laptops, projectors, cameras and more. Request what you '
                      'need and track it until it\'s returned.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                  SizedBox(height: large ? 32 : 18),
                  Wrap(
                    spacing: large ? 14 : 10,
                    runSpacing: large ? 14 : 10,
                    children: [
                      for (var i = 0; i < pictures.length; i++)
                        Transform.rotate(
                          angle: (i.isEven ? -1 : 1) * 0.04,
                          child: Container(
                            width: tileSize,
                            height: tileSize,
                            padding: EdgeInsets.all(large ? 10 : 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(large ? 24 : 16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(large ? 16 : 10),
                              child: EquipmentImage(pictures[i]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.10),
      ),
    );
  }
}
