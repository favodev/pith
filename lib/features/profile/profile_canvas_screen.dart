import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';

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

    return Stack(
      children: [
        CustomScrollView(
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
                              'Volver',
                              style: textTheme.labelMedium?.copyWith(
                                color: const Color(0x889AA8C0),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final viewportWidth = MediaQuery.of(context).size.width;
                      final avatarSize = (viewportWidth * 0.34).clamp(108.0, 142.0);

                      return Container(
                        width: avatarSize,
                        height: avatarSize,
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
                      );
                    },
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
                const SizedBox(height: 48),
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
                const SizedBox(height: 170),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sparkFeedback != null) ...[
                Text(
                  sparkFeedback!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFF4C025),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _SparkComposer(
                profileName: profile.name,
                onSubmitted: onSubmitSpark,
              ),
            ],
          ),
        ),
      ],
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.iconType != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          _iconForType(entry.iconType!),
                          size: 18,
                          color: const Color(0x88F4C025),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        entry.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w300,
                          height: 1.45,
                          color: const Color(0xE6F4EBD0),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForType(String iconType) {
    return switch (iconType.toLowerCase()) {
      'coffee' => Icons.coffee_rounded,
      'music' => Icons.music_note_rounded,
      'gift' => Icons.card_giftcard_rounded,
      _ => Icons.notes_rounded,
    };
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
        color: const Color(0xFF121C2C),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: TextField(
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
    );
  }
}
