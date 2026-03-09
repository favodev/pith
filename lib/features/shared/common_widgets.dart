import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';

class PithLogo extends StatelessWidget {
  const PithLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(
          7,
          (index) => Container(
            width: index == 3 ? 8 : 6,
            height: index == 3 ? 8 : 6,
            decoration: const BoxDecoration(
              color: Color(0xFFF4C025),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class IconButtonBubble extends StatelessWidget {
  const IconButtonBubble({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, color: const Color(0xFFF4EBD0), size: 22),
      ),
    );
  }
}

class TopCircleButton extends StatelessWidget {
  const TopCircleButton({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: const Color(0xFF9AA8C0), size: 22),
      ),
    );
  }
}

class ShellNavItem extends StatelessWidget {
  const ShellNavItem({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ShellTabItem tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFF4C025) : const Color(0xFF9AA8C0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              tab.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}