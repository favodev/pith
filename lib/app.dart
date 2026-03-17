import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/circle_labels.dart';
import 'core/models/pith_models.dart';
import 'core/services/haptics_service.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/utils/date_labels.dart';
import 'core/theme/pith_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/supabase_required_screen.dart';
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
      home: SupabaseBootstrap.isConfigured
          ? const _AuthGate()
          : const SupabaseRequiredScreen(),
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
  int _pendingAsyncOps = 0;
  NoteDeliveryReceipt? _noteReceipt;
  String? _sparkFeedback;
  late Map<String, ContactProfile> _profiles;
  late Map<String, SupabaseContactRecord> _remoteContactsByName;
  late List<BirthdayContact> _birthdayContacts;
  late List<SearchContact> _searchContacts;
  String _activeProfileName = '';
  int _profileReturnIndex = 0;
  late final AnimationController _fanOutController;


  final List<ShellTabItem> _tabs = const [
    ShellTabItem(label: 'Inicio', icon: Icons.home_rounded),
    ShellTabItem(label: 'Pilas', icon: Icons.layers_rounded),
    ShellTabItem(label: 'Calendario', icon: Icons.calendar_today_rounded),
    ShellTabItem(label: 'Perfil', icon: Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _profiles = {};
    _remoteContactsByName = {};
    _birthdayContacts = [];
    _searchContacts = [];
    _activeProfileName = '';
    _fanOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );

    _hydrateFromSupabase();
  }

  Future<void> _hydrateFromSupabase() async {
    if (!SupabaseSyncService.instance.isEnabled) {
      return;
    }

    try {
      final contacts = await _runBusy(
        () => SupabaseSyncService.instance.loadContactsWithSparks(),
      );

      if (!mounted || contacts.isEmpty) {
        return;
      }

      setState(() {
        _remoteContactsByName = {
          for (final contact in contacts) contact.fullName: contact,
        };
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

  bool get _isBusy => _pendingAsyncOps > 0;

  Future<T> _runBusy<T>(Future<T> Function() action) async {
    if (mounted) {
      setState(() => _pendingAsyncOps++);
    } else {
      _pendingAsyncOps++;
    }

    try {
      return await action();
    } finally {
      if (!mounted) {
        _pendingAsyncOps = (_pendingAsyncOps - 1).clamp(0, 9999).toInt();
      } else {
        setState(() {
          _pendingAsyncOps = (_pendingAsyncOps - 1).clamp(0, 9999).toInt();
        });
      }
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

    unawaited(HapticsService.tap());

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
    unawaited(HapticsService.select());
    setState(() => _isSearchVisible = true);
  }

  void _closeSearch() {
    setState(() => _isSearchVisible = false);
  }

  void _openProfileFromSearch(SearchContact contact) {
    unawaited(HapticsService.select());
    setState(() {
      _activeProfileName = contact.name;
      _profileReturnIndex = _currentIndex;
      _isSearchVisible = false;
      _currentIndex = 3;
    });
  }

  ContactProfile get _activeProfile => _profiles[_activeProfileName] ?? _emptyProfile;

  ContactProfile get _emptyProfile => const ContactProfile(
        name: 'Sin contacto seleccionado',
        subtitle: 'AGREGA TU PRIMER CONTACTO PARA EMPEZAR',
        initials: 'SC',
        interests: [
          ProfileInterest(label: 'CRM privado', icon: Icons.lock_rounded),
          ProfileInterest(label: 'Sincronizacion nube', icon: Icons.cloud_done_rounded),
        ],
        sparks: [
          QuickSparkEntry(
            dateLabel: 'HOY',
            content: 'Crea un contacto desde el boton + en Pilas para empezar.',
            highlighted: true,
          ),
        ],
      );

  ContactProfile _profileFromRemoteContact(SupabaseContactRecord contact) {
    final subtitle = contact.locationName.isEmpty
      ? '${contact.circleName.toUpperCase()} — CONTACTO'
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
    final group = _groupFromRemoteCircle(contact.circleName);

    return BirthdayContact(
      name: contact.fullName,
      relation: contact.circleName,
      birthday: contact.birthday,
      subtitle: _birthdaySubtitle(contact.birthday),
      initials: _initialsFromName(contact.fullName),
      accent: _colorFromHex(contact.circleColorHex),
      priority: contact.circlePriority <= 1 ? BirthdayPriority.highlighted : BirthdayPriority.standard,
      group: group,
      heightFactor: 0.92 + ((contact.fullName.length % 5) * 0.1),
      actionIcon: contact.circlePriority <= 2 ? Icons.card_giftcard_rounded : Icons.auto_awesome_rounded,
    );
  }

  SearchContact _searchFromRemoteContact(SupabaseContactRecord contact) {
    final previewSpark = contact.sparks.isEmpty ? '' : contact.sparks.first.content;
    final description = previewSpark.isEmpty
      ? 'Circulo: ${contact.circleName}'
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
        labels.add('Gustos musicales');
      }
      if (content.contains('coffee') || content.contains('cafe') || content.contains('espresso')) {
        labels.add('Rituales de cafe');
      }
      if (content.contains('gift') || content.contains('regalo')) {
        labels.add('Pistas de regalo');
      }
      if (content.contains('travel') || content.contains('trip') || content.contains('viaje')) {
        labels.add('Planes de viaje');
      }
    }

    final unique = labels.toSet().take(4).toList();
    if (unique.isEmpty) {
      return const [
        ProfileInterest(label: 'Momentos compartidos', icon: Icons.auto_awesome_rounded),
        ProfileInterest(label: 'Seguimientos', icon: Icons.favorite_border_rounded),
      ];
    }

    return [
      for (final label in unique)
        ProfileInterest(
          label: label,
          icon: switch (label) {
            'Gustos musicales' => Icons.music_note_rounded,
            'Rituales de cafe' => Icons.coffee_rounded,
            'Pistas de regalo' => Icons.card_giftcard_rounded,
            'Planes de viaje' => Icons.flight_takeoff_rounded,
            _ => Icons.auto_awesome_rounded,
          },
        ),
    ];
  }

  List<QuickSparkEntry> _sparksFromRemote(List<SupabaseSparkRecord> sparks) {
    if (sparks.isEmpty) {
      return const [
        QuickSparkEntry(
          dateLabel: 'HOY',
          content: 'Listo para capturar tu primera nota.',
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
      return 'SC';
    }
    if (words.length == 1) {
      return _firstLetter(words.first).toUpperCase();
    }
    return '${_firstLetter(words.first)}${_firstLetter(words.last)}'.toUpperCase();
  }

  String _firstLetter(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    return String.fromCharCode(trimmed.runes.first);
  }

  BirthdayGroup _groupFromRemoteCircle(String name) {
    final normalized = CircleLabels.normalize(name).toLowerCase();
    if (normalized == CircleLabels.family.toLowerCase()) {
      return BirthdayGroup.family;
    }
    if (normalized == CircleLabels.friends.toLowerCase()) {
      return BirthdayGroup.innerCircle;
    }
    return BirthdayGroup.allContacts;
  }

  bool _isBirthdayToday(DateTime? birthday) {
    if (birthday == null) {
      return false;
    }

    final now = DateTime.now();
    return birthday.month == now.month && birthday.day == now.day;
  }

  List<BirthdayContact> get _todayBirthdayContacts {
    return _birthdayContacts
        .where((contact) => _isBirthdayToday(contact.birthday))
        .toList();
  }

  String _birthdaySubtitle(DateTime? birthday) {
    if (birthday == null) {
      return 'Sin cumpleanos';
    }
    return DateLabels.monthDay(birthday);
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
    return DateLabels.monthDayYear(date);
  }

  DeckSummary get _deckSummary {
    final todayContacts = _todayBirthdayContacts;
    final total = todayContacts.length;
    final avatars = todayContacts
        .take(3)
        .map((contact) => contact.initials)
        .toList();

    if (total > 3) {
      avatars.add('+${total - 3}');
    }

    return DeckSummary(
      totalBirthdays: total,
      title: '$total Cumpleanos\nde hoy',
      subtitle: total == 0
          ? 'Tu red esta vacia. Agrega tu primer contacto.'
          : 'Un momento importante en tu red. Envia una nota.',
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

  List<RadarStory> get _radarStories {
    final hasFriends = _birthdayContacts.any(
      (c) => CircleLabels.normalize(c.relation) == CircleLabels.friends,
    );
    final hasFamily = _birthdayContacts.any(
      (c) => c.group == BirthdayGroup.family || c.relation.toLowerCase().contains('familia'),
    );

    return [
      const RadarStory(label: 'Tendencia', highlighted: true, accent: Color(0xFFF4C025)),
      RadarStory(
        label: 'Amigos',
        highlighted: hasFriends,
        accent: hasFriends ? const Color(0xFFF4C025) : const Color(0xFF8C9AB2),
      ),
      RadarStory(
        label: 'Contactos',
        highlighted: _profiles.length >= 3,
        accent: const Color(0xFF7590C0),
      ),
      RadarStory(
        label: 'Familia',
        highlighted: hasFamily,
        accent: const Color(0xFFBA8B66),
      ),
    ];
  }

  List<RadarFeedCard> get _radarFeedCards {
    final cards = <RadarFeedCard>[];

    if (_todayBirthdayContacts.isNotEmpty) {
      final first = _todayBirthdayContacts.first;
      cards.add(
        RadarFeedCard(
          title: 'Cumpleanos activo: ${first.name}',
          description: 'Revisa notas y recuerdos para escribir un saludo con contexto.',
          actionLabel: 'Abrir perfil',
          gradient: const [Color(0xFF223C72), Color(0xFF0F1730), Color(0xFF5F7088)],
        ),
      );
    }

    final profile = _activeProfile;
    if (profile.sparks.isNotEmpty) {
      cards.add(
        RadarFeedCard(
          title: 'Ultima nota de ${profile.name}',
          description: profile.sparks.first.content,
          actionLabel: 'Ver detalles',
          gradient: const [Color(0xFF7F6652), Color(0xFF201716), Color(0xFF42506B)],
        ),
      );
    }

    if (cards.isEmpty) {
      cards.add(
        const RadarFeedCard(
          title: 'Tu radar aun no tiene actividad',
          description: 'Agrega contactos y notas para activar recomendaciones y contexto.',
          actionLabel: 'Comenzar',
          gradient: [Color(0xFF223C72), Color(0xFF0F1730), Color(0xFF5F7088)],
        ),
      );
    }

    return cards;
  }

  ContactProfile _resolveProfileForSpark(String value) {
    if (_profiles.isEmpty) {
      return _emptyProfile;
    }

    final match = RegExp(r'^@([^:]+?)\s*:').firstMatch(value.trim());
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
    unawaited(HapticsService.success());
    final targetProfile = _profiles[contact.name];
    if (targetProfile == null) {
      setState(() {
        _sparkFeedback = 'No se encontro el perfil del contacto. Recarga e intenta nuevamente.';
      });
      return;
    }

    setState(() {
      _noteReceipt = NoteDeliveryReceipt(
        recipientName: contact.name,
        recipientLabel: 'CONTACTO',
        initials: contact.initials,
        statusLabel: 'Guardado',
        accent: const Color(0xFFF4C025),
      );
    });

    final birthdaySpark = QuickSparkParseResult(
      spark: QuickSparkEntry(
        dateLabel: _formatDate(DateTime.now()),
        content: 'Nota de cumpleanos guardada.',
        highlighted: true,
      ),
      inferredInterests: const [],
    );
    unawaited(_saveSparkToSupabase(targetProfile: targetProfile, parsed: birthdaySpark));
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

  void _handleRadarAction(RadarFeedCard card) {
    if (card.title.toLowerCase().contains('cumpleanos')) {
      _openBirthdayStack();
      return;
    }

    if (_activeProfileName.isNotEmpty && _profiles.containsKey(_activeProfileName)) {
      setState(() {
        _profileReturnIndex = _currentIndex;
        _currentIndex = 3;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == 3) {
      _openProfileFromTab();
      return;
    }

    unawaited(HapticsService.select());

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
                      SupabaseSyncService.instance.clearSessionCache();
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
    SupabaseContactRecord? record;
    try {
      record = await _runBusy(
        () => SupabaseSyncService.instance.createOrUpdateContact(
          CreateContactPayload(
            fullName: input.fullName,
            circleName: input.circleName,
            circlePriority: mapping.priority,
            circleColorHex: mapping.colorHex,
            locationName: input.locationName,
            birthday: input.birthday,
          ),
        ),
      );
    } on SupabaseSyncException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo guardar el contacto. ${error.message}';
      });
      return;
    } catch (_) {
      record = null;
    }

    if (!mounted) {
      return;
    }

    if (record == null) {
      unawaited(HapticsService.warning());
      setState(() {
        _sparkFeedback = 'No se pudo guardar en Supabase. Revisa la conexion e intenta de nuevo.';
      });
      return;
    }

    unawaited(HapticsService.success());

    final savedRecord = record;

    final profile = _profileFromRemoteContact(savedRecord);
    final birthday = _birthdayFromRemoteContact(savedRecord);
    final search = _searchFromRemoteContact(savedRecord);

    setState(() {
      _remoteContactsByName[savedRecord.fullName] = savedRecord;
      _profiles[profile.name] = profile;
      _birthdayContacts = [
        birthday,
        ..._birthdayContacts.where((item) => item.name != savedRecord.fullName),
      ];
      _searchContacts = [search, ..._searchContacts.where((item) => item.name != search.name)];
      _activeProfileName = profile.name;
      _profileReturnIndex = _currentIndex;
      _currentIndex = 3;
      _sparkFeedback = 'Contacto guardado en Supabase: ${profile.name}';
    });
  }

  _CircleMapping _circleMapping(String circle) {
    return switch (CircleLabels.normalize(circle)) {
      CircleLabels.family => const _CircleMapping(priority: 1, colorHex: '#DEB06D'),
      CircleLabels.friends => const _CircleMapping(priority: 2, colorHex: '#7F6688'),
      CircleLabels.work => const _CircleMapping(priority: 3, colorHex: '#4A84C6'),
      CircleLabels.acquaintances => const _CircleMapping(priority: 4, colorHex: '#6E7789'),
      _ => const _CircleMapping(priority: 3, colorHex: '#6E7789'),
    };
  }

  Future<void> _openActiveProfileActions() async {
    if (_activeProfileName.isEmpty || !_profiles.containsKey(_activeProfileName)) {
      return;
    }

    final profileName = _activeProfileName;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Acciones de contacto sincronizadas con Supabase.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9AA8C0),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _editContact(profileName);
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar contacto'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _confirmAndDeleteContact(profileName);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Eliminar contacto'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editContact(String oldName) async {
    final existing = _remoteContactsByName[oldName];
    if (existing == null) {
      setState(() {
        _sparkFeedback = 'No se encontro el contacto para editar. Recarga la app e intenta de nuevo.';
      });
      return;
    }

    final input = await showEditContactSheet(
      context,
      initial: ContactFormInitialData(
        fullName: existing.fullName,
        circleName: existing.circleName,
        locationName: existing.locationName,
        birthday: existing.birthday,
      ),
    );

    if (!mounted || input == null) {
      return;
    }

    final mapping = _circleMapping(input.circleName);

    SupabaseContactRecord? updated;
    try {
      updated = await _runBusy(
        () => SupabaseSyncService.instance.updateContactById(
          contactId: existing.id,
          payload: CreateContactPayload(
            fullName: input.fullName,
            circleName: input.circleName,
            circlePriority: mapping.priority,
            circleColorHex: mapping.colorHex,
            locationName: input.locationName,
            birthday: input.birthday,
          ),
        ),
      );
    } on SupabaseSyncException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo actualizar el contacto. ${error.message}';
      });
      return;
    } catch (_) {
      updated = null;
    }

    if (!mounted || updated == null) {
      unawaited(HapticsService.warning());
      setState(() {
        _sparkFeedback = 'No se pudo actualizar en Supabase. Verifica datos e intenta nuevamente.';
      });
      return;
    }

    unawaited(HapticsService.success());

    final updatedRecord = updated;

    final profile = _profileFromRemoteContact(updatedRecord);
    final birthday = _birthdayFromRemoteContact(updatedRecord);
    final search = _searchFromRemoteContact(updatedRecord);

    setState(() {
      _remoteContactsByName.remove(oldName);
      _remoteContactsByName[updatedRecord.fullName] = updatedRecord;

      _profiles.remove(oldName);
      _profiles[profile.name] = profile;

      _birthdayContacts = [
        birthday,
        ..._birthdayContacts.where((item) => item.name != oldName && item.name != updatedRecord.fullName),
      ];
      _searchContacts = [
        search,
        ..._searchContacts.where((item) => item.name != oldName && item.name != search.name),
      ];

      _activeProfileName = profile.name;
      _sparkFeedback = 'Contacto actualizado en Supabase: ${profile.name}';
    });
  }

  Future<void> _confirmAndDeleteContact(String name) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar contacto?'),
          content: Text('Esto eliminara permanentemente a $name y sus notas en Supabase.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      unawaited(HapticsService.warning());
      await _deleteContact(name);
    }
  }

  Future<void> _deleteContact(String name) async {
    try {
      await _runBusy(() => SupabaseSyncService.instance.deleteContactByName(name));
    } on SupabaseSyncException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo eliminar el contacto. ${error.message}';
      });
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo eliminar en Supabase. Intenta nuevamente.';
      });
      return;
    }

    unawaited(HapticsService.success());

    if (!mounted) {
      return;
    }

    setState(() {
      _remoteContactsByName.remove(name);
      _profiles.remove(name);
      _birthdayContacts = _birthdayContacts.where((item) => item.name != name).toList();
      _searchContacts = _searchContacts.where((item) => item.name != name).toList();
      _activeProfileName = _profiles.isEmpty ? '' : _profiles.keys.first;
      _currentIndex = 0;
      _sparkFeedback = 'Contacto eliminado en Supabase: $name';
    });
  }

  void _submitSpark(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _sparkFeedback = 'Escribe una nota antes de guardar.';
      });
      return;
    }

    if (_profiles.isEmpty) {
      setState(() {
        _sparkFeedback = 'No hay contactos aun. Crea uno desde Pilas con el boton +.';
      });
      return;
    }

    final targetProfile = _resolveProfileForSpark(trimmed);
    final parsed = QuickSparkParser.parse(input: trimmed, profile: targetProfile);
    if (parsed == null) {
      unawaited(HapticsService.warning());
      setState(() {
        _sparkFeedback = 'Nota no valida. Escribe una nota o usa @Nombre: para dirigirla a otro contacto.';
      });
      return;
    }

    unawaited(_saveSparkToSupabase(targetProfile: targetProfile, parsed: parsed));
  }

  Future<void> _saveSparkToSupabase({
    required ContactProfile targetProfile,
    required QuickSparkParseResult parsed,
  }) async {
    try {
      await _runBusy(
        () => SupabaseSyncService.instance.saveSpark(
          profile: targetProfile,
          spark: parsed.spark,
        ),
      );
    } on SupabaseSyncException catch (error) {
      unawaited(HapticsService.warning());
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo guardar la nota. ${error.message}';
      });
      return;
    } catch (_) {
      unawaited(HapticsService.warning());
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo guardar la nota en Supabase. Intenta nuevamente.';
      });
      return;
    }

    unawaited(HapticsService.success());

    if (!mounted) {
      return;
    }

    final latestProfile = _profiles[targetProfile.name] ?? targetProfile;
    final updatedInterests = [...latestProfile.interests, ...parsed.inferredInterests];
    final addedLabels = parsed.inferredInterests.map((entry) => entry.label).toList();

    setState(() {
      _profiles[targetProfile.name] = latestProfile.copyWith(
        interests: updatedInterests.take(6).toList(),
        sparks: [parsed.spark, ...latestProfile.sparks],
      );
      _activeProfileName = targetProfile.name;
        _sparkFeedback = addedLabels.isEmpty
          ? 'Nota guardada en ${targetProfile.name} • Sincronizacion Supabase OK'
          : 'Nota guardada en ${targetProfile.name} • Nuevos tags: ${addedLabels.join(', ')} • Sincronizacion Supabase OK';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Supabase.instance.client.auth.currentSession == null) {
      return const AuthScreen();
    }

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
        todayCount: _todayBirthdayContacts.length,
        onBack: () => setState(() => _currentIndex = 0),
        onOpenSearch: _openSearch,
        onSendNote: _sendBirthdayNote,
        onAddContact: _onAddContact,
      ),
      RelationshipRadarScreen(
        stories: _radarStories,
        feedCards: _radarFeedCards,
        onTapCardAction: _handleRadarAction,
      ),
      ProfileCanvasScreen(
        profile: _activeProfile,
        onSubmitSpark: _submitSpark,
        onBack: _backFromProfile,
        onOpenContactActions: _openActiveProfileActions,
        sparkFeedback: _sparkFeedback,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          ColoredBox(
            color: Color(0xFF070B13),
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
                  contacts: (_todayBirthdayContacts.isEmpty ? _birthdayContacts : _todayBirthdayContacts)
                      .take(5)
                      .toList(),
                  totalBirthdays: _todayBirthdayContacts.length,
                ),
              ),
            ),
          if (_isSearchVisible)
            Positioned.fill(
              child: PowerSearchScreen(
                initialQuery: '',
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
          if (_isBusy)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: const Color(0xFFF4C025),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
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