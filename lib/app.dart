import 'dart:ui';

import 'package:flutter/material.dart';

import 'core/models/pith_models.dart';
import 'core/theme/pith_theme.dart';
import 'features/birthdays/birthday_stack_screen.dart';
import 'features/home/home_dashboard_screen.dart';
import 'features/profile/profile_canvas_screen.dart';
import 'features/radar/relationship_radar_screen.dart';
import 'features/search/power_search_screen.dart';
import 'features/sparks/quick_spark_parser.dart';
import 'features/success/note_success_screen.dart';
import 'features/shared/common_widgets.dart';

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
  NoteDeliveryReceipt? _noteReceipt;
  String? _sparkFeedback;
  late Map<String, ContactProfile> _profiles;
  String _activeProfileName = 'Julian Vane';
  int _profileReturnIndex = 0;
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
      name: 'Julian Vane',
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

  static const _initialRaphaelProfile = ContactProfile(
    name: 'Raphael Vance',
    subtitle: 'SAN CARLOS — PRODUCER & VINYL DIGGER',
    initials: 'RV',
    interests: [
      ProfileInterest(label: '90s Rap', icon: Icons.music_note_rounded),
      ProfileInterest(label: 'Vinyl Crates', icon: Icons.album_rounded),
      ProfileInterest(label: 'Studio Nights', icon: Icons.graphic_eq_rounded),
      ProfileInterest(label: 'Analog Mixers', icon: Icons.tune_rounded),
    ],
    sparks: [
      QuickSparkEntry(
        dateLabel: 'NOV 09, 2023',
        content: 'Wants a rare pressing of Nas - Illmatic (1994).',
        highlighted: true,
      ),
      QuickSparkEntry(
        dateLabel: 'OCT 02, 2023',
        content: 'Prefers warm lighting and analog gear when hosting sessions.',
      ),
    ],
  );

  static const _initialSarahProfile = ContactProfile(
    name: 'Sarah Rapp',
    subtitle: 'SAN CARLOS — CURATOR & COLLECTOR',
    initials: 'SR',
    interests: [
      ProfileInterest(label: 'Vintage Hip-Hop', icon: Icons.album_rounded),
      ProfileInterest(label: 'Archive Finds', icon: Icons.book_rounded),
      ProfileInterest(label: 'Gallery Walks', icon: Icons.palette_rounded),
      ProfileInterest(label: 'Late Espresso', icon: Icons.coffee_rounded),
    ],
    sparks: [
      QuickSparkEntry(
        dateLabel: 'OCT 21, 2023',
        content: 'Collecting underground tapes from early 90s crews.',
        highlighted: true,
      ),
      QuickSparkEntry(
        dateLabel: 'SEP 08, 2023',
        content: 'Always asks for liner notes and provenance details.',
      ),
    ],
  );

  static const _initialJulianRProfile = ContactProfile(
    name: 'Julian Rappaport',
    subtitle: 'SAN CARLOS — PRODUCER & LOFI ARTIST',
    initials: 'JR',
    interests: [
      ProfileInterest(label: 'Lofi Beats', icon: Icons.headphones_rounded),
      ProfileInterest(label: 'Downtempo', icon: Icons.graphic_eq_rounded),
      ProfileInterest(label: 'Modular Synths', icon: Icons.settings_input_component_rounded),
      ProfileInterest(label: 'Late Walks', icon: Icons.nights_stay_rounded),
    ],
    sparks: [
      QuickSparkEntry(
        dateLabel: 'NOV 05, 2023',
        content: 'Wants a custom tape run for his next EP release.',
        highlighted: true,
      ),
      QuickSparkEntry(
        dateLabel: 'AUG 19, 2023',
        content: 'Prefers analog tape warmth over digital mastering.',
      ),
    ],
  );

  static const _radarStories = [
    RadarStory(label: 'Trending', highlighted: true, accent: Color(0xFFF4C025)),
    RadarStory(label: 'Favorites', highlighted: false, accent: Color(0xFF8C9AB2)),
    RadarStory(label: 'Friends', highlighted: false, accent: Color(0xFF7590C0)),
    RadarStory(label: 'Family', highlighted: false, accent: Color(0xFFBA8B66)),
  ];

  static const _radarFeedCards = [
    RadarFeedCard(
      title: 'Moments from the weekend',
      description: 'Exploring the city lights with the crew.',
      actionLabel: 'View',
      gradient: [Color(0xFF223C72), Color(0xFF0F1730), Color(0xFF5F7088)],
    ),
    RadarFeedCard(
      title: 'New Project Launch',
      description: 'Finally sharing what I\'ve been working on.',
      actionLabel: 'Read',
      gradient: [Color(0xFF7F6652), Color(0xFF201716), Color(0xFF42506B)],
    ),
  ];

  static const _initialJulianProfile = ContactProfile(
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

  static const _initialEleanorProfile = ContactProfile(
    name: 'Eleanor Thorne',
    subtitle: 'FAMILY — TURNS 58',
    initials: 'ET',
    interests: [
      ProfileInterest(label: 'Sunday Roast', icon: Icons.restaurant_rounded),
      ProfileInterest(label: 'Garden Evenings', icon: Icons.local_florist_rounded),
      ProfileInterest(label: 'Opera Nights', icon: Icons.music_note_rounded),
      ProfileInterest(label: 'Handwritten Notes', icon: Icons.edit_rounded),
    ],
    sparks: [
      QuickSparkEntry(
        dateLabel: 'NOV 02, 2023',
        content: 'Prefers intimate birthday dinners over large gatherings.',
        highlighted: true,
      ),
      QuickSparkEntry(
        dateLabel: 'SEP 11, 2023',
        content: 'Always appreciates flowers in warm cream tones and handwritten cards.',
      ),
      QuickSparkEntry(
        dateLabel: 'JUN 18, 2023',
        content: 'Loves classic piano recordings and long Sunday lunches with family.',
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
    _profiles = {
      _initialJulianProfile.name: _initialJulianProfile,
      _initialEleanorProfile.name: _initialEleanorProfile,
      _initialRaphaelProfile.name: _initialRaphaelProfile,
      _initialSarahProfile.name: _initialSarahProfile,
      _initialJulianRProfile.name: _initialJulianRProfile,
    };
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

  void _openProfileFromSearch(SearchContact contact) {
    setState(() {
      _activeProfileName = contact.name;
      _profileReturnIndex = _currentIndex;
      _isSearchVisible = false;
      _currentIndex = 3;
    });
  }

  ContactProfile get _activeProfile =>
      _profiles[_activeProfileName] ?? _initialJulianProfile;

  ContactProfile _profileForContact(BirthdayContact contact) {
    return _profiles[contact.name] ??
        ContactProfile(
          name: contact.name,
          subtitle: '${contact.relation.toUpperCase()} — ${contact.subtitle.toUpperCase()}',
          initials: contact.initials,
          interests: const [
            ProfileInterest(label: 'Thoughtful Gifts', icon: Icons.card_giftcard_rounded),
            ProfileInterest(label: 'Warm Follow-ups', icon: Icons.favorite_border_rounded),
            ProfileInterest(label: 'Shared Moments', icon: Icons.auto_awesome_rounded),
          ],
          sparks: const [
            QuickSparkEntry(
              dateLabel: 'TODAY',
              content: 'Profile created from the birthday stack flow to continue the conversation.',
              highlighted: true,
            ),
          ],
        );
  }

  ContactProfile _resolveProfileForSpark(String value) {
    final match = RegExp(r'^@([^:]+):').firstMatch(value.trim());
    if (match == null) {
      return _activeProfile;
    }

    final mention = match.group(1)?.trim().toLowerCase() ?? '';
    for (final entry in _profiles.values) {
      final name = entry.name.toLowerCase();
      final initials = entry.initials.toLowerCase();
      if (name.contains(mention) || mention.contains(initials) || initials.contains(mention)) {
        return entry;
      }
    }

    return _activeProfile;
  }

  void _sendBirthdayNote(BirthdayContact contact) {
    setState(() {
      _profiles[contact.name] = _profileForContact(contact);
      _noteReceipt = NoteDeliveryReceipt(
        recipientName: contact.name,
        recipientLabel: 'RECIPIENT',
        initials: contact.initials,
        statusLabel: 'Delivered',
        accent: const Color(0xFFF4C025),
      );
    });
  }

  void _closeNoteSuccess() {
    setState(() => _noteReceipt = null);
  }

  void _returnToDashboard() {
    setState(() {
      _noteReceipt = null;
      _currentIndex = 0;
    });
  }

  void _viewNoteDetails() {
    final receipt = _noteReceipt;
    setState(() {
      if (receipt != null) {
        _activeProfileName = receipt.recipientName;
      }
      _profileReturnIndex = 1;
      _noteReceipt = null;
      _currentIndex = 3;
    });
  }

  void _openProfileFromTab() {
    setState(() {
      _profileReturnIndex = _currentIndex == 3 ? 0 : _currentIndex;
      _currentIndex = 3;
    });
  }

  void _backFromProfile() {
    setState(() {
      _currentIndex = _profileReturnIndex;
    });
  }

  void _onNavTap(int index) {
    if (index == 3) {
      _openProfileFromTab();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _submitSpark(String value) {
    final targetProfile = _resolveProfileForSpark(value);
    final parsed = QuickSparkParser.parse(input: value, profile: targetProfile);
    if (parsed == null) {
      setState(() {
        _sparkFeedback = 'Spark no valido. Usa @Julian: ... o escribe una nota directa.';
      });
      return;
    }

    final updatedInterests = [...targetProfile.interests, ...parsed.inferredInterests];
    final addedLabels = parsed.inferredInterests.map((entry) => entry.label).toList();

    setState(() {
      _profiles[targetProfile.name] = targetProfile.copyWith(
        interests: updatedInterests.take(6).toList(),
        sparks: [parsed.spark, ...targetProfile.sparks],
      );
      _activeProfileName = targetProfile.name;
      _sparkFeedback = addedLabels.isEmpty
          ? 'Spark guardado en ${targetProfile.name}.'
          : 'Spark guardado en ${targetProfile.name} • Nuevos tags: ${addedLabels.join(', ')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(
        deck: _deck,
        pulses: _pulses,
        onOpenBirthdays: _openBirthdayStack,
        onOpenSearch: _openSearch,
        onSubmitSpark: _submitSpark,
        sparkFeedback: _sparkFeedback,
      ),
      BirthdayStackScreen(
        contacts: _birthdayContacts,
        onBack: () => setState(() => _currentIndex = 0),
        onOpenSearch: _openSearch,
        onSendNote: _sendBirthdayNote,
      ),
      const RelationshipRadarScreen(
        stories: _radarStories,
        feedCards: _radarFeedCards,
      ),
      ProfileCanvasScreen(
        profile: _activeProfile,
        onSubmitSpark: _submitSpark,
        onBack: _backFromProfile,
        sparkFeedback: _sparkFeedback,
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
                onSelectResult: _openProfileFromSearch,
              ),
            ),
          if (_noteReceipt != null)
            Positioned.fill(
              child: NoteSuccessScreen(
                receipt: _noteReceipt!,
                onClose: _closeNoteSuccess,
                onReturnToDashboard: _returnToDashboard,
                onViewDetails: _viewNoteDetails,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isSearchVisible || _noteReceipt != null
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
                              onTap: () => _onNavTap(index),
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