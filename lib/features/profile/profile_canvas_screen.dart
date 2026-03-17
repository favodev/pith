import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';
import '../gifts/gift_recommender.dart';

class ProfileCanvasScreen extends StatelessWidget {
  const ProfileCanvasScreen({
    super.key,
    required this.profile,
    required this.onSubmitSpark,
    required this.onBack,
    this.onOpenContactActions,
    this.sparkFeedback,
  });

  final ContactProfile profile;
  final ValueChanged<String> onSubmitSpark;
  final VoidCallback onBack;
  final VoidCallback? onOpenContactActions;
  final String? sparkFeedback;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final suggestions = GiftRecommender.recommend(profile);

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
                    InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 18,
                              color: Color(0x889AA8C0),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'VOLVER A LA RED',
                              style: textTheme.labelMedium?.copyWith(
                                color: const Color(0x889AA8C0),
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: onOpenContactActions,
                          icon: const Icon(Icons.edit_note_rounded),
                          color: const Color(0x889AA8C0),
                        ),
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
                        color: const Color(0xFF1C2738),
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
                  'INTERESES CURADOS',
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
                const SizedBox(height: 64),
                Text(
                  'INTELIGENCIA DE REGALOS',
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: const Color(0x669AA8C0),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sugerencias basadas en tus notas e intereses privados',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0x889AA8C0),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                for (final suggestion in suggestions) ...[
                  _GiftSuggestionTile(suggestion: suggestion),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 72),
                Text(
                  'NOTAS Y RECUERDOS',
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: const Color(0x669AA8C0),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Agrega una nota nueva para ${profile.name} desde aqui.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0x889AA8C0),
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
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    widget.onSubmitted(value);
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
      child: Column(
        children: [
          TextField(
            controller: _controller,
            onSubmitted: (_) => _submit(),
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              border: InputBorder.none,
              fillColor: Colors.transparent,
              filled: false,
              prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0x88F4C025)),
              hintText: 'Agregar nota para ${widget.profileName}...',
              hintStyle: const TextStyle(color: Color(0x449AA8C0)),
              suffixIcon: IconButton(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded, color: Color(0x88F4C025)),
                tooltip: 'Guardar nota',
              ),
            ),
            style: const TextStyle(
              color: Color(0xFFF4EBD0),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: _submit,
              icon: const Icon(Icons.add_comment_rounded),
              label: const Text('Agregar nota'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftSuggestionTile extends StatelessWidget {
  const _GiftSuggestionTile({required this.suggestion});

  final GiftSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x1AF4C025),
              border: Border.all(color: const Color(0x33F4C025)),
            ),
            child: const Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFFF4C025)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFF4EBD0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.reason,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9AA8C0),
                    height: 1.35,
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