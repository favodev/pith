import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';
import '../shared/common_widgets.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    super.key,
    required this.deck,
    required this.pulses,
    required this.onOpenBirthdays,
    required this.onOpenSearch,
  });

  final DeckSummary deck;
  final List<PulseItem> pulses;
  final VoidCallback onOpenBirthdays;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                _HeaderBar(onOpenSearch: onOpenSearch),
                const SizedBox(height: 24),
                _DeckCard(deck: deck, onTap: onOpenBirthdays),
                const SizedBox(height: 34),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT PULSE',
                      style: textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF8392AD),
                        letterSpacing: 3.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'View all',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFF4C025),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                for (final pulse in pulses) ...[
                  _PulseCard(item: pulse),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 4),
                const _QuickSparkInput(),
                const SizedBox(height: 12),
                const _ShortcutRow(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.onOpenSearch});

  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PithLogo(),
        const SizedBox(width: 12),
        Text(
          'Pith',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const Spacer(),
        IconButtonBubble(icon: Icons.search_rounded, onTap: onOpenSearch),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF4C025).withValues(alpha: 0.35)),
            gradient: const LinearGradient(
              colors: [Color(0xFFF7D89A), Color(0xFFD7A46D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.person, color: Color(0xFF3B2A16), size: 20),
        ),
      ],
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.deck, required this.onTap});

  final DeckSummary deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 10,
            right: 10,
            bottom: -12,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EAC5).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(34),
              ),
            ),
          ),
          Positioned(
            left: 5,
            right: 5,
            bottom: -24,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EAC5).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(34),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF4C025),
              borderRadius: BorderRadius.circular(36),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33F4C025),
                  blurRadius: 28,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STACKED DECK',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF3F3522),
                              letterSpacing: 4,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            deck.title,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: const Color(0xFF101010),
                              fontWeight: FontWeight.w800,
                              height: 1.04,
                              letterSpacing: -1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Text(
                              deck.subtitle,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF2E2A1F),
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.cake_rounded, color: Color(0x88704E00), size: 62),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 42,
                  child: Stack(
                    children: [
                      for (var index = 0; index < deck.avatars.length; index++)
                        Positioned(
                          left: index * 26,
                          child: _DeckAvatar(label: deck.avatars[index]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckAvatar extends StatelessWidget {
  const _DeckAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isAggregate = label.startsWith('+');

    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isAggregate ? const Color(0xFFECECEC) : const Color(0xFF1A2332),
        border: Border.all(color: const Color(0xFFF4C025), width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isAggregate ? const Color(0xFF111111) : const Color(0xFFF4EBD0),
          fontWeight: FontWeight.w800,
          fontSize: isAggregate ? 13 : 15,
        ),
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({required this.item});

  final PulseItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2B).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [item.tint.withValues(alpha: 0.9), item.tint.withValues(alpha: 0.45)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              item.initials,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.meta} • ${item.detail}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF91A0BA),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.more_horiz_rounded, color: Color(0xFF91A0BA)),
        ],
      ),
    );
  }
}

class _QuickSparkInput extends StatelessWidget {
  const _QuickSparkInput();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121C2C).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: const TextField(
        style: TextStyle(color: Color(0xFFF4EBD0), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.terminal_rounded, color: Color(0xFFF4C025)),
          hintText: '@Juan: likes vinyl records',
          suffixIcon: Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
              widthFactor: 1,
              child: Text(
                'ENTER',
                style: TextStyle(
                  color: Color(0xFF8392AD),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow();

  @override
  Widget build(BuildContext context) {
    const shortcuts = ['LOG MEETING', 'SET REMINDER', 'SHARE PROFILE'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final item in shortcuts)
          Text(
            item,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF6E7D97),
              letterSpacing: 2.6,
            ),
          ),
      ],
    );
  }
}