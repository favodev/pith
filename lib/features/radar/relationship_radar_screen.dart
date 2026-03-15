import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';

class RelationshipRadarScreen extends StatelessWidget {
  const RelationshipRadarScreen({
    super.key,
    required this.stories,
    required this.feedCards,
  });

  final List<RadarStory> stories;
  final List<RadarFeedCard> feedCards;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 76),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      const _RadarHeader(),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 106,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) => _StoryChip(
                            story: stories[index],
                          ),
                          separatorBuilder: (context, index) => const SizedBox(width: 14),
                          itemCount: stories.length,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final card in feedCards) ...[
                        _FeedCard(card: card),
                        const SizedBox(height: 18),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          top: 0,
          bottom: 0,
          right: 8,
          child: _RadarSidebar(),
        ),
      ],
    );
  }
}

class _RadarHeader extends StatelessWidget {
  const _RadarHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        const _HeaderIcon(icon: Icons.menu_rounded),
        Expanded(
          child: Text(
            'Pith',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const _HeaderIcon(icon: Icons.notifications_none_rounded),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Icon(icon, color: const Color(0xFFE8DFC5), size: 22),
    );
  }
}

class _StoryChip extends StatelessWidget {
  const _StoryChip({required this.story});

  final RadarStory story;

  @override
  Widget build(BuildContext context) {
    final ringColors = story.highlighted
        ? [const Color(0xFFF4C025), const Color(0xFFD97C1A)]
        : [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.06)];

    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ringColors.first,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D1524),
                border: Border.all(color: const Color(0xFF09111F)),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: story.accent.withValues(alpha: 0.78),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            story.label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF9AA8C0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.card});

  final RadarFeedCard card;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 192,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              color: card.gradient.first,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 22,
                  right: 20,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  bottom: 18,
                  child: Container(
                    width: 132,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.black.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF4EBD0),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF9AA8C0),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF4C025),
                        foregroundColor: const Color(0xFF161104),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(card.actionLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarSidebar extends StatelessWidget {
  const _RadarSidebar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 58,
          margin: const EdgeInsets.symmetric(vertical: 18),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'RADAR',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF9AA8C0),
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'ENE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0x669AA8C0),
                        fontSize: 9,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          const _RadarMarkers(),
                        ],
                      ),
                    ),
                    Text(
                      'DIC',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0x669AA8C0),
                        fontSize: 9,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Icon(Icons.insights_rounded, color: Color(0xFFF4C025), size: 22),
              const SizedBox(height: 18),
              const Icon(
                Icons.settings_input_antenna_rounded,
                color: Color(0xFF6C7B93),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarMarkers extends StatelessWidget {
  const _RadarMarkers();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _Marker(size: 10, glow: 0.26),
        _Marker(size: 7, glow: 0.18),
        _Marker(size: 14, glow: 0.34),
        _Marker(size: 5, glow: 0),
        _Marker(size: 9, glow: 0.22),
      ],
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.size, required this.glow});

  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 16,
      height: size + 16,
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF4C025),
          boxShadow: glow == 0
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFF4C025).withValues(alpha: glow),
                    blurRadius: 18,
                    spreadRadius: 4,
                  ),
                ],
        ),
      ),
    );
  }
}