import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/models/pith_models.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/theme/pith_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/birthdays/birthday_stack_screen.dart';
import 'features/contacts/create_contact_sheet.dart';
import 'features/home/home_dashboard_screen.dart';
import 'features/profile/profile_canvas_screen.dart';
import 'features/radar/relationship_radar_screen.dart';
import 'features/search/power_search_screen.dart';
import 'features/sparks/quick_spark_parser.dart';
import 'features/success/note_success_screen.dart';
import 'features/shared/common_widgets.dart';
import 'core/supabase/supabase_sync_service.dart';

class PithApp extends StatelessWidget {
  const PithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pith',
      debugShowCheckedModeBanner: false,
      theme: buildPithTheme(),
      home: SupabaseBootstrap.isConfigured ? const _AuthGate() : const PithShell(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      initialData: AuthState(AuthChangeEvent.initialSession, auth.currentSession),
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session == null) {
          return const AuthScreen();
        }

        return const PithShell();
      },
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
  late List<BirthdayContact> _birthdayContacts;
  late List<SearchContact> _searchContacts;
  String _activeProfileName = '';
  int _profileReturnIndex = 0;
  late final AnimationController _fanOutController;

  static const _defaultBirthdayContacts = [
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

  static const _defaultSearchContacts = [
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
    if (SupabaseSyncService.instance.isEnabled) {
      _profiles = {};
      _birthdayContacts = [];
      _searchContacts = [];
      _activeProfileName = '';
    } else {
      _profiles = {
        _initialJulianProfile.name: _initialJulianProfile,
        _initialEleanorProfile.name: _initialEleanorProfile,
        _initialRaphaelProfile.name: _initialRaphaelProfile,
        _initialSarahProfile.name: _initialSarahProfile,
        _initialJulianRProfile.name: _initialJulianRProfile,
      };
      _birthdayContacts = List<BirthdayContact>.from(_defaultBirthdayContacts);
      _searchContacts = List<SearchContact>.from(_defaultSearchContacts);
      _activeProfileName = _initialJulianProfile.name;
    }
    _fanOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );

    unawaited(_hydrateFromSupabase());
  }

  Future<void> _hydrateFromSupabase() async {
    if (!SupabaseSyncService.instance.isEnabled) {
      return;
    }

    try {
      final contacts = await SupabaseSyncService.instance.loadContactsWithSparks();

      if (!mounted || contacts.isEmpty) {
        return;
      }

      setState(() {
        _profiles = {
          for (final contact in contacts) contact.fullName: _profileFromRemoteContact(contact),
        };
        _birthdayContacts = [
          for (final contact in contacts) _birthdayFromRemoteContact(contact),
        ];
        _searchContacts = [
          for (final contact in contacts) _searchFromRemoteContact(contact),
        ];

        if (_profiles.isNotEmpty && !_profiles.containsKey(_activeProfileName)) {
          _activeProfileName = _profiles.keys.first;
        }
      });
    } catch (_) {
      // Keep local fallback if sync fails.
    }
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

    if (_birthdayContacts.isEmpty) {
      setState(() {
        _currentIndex = 1;
      });
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

  ContactProfile get _activeProfile => _profiles[_activeProfileName] ?? _emptyProfile;

  ContactProfile get _emptyProfile => const ContactProfile(
        name: 'No contact selected',
        subtitle: 'ADD YOUR FIRST CONTACT TO START',
        initials: 'NA',
        interests: [
          ProfileInterest(label: 'Private CRM', icon: Icons.lock_rounded),
          ProfileInterest(label: 'Cloud Sync', icon: Icons.cloud_done_rounded),
        ],
        sparks: [
          QuickSparkEntry(
            dateLabel: 'TODAY',
            content: 'Create a contact from the + button in Stacks to begin.',
            highlighted: true,
          ),
        ],
      );

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

  ContactProfile _profileFromRemoteContact(SupabaseContactRecord contact) {
    final subtitle = contact.locationName.isEmpty
        ? '${contact.circleName.toUpperCase()} — CONTACT'
        : '${contact.locationName.toUpperCase()} — ${contact.circleName.toUpperCase()}';

    return ContactProfile(
      name: contact.fullName,
      subtitle: subtitle,
      initials: _initialsFromName(contact.fullName),
      interests: _inferInterestsFromRemoteSparks(contact.sparks),
      sparks: _sparksFromRemote(contact.sparks),
    );
  }

  BirthdayContact _birthdayFromRemoteContact(SupabaseContactRecord contact) {
    final group = _groupFromRemoteCircle(contact.circleName, contact.circlePriority);

    return BirthdayContact(
      name: contact.fullName,
      relation: contact.circleName,
      subtitle: _birthdaySubtitle(contact.birthday),
      initials: _initialsFromName(contact.fullName),
      accent: _colorFromHex(contact.circleColorHex),
      priority: contact.circlePriority <= 1 ? BirthdayPriority.vip : BirthdayPriority.standard,
      group: group,
      heightFactor: 0.92 + ((contact.fullName.length % 5) * 0.1),
      actionIcon: contact.circlePriority <= 2 ? Icons.card_giftcard_rounded : Icons.auto_awesome_rounded,
    );
  }

  SearchContact _searchFromRemoteContact(SupabaseContactRecord contact) {
    final previewSpark = contact.sparks.isEmpty ? '' : contact.sparks.first.content;
    final description = previewSpark.isEmpty
        ? 'Circle: ${contact.circleName}'
        : previewSpark.length > 46
            ? '${previewSpark.substring(0, 46)}...'
            : previewSpark;

    return SearchContact(
      name: contact.fullName,
      description: description,
      initials: _initialsFromName(contact.fullName),
      statusColor: contact.circlePriority <= 1
          ? const Color(0xFF21C45D)
          : const Color(0xFF95A3B9),
      highlighted: contact.circlePriority <= 2,
    );
  }

  List<ProfileInterest> _inferInterestsFromRemoteSparks(List<SupabaseSparkRecord> sparks) {
    final labels = <String>[];
    for (final spark in sparks) {
      final content = spark.content.toLowerCase();
      if (content.contains('rap') || content.contains('music') || content.contains('vinyl')) {
        labels.add('Music Tastes');
      }
      if (content.contains('coffee') || content.contains('cafe') || content.contains('espresso')) {
        labels.add('Cafe Rituals');
      }
      if (content.contains('gift') || content.contains('regalo')) {
        labels.add('Gift Clues');
      }
      if (content.contains('travel') || content.contains('trip') || content.contains('viaje')) {
        labels.add('Travel Plans');
      }
    }

    final unique = labels.toSet().take(4).toList();
    if (unique.isEmpty) {
      return const [
        ProfileInterest(label: 'Shared Moments', icon: Icons.auto_awesome_rounded),
        ProfileInterest(label: 'Follow-ups', icon: Icons.favorite_border_rounded),
      ];
    }

    return [
      for (final label in unique)
        ProfileInterest(
          label: label,
          icon: switch (label) {
            'Music Tastes' => Icons.music_note_rounded,
            'Cafe Rituals' => Icons.coffee_rounded,
            'Gift Clues' => Icons.card_giftcard_rounded,
            'Travel Plans' => Icons.flight_takeoff_rounded,
            _ => Icons.auto_awesome_rounded,
          },
        ),
    ];
  }

  List<QuickSparkEntry> _sparksFromRemote(List<SupabaseSparkRecord> sparks) {
    if (sparks.isEmpty) {
      return const [
        QuickSparkEntry(
          dateLabel: 'TODAY',
          content: 'Ready to capture your first spark.',
          highlighted: true,
        ),
      ];
    }

    return [
      for (var index = 0; index < sparks.take(8).length; index++)
        QuickSparkEntry(
          dateLabel: _formatDate(sparks[index].createdAt),
          content: sparks[index].content,
          highlighted: index == 0,
        ),
    ];
  }

  String _initialsFromName(String fullName) {
    final words = fullName
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'NA';
    }
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'.toUpperCase();
  }

  BirthdayGroup _groupFromRemoteCircle(String name, int priority) {
    final lowered = name.toLowerCase();
    if (lowered.contains('family')) {
      return BirthdayGroup.family;
    }
    if (priority <= 2 || lowered.contains('inner') || lowered.contains('vip')) {
      return BirthdayGroup.innerCircle;
    }
    return BirthdayGroup.allContacts;
  }

  String _birthdaySubtitle(DateTime? birthday) {
    if (birthday == null) {
      return 'No birthday yet';
    }
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[birthday.month - 1]} ${birthday.day}';
  }

  Color _colorFromHex(String value) {
    final cleaned = value.replaceAll('#', '').trim();
    if (cleaned.length != 6) {
      return const Color(0xFF708DB4);
    }

    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed == null) {
      return const Color(0xFF708DB4);
    }

    return Color(0xFF000000 | parsed);
  }

  String _formatDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  DeckSummary get _deckSummary {
    final total = _birthdayContacts.length;
    final avatars = _birthdayContacts
        .take(3)
        .map((contact) => contact.initials)
        .toList();

    if (total > 3) {
      avatars.add('+${total - 3}');
    }

    return DeckSummary(
      totalBirthdays: total,
      title: '$total Birthdays\ntoday',
      subtitle: total == 0
          ? 'Your network starts empty. Add your first contact.'
          : 'A significant moment in your network. Send a note.',
      avatars: avatars,
    );
  }

  List<PulseItem> get _pulseItems {
    final items = <PulseItem>[];
    for (final contact in _birthdayContacts.take(3)) {
      items.add(
        PulseItem(
          name: contact.name,
          meta: contact.relation,
          detail: contact.subtitle,
          initials: contact.initials,
          tint: contact.accent,
        ),
      );
    }
    return items;
  }

  ContactProfile _resolveProfileForSpark(String value) {
    if (_profiles.isEmpty) {
      return _emptyProfile;
    }

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
        recipientLabel: 'CONTACT',
        initials: contact.initials,
        statusLabel: 'Saved',
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

  Future<void> _openAccountSheet() async {
    if (!SupabaseSyncService.instance.isEnabled || !mounted) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuenta activa',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? 'Usuario autenticado',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9AA8C0),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Cerrar sesion'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onAddContact() async {
    final input = await showCreateContactSheet(context);
    if (!mounted || input == null) {
      return;
    }

    final mapping = _circleMapping(input.circleName);
    SupabaseContactRecord? remote;
    if (SupabaseSyncService.instance.isEnabled) {
      try {
        remote = await SupabaseSyncService.instance.createOrUpdateContact(
          CreateContactPayload(
            fullName: input.fullName,
            circleName: input.circleName,
            circlePriority: mapping.priority,
            circleColorHex: mapping.colorHex,
            locationName: input.locationName,
            birthday: input.birthday,
          ),
        );
      } catch (_) {
        remote = null;
      }
    }

    final record = remote ??
        SupabaseContactRecord(
          id: input.fullName,
          fullName: input.fullName,
          locationName: input.locationName,
          birthday: input.birthday,
          circleName: input.circleName,
          circlePriority: mapping.priority,
          circleColorHex: mapping.colorHex,
          sparks: const [],
        );

    final profile = _profileFromRemoteContact(record);
    final birthday = _birthdayFromRemoteContact(record);
    final search = _searchFromRemoteContact(record);

    setState(() {
      _profiles[profile.name] = profile;
      _birthdayContacts = [birthday, ..._birthdayContacts.where((item) => item.name != birthday.name)];
      _searchContacts = [search, ..._searchContacts.where((item) => item.name != search.name)];
      _activeProfileName = profile.name;
      _profileReturnIndex = _currentIndex;
      _currentIndex = 3;
      _sparkFeedback = SupabaseSyncService.instance.isEnabled
          ? 'Contacto guardado en Supabase: ${profile.name}'
          : 'Contacto creado en local: ${profile.name}';
    });
  }

  _CircleMapping _circleMapping(String circle) {
    return switch (circle) {
      'VIP' => const _CircleMapping(priority: 1, colorHex: '#F4C025'),
      'Family' => const _CircleMapping(priority: 1, colorHex: '#DEB06D'),
      'Inner Circle' => const _CircleMapping(priority: 2, colorHex: '#7F6688'),
      _ => const _CircleMapping(priority: 3, colorHex: '#6E7789'),
    };
  }

  void _submitSpark(String value) {
    if (_profiles.isEmpty) {
      setState(() {
        _sparkFeedback = 'No hay contactos aun. Crea uno desde Stacks con el boton +.';
      });
      return;
    }

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

      if (SupabaseSyncService.instance.isEnabled) {
        _sparkFeedback = '${_sparkFeedback!} • Sync Supabase OK';
      }
    });

    SupabaseSyncService.instance
        .saveSpark(profile: targetProfile, spark: parsed.spark)
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(
        deck: _deckSummary,
        pulses: _pulseItems,
        onOpenBirthdays: _openBirthdayStack,
        onOpenSearch: _openSearch,
        hasContacts: _profiles.isNotEmpty,
        onAddFirstContact: _onAddContact,
        onOpenAccount: _openAccountSheet,
        onSubmitSpark: _submitSpark,
        sparkFeedback: _sparkFeedback,
      ),
      BirthdayStackScreen(
        contacts: _birthdayContacts,
        onBack: () => setState(() => _currentIndex = 0),
        onOpenSearch: _openSearch,
        onSendNote: _sendBirthdayNote,
        onAddContact: _onAddContact,
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
                  Color(0xFF0A0C12),
                  Color(0xFF0D121A),
                  Color(0xFF0A0C12),
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
                  totalBirthdays: _birthdayContacts.length,
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

class _CircleMapping {
  const _CircleMapping({required this.priority, required this.colorHex});

  final int priority;
  final String colorHex;
}