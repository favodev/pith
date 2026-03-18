import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';
import '../shared/common_widgets.dart';

class BirthdayStackScreen extends StatefulWidget {
  const BirthdayStackScreen({
    super.key,
    required this.contacts,
    required this.todayCount,
    required this.onBack,
    required this.onOpenSearch,
    required this.onSendNote,
    required this.onOpenContact,
    required this.onAddContact,
  });

  final List<BirthdayContact> contacts;
  final int todayCount;
  final VoidCallback onBack;
  final VoidCallback onOpenSearch;
  final ValueChanged<BirthdayContact> onSendNote;
  final ValueChanged<BirthdayContact> onOpenContact;
  final VoidCallback onAddContact;

  @override
  State<BirthdayStackScreen> createState() => _BirthdayStackScreenState();
}

class _BirthdayStackScreenState extends State<BirthdayStackScreen> {
  BirthdayGroup _selectedGroup = BirthdayGroup.allContacts;

  @override
  Widget build(BuildContext context) {
    final filteredContacts = switch (_selectedGroup) {
      BirthdayGroup.allContacts => widget.contacts,
      _ => widget.contacts
          .where((contact) => contact.group == _selectedGroup)
          .toList(),
    };

    final leftColumn = <BirthdayContact>[];
    final rightColumn = <BirthdayContact>[];
    var leftHeight = 0.0;
    var rightHeight = 0.0;

    for (final contact in filteredContacts) {
      if (leftHeight <= rightHeight) {
        leftColumn.add(contact);
        leftHeight += contact.heightFactor;
      } else {
        rightColumn.add(contact);
        rightHeight += contact.heightFactor;
      }
    }

    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _BirthdayHeaderDelegate(
                minExtent: 132,
                maxExtent: 132,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF09111F).withValues(alpha: 0.92),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Row(
                            children: [
                              TopCircleButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: widget.onBack,
                              ),
                              Expanded(
                                child: Text(
                                  '${widget.todayCount} cumpleanos hoy · ${widget.contacts.length} en total',
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              TopCircleButton(
                                icon: Icons.search_rounded,
                                onTap: widget.onOpenSearch,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            itemCount: BirthdayGroup.values.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 18),
                            itemBuilder: (context, index) {
                              final tab = BirthdayGroup.values[index];
                              return _BirthdayTab(
                                label: tab.label,
                                selected: _selectedGroup == tab,
                                onTap: () => setState(() => _selectedGroup = tab),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 132),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFF4C025), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'DESEOS PRIORITARIOS',
                          style: textTheme.labelLarge?.copyWith(
                            color: const Color(0xFFF4C025),
                            letterSpacing: 4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (filteredContacts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No hay contactos en este grupo',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pulsa + para crear un contacto y se sincronizara con tu cuenta.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF9AA8C0),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              for (final contact in leftColumn) ...[
                                BirthdayCard(
                                  contact: contact,
                                  onOpenContact: () => widget.onOpenContact(contact),
                                  onSendNote: contact.actionIcon == null
                                      ? null
                                      : () => widget.onSendNote(contact),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              for (final contact in rightColumn) ...[
                                BirthdayCard(
                                  contact: contact,
                                  onOpenContact: () => widget.onOpenContact(contact),
                                  onSendNote: contact.actionIcon == null
                                      ? null
                                      : () => widget.onSendNote(contact),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 24,
          bottom: 112,
          child: GestureDetector(
            onTap: widget.onAddContact,
            child: Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF4C025),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x44F4C025),
                    blurRadius: 22,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF101010), size: 32),
            ),
          ),
        ),
      ],
    );
  }
}

class BirthdayFanOutOverlay extends StatelessWidget {
  const BirthdayFanOutOverlay({
    super.key,
    required this.controller,
    required this.contacts,
    required this.totalBirthdays,
  });

  final Animation<double> controller;
  final List<BirthdayContact> contacts;
  final int totalBirthdays;

  @override
  Widget build(BuildContext context) {
    const cardOffsets = <Offset>[
      Offset(-150, -150),
      Offset(-74, -92),
      Offset(0, -56),
      Offset(76, -92),
      Offset(152, -148),
    ];
    const rotations = [-0.48, -0.22, 0.0, 0.22, 0.48];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final curve = Curves.easeOutCubic.transform(controller.value);
        final fadeCurve = Curves.easeInOut.transform(controller.value);

        return Container(
          color: Color.lerp(Colors.transparent, const Color(0xCC06101D), fadeCurve),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x11000000).withValues(alpha: 0.18 * curve),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.05),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = (constraints.maxWidth * 0.92).clamp(260.0, 360.0);
                    final height = (constraints.maxHeight * 0.54).clamp(260.0, 380.0);

