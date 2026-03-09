import 'package:flutter/material.dart';

import 'common_widgets.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.bulletPoints,
    required this.icon,
  });

  final String title;
  final String eyebrow;
  final String description;
  final List<String> bulletPoints;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PithLogo(),
              const SizedBox(width: 12),
              Text(
                'Pith',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF121C2C).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4C025).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: const Color(0xFFF4C025), size: 30),
                ),
                const SizedBox(height: 24),
                Text(
                  eyebrow.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFF4C025),
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.04,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  description,
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFBAC6DA),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                for (final point in bulletPoints) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4C025),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          point,
                          style: textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFFE9E0C6),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}