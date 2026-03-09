import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const PithApp());
}

class PithApp extends StatelessWidget {
  const PithApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF09111F);
    const surface = Color(0xFF121C2C);
    const cardSurface = Color(0xFF182435);
    const gold = Color(0xFFF4C025);
    const cream = Color(0xFFF4EBD0);
    const muted = Color(0xFF90A0BA);

    const scheme = ColorScheme.dark(
      primary: gold,
      secondary: cream,
      surface: surface,
      onPrimary: Color(0xFF111111),
      onSecondary: background,
      onSurface: cream,
      error: Color(0xFFF06A6A),
      onError: Colors.white,
    );

    return MaterialApp(
      title: 'Pith',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: background,
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: cream,
          displayColor: cream,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardSurface.withValues(alpha: 0.8),
          hintStyle: const TextStyle(color: muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
      home: const PithShell(),
    );
  }
}

class PithShell extends StatefulWidget {
  const PithShell({super.key});

  @override
  State<PithShell> createState() => _PithShellState();
}

class _PithShellState extends State<PithShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _fanOutController;
  bool _isFanOutVisible = false;

  static const _birthdayContacts = [
    _BirthdayContact(
      name: 'Eleanor Thorne',
      relation: 'Mom',
      subtitle: 'Turns 58',
      initials: 'ET',
      accent: Color(0xFFDEB06D),
      priority: _BirthdayPriority.vip,
      group: _BirthdayGroup.family,
      heightFactor: 1.26,
      actionIcon: Icons.card_giftcard_rounded,
    ),
    _BirthdayContact(
      name: 'Julian Vance',
      relation: 'Brother',
      subtitle: 'Turns 24',
      initials: 'JV',
      accent: Color(0xFFC88559),
      priority: _BirthdayPriority.vip,
      group: _BirthdayGroup.family,
      heightFactor: 1.02,
      actionIcon: Icons.auto_awesome_rounded,
    ),
    _BirthdayContact(
      name: 'Marcus Wright',
      relation: 'Colleague',
      subtitle: 'Design Team',
      initials: 'MW',
      accent: Color(0xFF5B78A6),
      priority: _BirthdayPriority.standard,
      group: _BirthdayGroup.innerCircle,
      heightFactor: 1.02,
    ),
    _BirthdayContact(
      name: 'Clara Smith',
      relation: 'Old School Friend',
      subtitle: 'Inner Circle',
      initials: 'CS',
      accent: Color(0xFF7F6688),
      priority: _BirthdayPriority.standard,
      group: _BirthdayGroup.innerCircle,
      heightFactor: 0.9,
    ),
    _BirthdayContact(
      name: 'Sarah Jenkins',
      relation: 'Acquaintance',
      subtitle: 'Tech Meetup',
      initials: 'SJ',
      accent: Color(0xFF708DB4),
      priority: _BirthdayPriority.standard,
      group: _BirthdayGroup.allContacts,
      heightFactor: 1.34,
    ),
    _BirthdayContact(
      name: 'Leo Thompson',
      relation: 'Gym Member',
      subtitle: 'Networking',
      initials: 'LT',
      accent: Color(0xFF6E7789),
      priority: _BirthdayPriority.standard,
      group: _BirthdayGroup.allContacts,
      heightFactor: 1.18,
    ),
  ];

  final List<_ShellTab> _tabs = const [
    _ShellTab(label: 'Home', icon: Icons.home_rounded),
    _ShellTab(label: 'Stacks', icon: Icons.layers_rounded),
    _ShellTab(label: 'Calendar', icon: Icons.calendar_today_rounded),
    _ShellTab(label: 'Profile', icon: Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _fanOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
  }

  @override
  void dispose() {
    _fanOutController.dispose();
    super.dispose();
  }

  Future<void> _openBirthdayStack() async {
    if (_isFanOutVisible || _currentIndex != 0) {
      return;
    }

    setState(() => _isFanOutVisible = true);
    await _fanOutController.forward();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = 1;
      _isFanOutVisible = false;
    });

    _fanOutController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomeDashboard(onOpenBirthdays: _openBirthdayStack),
      _BirthdayStackScreen(
        contacts: _birthdayContacts,
        onBack: () => setState(() => _currentIndex = 0),
      ),
      const _PreviewScreen(
        title: 'Relationship Calendar',
        eyebrow: 'Base para radar y agenda',
        description:
            'Aqui conviene unir cumpleanos, recordatorios y densidad de interaccion para preparar el Relationship Radar.',
        bulletPoints: [
          'Eventos por contacto y por circulo.',
          'Agrupacion por dia para cargas de 60+ cumpleanos.',
          'Puente directo hacia Supabase cuando entremos a datos.',
        ],
        icon: Icons.radar_rounded,
      ),
      const _PreviewScreen(
        title: 'Profile Canvas',
        eyebrow: 'Quick Sparks y detalle relacional',
        description:
            'El perfil sera la pantalla mas rica en contexto: intereses, timeline de sparks y acciones rapidas por contacto.',
        bulletPoints: [
          'Timeline vertical con sparks fechados.',
          'Intereses con iconografia ligera.',
          'Entrada tipo comando para capturar notas en segundos.',
        ],
        icon: Icons.auto_awesome_rounded,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A1426),
                  Color(0xFF09111F),
                  Color(0xFF060B14),
                ],
              ),
            ),
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(_currentIndex),
                  child: screens[_currentIndex],
                ),
              ),
            ),
          ),
          if (_isFanOutVisible)
            Positioned.fill(
              child: IgnorePointer(
                child: _BirthdayFanOutOverlay(
                  controller: _fanOutController,
                  contacts: _birthdayContacts.take(5).toList(),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF121C2C).withValues(
                  alpha: _isFanOutVisible ? 0.34 : 0.88,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  for (var index = 0; index < _tabs.length; index++)
                    Expanded(
                      child: _NavItem(
                        tab: _tabs[index],
                        selected: _currentIndex == index,
                        onTap: () => setState(() => _currentIndex = index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({required this.onOpenBirthdays});

  final VoidCallback onOpenBirthdays;

  static const _deck = _DeckSummary(
    totalBirthdays: 60,
    title: '60 Birthdays\ntoday',
    subtitle: 'A significant moment in your network. Send a note.',
    avatars: ['S', 'M', 'E', '+57'],
  );

  static const _pulses = [
    _PulseItem(
      name: 'Sarah Jenkins',
      meta: 'Last spoke 3 days ago',
      detail: 'Designer',
      initials: 'SJ',
      tint: Color(0xFF5F89C9),
    ),
    _PulseItem(
      name: 'Marcus Aurelius',
      meta: 'Met at Coffee House',
      detail: 'Philosophy',
      initials: 'MA',
      tint: Color(0xFF7F6FCE),
    ),
    _PulseItem(
      name: 'Elena Rodriguez',
      meta: 'Follow up on partnership',
      detail: 'Tomorrow',
      initials: 'ER',
      tint: Color(0xFFCA7B66),
    ),
  ];

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
                const _HeaderBar(),
                const SizedBox(height: 24),
                _DeckCard(deck: _deck, onTap: onOpenBirthdays),
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
                for (final pulse in _pulses) ...[
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
  const _HeaderBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _PithLogo(),
        const SizedBox(width: 12),
        Text(
          'Pith',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const Spacer(),
        const _IconButtonBubble(icon: Icons.search_rounded),
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

class _PithLogo extends StatelessWidget {
  const _PithLogo();

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

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.deck, required this.onTap});

  final _DeckSummary deck;
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
                    const Icon(
                      Icons.cake_rounded,
                      color: Color(0x88704E00),
                      size: 62,
                    ),
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

class _BirthdayStackScreen extends StatefulWidget {
  const _BirthdayStackScreen({required this.contacts, required this.onBack});

  final List<_BirthdayContact> contacts;
  final VoidCallback onBack;

  @override
  State<_BirthdayStackScreen> createState() => _BirthdayStackScreenState();
}

class _BirthdayFanOutOverlay extends StatelessWidget {
  const _BirthdayFanOutOverlay({
    required this.controller,
    required this.contacts,
  });

  final Animation<double> controller;
  final List<_BirthdayContact> contacts;

  @override
  Widget build(BuildContext context) {
    final cardOffsets = <Offset>[
      const Offset(-150, -150),
      const Offset(-74, -92),
      const Offset(0, -56),
      const Offset(76, -92),
      const Offset(152, -148),
    ];
    final rotations = [-0.48, -0.22, 0.0, 0.22, 0.48];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final curve = Curves.easeOutCubic.transform(controller.value);
        final fadeCurve = Curves.easeInOut.transform(controller.value);

        return Container(
          color: Color.lerp(
            Colors.transparent,
            const Color(0xCC06101D),
            fadeCurve,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.1),
                      radius: 0.9,
                      colors: [
                        const Color(0x22F4C025).withValues(alpha: 0.36 * curve),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.05),
                child: SizedBox(
                  width: 360,
                  height: 380,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      for (var index = 0; index < contacts.length; index++)
                        Transform.translate(
                          offset: cardOffsets[index] * curve,
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
                          child: const _DeckFanCoreCard(),
                        ),
                      ),
                    ],
                  ),
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
  const _DeckFanCoreCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 282,
      height: 318,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF4C025),
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44F4C025),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
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
          const SizedBox(height: 12),
          Text(
            '60 Birthdays\ntoday',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: const Color(0xFF111111),
              fontWeight: FontWeight.w800,
              height: 1.04,
              letterSpacing: -1.4,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              for (final label in const ['ET', 'JV', 'SJ'])
                Transform.translate(
                  offset: Offset(label == 'ET' ? 0 : -8, 0),
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
                      label,
                      style: const TextStyle(
                        color: Color(0xFFF4EBD0),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
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

  final _BirthdayContact contact;
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            contact.accent.withValues(alpha: highlight ? 0.92 : 0.72),
            const Color(0xFF0D1523),
          ],
        ),
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

class _BirthdayStackScreenState extends State<_BirthdayStackScreen> {
  _BirthdayGroup _selectedGroup = _BirthdayGroup.allContacts;

  @override
  Widget build(BuildContext context) {
    final filteredContacts = switch (_selectedGroup) {
      _BirthdayGroup.allContacts => widget.contacts,
      _ => widget.contacts
          .where((contact) => contact.group == _selectedGroup)
          .toList(),
    };

    final leftColumn = <_BirthdayContact>[];
    final rightColumn = <_BirthdayContact>[];
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
                minExtent: 110,
                maxExtent: 110,
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
                              _TopCircleButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: widget.onBack,
                              ),
                              Expanded(
                                child: Text(
                                  '60 Birthdays Today',
                                  textAlign: TextAlign.center,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const _TopCircleButton(icon: Icons.search_rounded),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              for (final tab in _BirthdayGroup.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 28),
                                  child: _BirthdayTab(
                                    label: tab.label,
                                    selected: _selectedGroup == tab,
                                    onTap: () => setState(() => _selectedGroup = tab),
                                  ),
                                ),
                            ],
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
                        const Icon(
                          Icons.stars_rounded,
                          color: Color(0xFFF4C025),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'PRIORITY WISHES',
                          style: textTheme.labelLarge?.copyWith(
                            color: const Color(0xFFF4C025),
                            letterSpacing: 4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              for (final contact in leftColumn) ...[
                                _BirthdayCard(contact: contact),
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
                                _BirthdayCard(contact: contact),
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
      ],
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _BirthdayHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.minExtent != minExtent ||
        oldDelegate.maxExtent != maxExtent;
  }
}

class _TopCircleButton extends StatelessWidget {
  const _TopCircleButton({required this.icon, this.onTap});

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

class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard({required this.contact});

  final _BirthdayContact contact;

  @override
  Widget build(BuildContext context) {
    final isVip = contact.priority == _BirthdayPriority.vip;

    return AspectRatio(
      aspectRatio: 0.82 / contact.heightFactor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: isVip
                ? const Color(0x80F4C025)
                : Colors.white.withValues(alpha: 0.05),
            width: isVip ? 2 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              contact.accent.withValues(alpha: isVip ? 0.94 : 0.52),
              const Color(0xFF111A28),
            ],
          ),
          boxShadow: isVip
              ? const [
                  BoxShadow(
                    color: Color(0x33F4C025),
                    blurRadius: 26,
                    offset: Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -20,
              right: -14,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: isVip ? 0.1 : 0.06),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC07101C)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
            ),
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
                          color: Colors.white.withValues(alpha: isVip ? 0.18 : 0.1),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          contact.initials,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: isVip ? 0.95 : 0.72),
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
                      color: isVip
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
                        Icon(
                          contact.actionIcon,
                          color: const Color(0xFFF4C025),
                          size: 22,
                        ),
                    ],
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

  final _PulseItem item;

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

class _PreviewScreen extends StatelessWidget {
  const _PreviewScreen({
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
          const _HeaderBar(),
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

class _IconButtonBubble extends StatelessWidget {
  const _IconButtonBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Icon(icon, color: const Color(0xFFF4EBD0), size: 22),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _ShellTab tab;
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

class _ShellTab {
  const _ShellTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _DeckSummary {
  const _DeckSummary({
    required this.totalBirthdays,
    required this.title,
    required this.subtitle,
    required this.avatars,
  });

  final int totalBirthdays;
  final String title;
  final String subtitle;
  final List<String> avatars;
}

enum _BirthdayPriority { vip, standard }

enum _BirthdayGroup {
  allContacts('All Contacts'),
  family('Family'),
  innerCircle('Inner Circle');

  const _BirthdayGroup(this.label);

  final String label;
}

class _BirthdayContact {
  const _BirthdayContact({
    required this.name,
    required this.relation,
    required this.subtitle,
    required this.initials,
    required this.accent,
    required this.priority,
    required this.group,
    required this.heightFactor,
    this.actionIcon,
  });

  final String name;
  final String relation;
  final String subtitle;
  final String initials;
  final Color accent;
  final _BirthdayPriority priority;
  final _BirthdayGroup group;
  final double heightFactor;
  final IconData? actionIcon;
}

class _PulseItem {
  const _PulseItem({
    required this.name,
    required this.meta,
    required this.detail,
    required this.initials,
    required this.tint,
  });

  final String name;
  final String meta;
  final String detail;
  final String initials;
  final Color tint;
}