                    final scaleX = width / 360;
                    final scaleY = height / 380;
                    final responsiveOffsets = [
                      for (final base in cardOffsets)
                        Offset(base.dx * scaleX, base.dy * scaleY),
                    ];

                    return SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          for (var index = 0; index < contacts.length; index++)
                            Transform.translate(
                              offset: responsiveOffsets[index] * curve,
                              child: Transform.rotate(
                                angle: rotations[index] * curve,
                                child: Transform.scale(
                                  scale: 0.7 + (0.3 * curve),
                                  child: Opacity(
                                    opacity: curve.clamp(0.0, 1.0),
                                    child: _FanOutMiniCard(
                                      contact: contacts[index],
                                      highlight: index < 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Transform.scale(
                            scale: 1 - (0.08 * curve),
                            child: Opacity(
                              opacity: (1.2 - controller.value * 1.35).clamp(0.0, 1.0),
                              child: _DeckFanCoreCard(
                                totalBirthdays: totalBirthdays,
                                contactInitials: contacts.take(3).map((entry) => entry.initials).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeckFanCoreCard extends StatelessWidget {
  const _DeckFanCoreCard({
    required this.totalBirthdays,
    required this.contactInitials,
  });

  final int totalBirthdays;
  final List<String> contactInitials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 282,
      height: 318,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF182435),
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STACK PRINCIPAL',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF8392AD),
              letterSpacing: 4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$totalBirthdays cumpleanos\nde hoy',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: const Color(0xFFF4EBD0),
              fontWeight: FontWeight.w800,
              height: 1.04,
              letterSpacing: -1.4,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              for (var index = 0; index < contactInitials.length; index++)
                Transform.translate(
                  offset: Offset(index == 0 ? 0 : -8, 0),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF101010).withValues(alpha: 0.92),
                      border: Border.all(color: const Color(0xFFF4EBD0), width: 1.6),
                    ),
                    child: Text(
                      contactInitials[index],
                      style: const TextStyle(
                        color: Color(0xFFF4EBD0),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              if (contactInitials.isEmpty)
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF101010).withValues(alpha: 0.92),
                    border: Border.all(color: const Color(0xFFF4EBD0), width: 1.6),
                  ),
                  child: const Text(
                    '--',
                    style: TextStyle(
                      color: Color(0xFFF4EBD0),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
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

class _FanOutMiniCard extends StatelessWidget {
  const _FanOutMiniCard({required this.contact, required this.highlight});

  final BirthdayContact contact;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 154,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight
              ? const Color(0x88F4C025)
              : Colors.white.withValues(alpha: 0.06),
          width: highlight ? 1.6 : 1,
        ),
        color: contact.accent.withValues(alpha: highlight ? 0.42 : 0.28),
        boxShadow: highlight
            ? const [
                BoxShadow(
                  color: Color(0x33F4C025),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
                child: Text(
                  contact.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          Text(
            contact.relation.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFFF4C025),
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            contact.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFF4EBD0),
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _BirthdayHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _BirthdayHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.minExtent != minExtent ||
        oldDelegate.maxExtent != maxExtent;
  }
}

class _BirthdayTab extends StatelessWidget {
  const _BirthdayTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: selected ? const Color(0xFFF4C025) : const Color(0xFF9AA8C0),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: selected ? 114 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: const Color(0xFFF4C025),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class BirthdayCard extends StatelessWidget {
  const BirthdayCard({
    super.key,
    required this.contact,
    this.onSendNote,
    this.onOpenContact,
  });

  final BirthdayContact contact;
  final VoidCallback? onSendNote;
  final VoidCallback? onOpenContact;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = contact.priority == BirthdayPriority.highlighted;
    final normalizedHeightFactor = contact.heightFactor.clamp(0.75, 1.15);
    final aspectRatio = (0.82 / normalizedHeightFactor).clamp(0.72, 0.95);

    return GestureDetector(
      onTap: onOpenContact,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: isHighlighted
                ? const Color(0x80F4C025)
                : Colors.white.withValues(alpha: 0.05),
            width: isHighlighted ? 2 : 1,
          ),
          color: contact.accent.withValues(alpha: isHighlighted ? 0.26 : 0.20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x1FFFFFFF),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          contact.initials,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: isHighlighted ? 0.95 : 0.72),
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    contact.relation.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFF4C025),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isHighlighted
                          ? const Color(0xFFF4EBD0)
                          : const Color(0xFFE2E5EA),
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          contact.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF9AA8C0),
                          ),
                        ),
                      ),
                      if (contact.actionIcon != null)
                        GestureDetector(
                          onTap: onSendNote,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0x1AF4C025),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              contact.actionIcon,
                              color: const Color(0xFFF4C025),
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}