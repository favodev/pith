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
    required this.onSubmitSpark,
    required this.hasContacts,
    this.onAddFirstContact,
    this.onOpenAccount,
    this.sparkFeedback,
  });

  final DeckSummary deck;
  final List<PulseItem> pulses;
  final VoidCallback onOpenBirthdays;
  final VoidCallback onOpenSearch;
  final ValueChanged<String> onSubmitSpark;
  final bool hasContacts;
  final VoidCallback? onAddFirstContact;
  final VoidCallback? onOpenAccount;
  final String? sparkFeedback;

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
                _HeaderBar(
                  onOpenSearch: onOpenSearch,
                  onOpenAccount: onOpenAccount,
                ),
                const SizedBox(height: 24),
                _DeckCard(deck: deck, onTap: onOpenBirthdays),
                const SizedBox(height: 34),
                if (hasContacts)
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: onOpenBirthdays,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Ver todos',
                          style: textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFF4C025),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (!hasContacts)
                  _EmptyHomeState(onAddFirstContact: onAddFirstContact)
                else
                for (final pulse in pulses) ...[
                  _PulseCard(item: pulse),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 4),
                _QuickSparkInput(
                  onSubmitted: onSubmitSpark,
                  hasContacts: hasContacts,
                ),
                if (sparkFeedback != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    sparkFeedback!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFF4C025),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
  const _HeaderBar({
    required this.onOpenSearch,
    this.onOpenAccount,
  });

  final VoidCallback onOpenSearch;
  final VoidCallback? onOpenAccount;

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
        GestureDetector(
          onTap: onOpenAccount,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF4C025).withValues(alpha: 0.35)),
              color: const Color(0xFFD7A46D),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, color: Color(0xFF3B2A16), size: 20),
          ),
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF182435),
          borderRadius: BorderRadius.circular(36),
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
                        deck.title,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: const Color(0xFFF4EBD0),
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
                            color: const Color(0xFF9AA8C0),
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.cake_rounded, color: Color(0xFFF4C025), size: 62),
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
              color: item.tint.withValues(alpha: 0.82),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF91A0BA),
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

class _QuickSparkInput extends StatefulWidget {
  const _QuickSparkInput({
    required this.onSubmitted,
    required this.hasContacts,
  });

  final ValueChanged<String> onSubmitted;
  final bool hasContacts;

  @override
  State<_QuickSparkInput> createState() => _QuickSparkInputState();
}

class _QuickSparkInputState extends State<_QuickSparkInput> {
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
        style: const TextStyle(color: Color(0xFFF4EBD0), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFFF4C025)),
          hintText: widget.hasContacts
              ? 'Escribe una nota para un contacto'
              : 'Primero crea un contacto desde Contactos',
          suffixIcon: IconButton(
            onPressed: _submit,
            icon: const Icon(Icons.send_rounded, color: Color(0xFF8392AD)),
            tooltip: 'Guardar nota',
          ),
        ),
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  const _EmptyHomeState({required this.onAddFirstContact});

  final VoidCallback? onAddFirstContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2B).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu cuenta esta lista',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer contacto desde Contactos y Pith empezara a construir tu memoria privada.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9AA8C0),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: onAddFirstContact,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Agregar primer contacto'),
          ),
        ],
      ),
    );
  }
}