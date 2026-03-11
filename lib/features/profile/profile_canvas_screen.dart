import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';

class ProfileCanvasScreen extends StatelessWidget {
  const ProfileCanvasScreen({
    super.key,
    required this.profile,
    required this.onSubmitSpark,
    this.sparkFeedback,
  });

  final ContactProfile profile;
  final ValueChanged<String> onSubmitSpark;
  final String? sparkFeedback;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 18,
                          color: Color(0x889AA8C0),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BACK TO NETWORK',
                          style: textTheme.labelMedium?.copyWith(
                            color: const Color(0x889AA8C0),
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: Color(0x889AA8C0)),
                        SizedBox(width: 18),
                        Icon(Icons.settings_rounded, color: Color(0x889AA8C0)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Center(
                  child: Container(
                    width: 142,
                    height: 142,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF2B374E), Color(0xFF0F172A)],
                        ),
                        border: Border.all(color: const Color(0x33F4EBD0)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        profile.initials,
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF4EBD0),
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  profile.name,
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  profile.subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0x889AA8C0),
                    letterSpacing: 3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 56),
                Text(
                  'CURATED INTERESTS',
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: const Color(0x669AA8C0),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 28,
                  runSpacing: 24,
                  children: [
                    for (final interest in profile.interests)
                      _InterestBadge(interest: interest),
                  ],
                ),
                const SizedBox(height: 72),
                Text(
                  'QUICK SPARKS',
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: const Color(0x669AA8C0),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 30),
                for (final spark in profile.sparks) ...[
                  _SparkTimelineEntry(entry: spark),
                  const SizedBox(height: 34),
                ],
                const SizedBox(height: 24),
                _SparkComposer(
                  profileName: profile.name,
                  onSubmitted: onSubmitSpark,
                ),
                if (sparkFeedback != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    sparkFeedback!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFF4C025),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const _ProfileActionsRow(),
                const SizedBox(height: 130),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InterestBadge extends StatelessWidget {
  const _InterestBadge({required this.interest});

  final ProfileInterest interest;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(interest.icon, color: const Color(0xFFF4C025), size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            interest.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xB3E8DFC5),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkTimelineEntry extends StatelessWidget {
  const _SparkTimelineEntry({required this.entry});

  final QuickSparkEntry entry;

  @override
  Widget build(BuildContext context) {
    final dotColor = entry.highlighted
        ? const Color(0xFFF4C025)
        : const Color(0x339AA8C0);
    final dateColor = entry.highlighted
        ? const Color(0x99F4C025)
        : const Color(0x669AA8C0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              Container(
                width: 1,
                height: 108,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.dateLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: dateColor,
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  entry.content,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w300,
                    height: 1.45,
                    color: const Color(0xE6F4EBD0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SparkComposer extends StatefulWidget {
  const _SparkComposer({required this.profileName, required this.onSubmitted});

  final String profileName;
  final ValueChanged<String> onSubmitted;

  @override
  State<_SparkComposer> createState() => _SparkComposerState();
}

class _SparkComposerState extends State<_SparkComposer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmitted(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x1A1E293B),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: TextField(
        controller: _controller,
        onSubmitted: (_) => _submit(),
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          border: InputBorder.none,
          fillColor: Colors.transparent,
          filled: false,
          prefixIcon: const Icon(Icons.terminal_rounded, color: Color(0x88F4C025)),
          hintText: 'Add a new spark for ${widget.profileName}...',
          hintStyle: const TextStyle(color: Color(0x449AA8C0)),
          suffixIcon: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
              widthFactor: 1,
              child: Text(
                'CMD + K',
                style: TextStyle(
                  color: Color(0x449AA8C0),
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
        style: const TextStyle(
          color: Color(0xFFF4EBD0),
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ProfileActionsRow extends StatelessWidget {
  const _ProfileActionsRow();

  @override
  Widget build(BuildContext context) {
    const actions = ['LOG MEETING', 'SET REMINDER', 'SHARE PROFILE'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final action in actions)
          Text(
            action,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0x449AA8C0),
              letterSpacing: 2.2,
            ),
          ),
      ],
    );
  }
}