import 'dart:ui';

import 'package:flutter/material.dart';

import 'core/models/pith_models.dart';
import 'core/theme/pith_theme.dart';
import 'features/birthdays/birthday_stack_screen.dart';
import 'features/home/home_dashboard_screen.dart';
import 'features/profile/profile_canvas_screen.dart';
import 'features/search/power_search_screen.dart';
import 'features/shared/common_widgets.dart';
import 'features/shared/preview_screen.dart';

class PithApp extends StatelessWidget {
  const PithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pith',
      debugShowCheckedModeBanner: false,
      theme: buildPithTheme(),
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
  bool _isFanOutVisible = false;
  bool _isSearchVisible = false;
  late final AnimationController _fanOutController;

  static const _deck = DeckSummary(
    totalBirthdays: 60,
    title: '60 Birthdays\ntoday',
    subtitle: 'A significant moment in your network. Send a note.',
    avatars: ['S', 'M', 'E', '+57'],
  );

  static const _pulses = [
    PulseItem(
      name: 'Sarah Jenkins',
      meta: 'Last spoke 3 days ago',
      detail: 'Designer',
      initials: 'SJ',
      tint: Color(0xFF5F89C9),
    ),
    PulseItem(
      name: 'Marcus Aurelius',
      meta: 'Met at Coffee House',
      detail: 'Philosophy',
      initials: 'MA',
      tint: Color(0xFF7F6FCE),
    ),
    PulseItem(
      name: 'Elena Rodriguez',
      meta: 'Follow up on partnership',
      detail: 'Tomorrow',
      initials: 'ER',
      tint: Color(0xFFCA7B66),
    ),
  ];

  static const _birthdayContacts = [
    BirthdayContact(
      name: 'Eleanor Thorne',
      relation: 'Mom',
      subtitle: 'Turns 58',
      initials: 'ET',
      accent: Color(0xFFDEB06D),
      priority: BirthdayPriority.vip,
      group: BirthdayGroup.family,
      heightFactor: 1.26,
      actionIcon: Icons.card_giftcard_rounded,
    ),
    BirthdayContact(
      name: 'Julian Vance',
      relation: 'Brother',
      subtitle: 'Turns 24',
      initials: 'JV',
      accent: Color(0xFFC88559),
      priority: BirthdayPriority.vip,
      group: BirthdayGroup.family,
      heightFactor: 1.02,
      actionIcon: Icons.auto_awesome_rounded,
    ),
    BirthdayContact(
      name: 'Marcus Wright',
      relation: 'Colleague',
      subtitle: 'Design Team',
      initials: 'MW',
      accent: Color(0xFF5B78A6),
      priority: BirthdayPriority.standard,
      group: BirthdayGroup.innerCircle,
      heightFactor: 1.02,
    ),
    BirthdayContact(
      name: 'Clara Smith',
      relation: 'Old School Friend',
      subtitle: 'Inner Circle',
      initials: 'CS',
      accent: Color(0xFF7F6688),
      priority: BirthdayPriority.standard,
      group: BirthdayGroup.innerCircle,
      heightFactor: 0.9,
    ),
    BirthdayContact(
      name: 'Sarah Jenkins',
      relation: 'Acquaintance',
      subtitle: 'Tech Meetup',
      initials: 'SJ',
      accent: Color(0xFF708DB4),
      priority: BirthdayPriority.standard,
      group: BirthdayGroup.allContacts,
      heightFactor: 1.34,
    ),
    BirthdayContact(
      name: 'Leo Thompson',
      relation: 'Gym Member',
      subtitle: 'Networking',
      initials: 'LT',
      accent: Color(0xFF6E7789),
      priority: BirthdayPriority.standard,
      group: BirthdayGroup.allContacts,
      heightFactor: 1.18,
    ),
  ];

  static const _searchContacts = [
    SearchContact(
      name: 'Raphael Vance',
      description: 'Interested in 90s East Coast Rap',
      initials: 'RV',
      statusColor: Color(0xFF21C45D),
      highlighted: true,
    ),
    SearchContact(
      name: 'Sarah Rapp',
      description: 'Collector of vintage hip-hop vinyls',
      initials: 'SR',
      statusColor: Color(0xFF95A3B9),
      highlighted: false,
    ),
    SearchContact(
      name: 'Julian Rappaport',
      description: 'Producer, rap beats and lofi',
      initials: 'JR',
      statusColor: Color(0xFF21C45D),
      highlighted: true,
    ),
  ];

  static const _profile = ContactProfile(
    name: 'Julian Vane',
    subtitle: 'LONDON — ART CURATOR & SAILOR',
    initials: 'JV',
    interests: [
      ProfileInterest(label: 'Light Roast', icon: Icons.coffee_rounded),
      ProfileInterest(label: 'Analog Vinyl', icon: Icons.album_rounded),
      ProfileInterest(label: 'Coastal Racing', icon: Icons.sailing_rounded),
      ProfileInterest(label: 'Brutalism', icon: Icons.architecture_rounded),
    ],
    sparks: [
      QuickSparkEntry(
        dateLabel: 'OCT 14, 2023',
        content:
            'Mentioned wanting a first edition of "The Old Man and the Sea". Prefers the 1952 Scribner\'s cover.',
        highlighted: true,
      ),
      QuickSparkEntry(
        dateLabel: 'SEP 28, 2023',
        content:
            'Gift Idea: A high-quality set of brass drafting tools for his architectural sketches.',
      ),
      QuickSparkEntry(
        dateLabel: 'AUG 12, 2023',
        content:
            'Loves bitter chocolate and small-batch mezcal. Specifically mentions Joven styles.',
      ),
    ],
  );

  final List<ShellTabItem> _tabs = const [
    ShellTabItem(label: 'Home', icon: Icons.home_rounded),
    ShellTabItem(label: 'Stacks', icon: Icons.layers_rounded),
    ShellTabItem(label: 'Calendar', icon: Icons.calendar_today_rounded),
    ShellTabItem(label: 'Profile', icon: Icons.person_rounded),
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

  void _openSearch() {
    setState(() => _isSearchVisible = true);
  }

  void _closeSearch() {
    setState(() => _isSearchVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(
        deck: _deck,
        pulses: _pulses,
        onOpenBirthdays: _openBirthdayStack,
        onOpenSearch: _openSearch,
      ),
      BirthdayStackScreen(
        contacts: _birthdayContacts,
        onBack: () => setState(() => _currentIndex = 0),
        onOpenSearch: _openSearch,
      ),
      const PreviewScreen(
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
      const ProfileCanvasScreen(
        profile: _profile,
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
                child: BirthdayFanOutOverlay(
                  controller: _fanOutController,
                  contacts: _birthdayContacts.take(5).toList(),
                ),
              ),
            ),
          if (_isSearchVisible)
            Positioned.fill(
              child: PowerSearchScreen(
                initialQuery: 'Rap',
                results: _searchContacts,
                onClose: _closeSearch,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isSearchVisible
          ? null
          : Padding(
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
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (var index = 0; index < _tabs.length; index++)
                          Expanded(
                            child: ShellNavItem(
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