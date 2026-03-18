import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/circle_labels.dart';
import 'core/models/pith_models.dart';
import 'core/services/haptics_service.dart';
import 'core/services/birthday_notification_service.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/utils/date_labels.dart';
import 'core/theme/pith_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/supabase_required_screen.dart';
import 'features/birthdays/birthday_stack_screen.dart';
import 'features/contacts/create_contact_sheet.dart';
import 'features/home/home_dashboard_screen.dart';
import 'features/profile/profile_canvas_screen.dart';
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
  static const _homeTabIndex = 0;
  static const _birthdaysTabIndex = 1;
  static const _profileTabIndex = 2;

  int _currentIndex = 0;
  bool _isFanOutVisible = false;
  int _pendingAsyncOps = 0;
  NoteDeliveryReceipt? _noteReceipt;
  String? _sparkFeedback;
  late Map<String, ContactProfile> _profiles;
  late Map<String, SupabaseContactRecord> _remoteContactsByName;
  late List<BirthdayContact> _birthdayContacts;
  String _activeProfileName = '';
  int _profileReturnIndex = 0;
  late final AnimationController _fanOutController;


  final List<ShellTabItem> _tabs = const [
    ShellTabItem(label: 'Inicio', icon: Icons.home_rounded),
    ShellTabItem(label: 'Contactos', icon: Icons.layers_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _profiles = {};
    _remoteContactsByName = {};
    _birthdayContacts = [];
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

        if (_profiles.isNotEmpty && !_profiles.containsKey(_activeProfileName)) {
          _activeProfileName = _profiles.keys.first;
        }
      });

      unawaited(_syncBirthdayNotifications());
    } catch (_) {
      // Keep local fallback if sync fails.
    }
  }

  Future<void> _syncBirthdayNotifications() async {
    final reminders = [
      for (final contact in _remoteContactsByName.values)
        if (contact.birthday != null)
          BirthdayReminderTarget(
            contactId: contact.id,
            name: contact.fullName,
            birthday: contact.birthday!,
          ),
    ];

    await BirthdayNotificationService.instance.syncBirthdays(reminders);
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
    unawaited(_openSearchSheet());
  }

  Future<void> _openSearchSheet() async {
    unawaited(HapticsService.select());

    final contacts = _profiles.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final controller = TextEditingController();

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = controller.text.trim().toLowerCase();
            final filtered = contacts.where((contact) {
              if (query.isEmpty) {
                return true;
              }
              return contact.name.toLowerCase().contains(query) ||
                  contact.subtitle.toLowerCase().contains(query);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscar contacto',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Escribe un nombre',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: controller.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  controller.clear();
                                  setSheetState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Text(
                                contacts.isEmpty
                                    ? 'Aun no tienes contactos guardados.'
                                    : 'No hay coincidencias para tu busqueda.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF9AA8C0),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final contact = filtered[index];
                                return ListTile(
                                  tileColor: Colors.white.withValues(alpha: 0.04),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0x223B4A63),
                                    child: Text(contact.initials),
                                  ),
                                  title: Text(contact.name),
                                  subtitle: Text(
                                    contact.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    if (!mounted) {
                                      return;
                                    }
                                    setState(() {
                                      _activeProfileName = contact.name;
                                      _profileReturnIndex = _currentIndex;
                                      _currentIndex = _profileTabIndex;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
            content: 'Crea un contacto desde el boton + en Contactos para empezar.',
            highlighted: true,
          ),
        ],
      );

  ContactProfile _profileFromRemoteContact(SupabaseContactRecord contact) {
    final subtitle = '${contact.circleName.toUpperCase()} — CONTACTO';

    final persistedInterests = [
      for (final label in contact.interestLabels)
        ProfileInterest(label: label, icon: _interestIconForLabel(label)),
    ];

    return ContactProfile(
      name: contact.fullName,
      subtitle: subtitle,
      initials: _initialsFromName(contact.fullName),
      interests: persistedInterests.isEmpty
          ? _inferInterestsFromRemoteSparks(contact.sparks)
          : persistedInterests,
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
      return const [];
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
      for (var index = 0; index < sparks.length; index++)
        QuickSparkEntry(
          dateLabel: _formatDate(sparks[index].createdAt),
          content: sparks[index].content,
          iconType: sparks[index].iconType,
          highlighted: index == 0,
        ),
    ];
  }

  IconData _interestIconForLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('mus')) {
      return Icons.music_note_rounded;
    }
    if (normalized.contains('cafe')) {
      return Icons.coffee_rounded;
    }
    if (normalized.contains('regalo')) {
      return Icons.card_giftcard_rounded;
    }
    if (normalized.contains('viaje') || normalized.contains('lugar')) {
      return Icons.flight_takeoff_rounded;
    }
    if (normalized.contains('fecha')) {
      return Icons.event_rounded;
    }
    return Icons.auto_awesome_rounded;
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
    if (normalized == CircleLabels.work.toLowerCase()) {
      return BirthdayGroup.work;
    }
    if (normalized == CircleLabels.acquaintances.toLowerCase()) {
      return BirthdayGroup.acquaintances;
    }
    return BirthdayGroup.allContacts;
  }

  bool _isBirthdayToday(DateTime? birthday) {
    return _daysUntilBirthday(birthday) == 0;
  }

  int? _daysUntilBirthday(DateTime? birthday) {
    if (birthday == null) {
      return null;
    }

    final now = DateTime.now();
    DateTime next = _safeBirthdayForYear(birthday, now.year);
    if (next.isBefore(DateTime(now.year, now.month, now.day))) {
      next = _safeBirthdayForYear(birthday, now.year + 1);
    }

    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  DateTime _safeBirthdayForYear(DateTime birthday, int year) {
    final month = birthday.month;
    final day = birthday.day;
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextMonthYear = month == 12 ? year + 1 : year;
    final lastDay = DateTime(nextMonthYear, nextMonth, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay).toInt());
  }

  List<BirthdayContact> get _upcomingBirthdayContacts {
    final list = _birthdayContacts.where((contact) {
      final days = _daysUntilBirthday(contact.birthday);
      return days != null && days <= 14;
    }).toList();

    list.sort((a, b) {
      final aDays = _daysUntilBirthday(a.birthday) ?? 999;
      final bDays = _daysUntilBirthday(b.birthday) ?? 999;
      return aDays.compareTo(bDays);
    });

    return list;
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

    final days = _daysUntilBirthday(birthday);
    if (days == null) {
      return DateLabels.monthDay(birthday);
    }
    if (days == 0) {
      return 'Hoy';
    }
    if (days == 1) {
      return 'Manana';
    }
    return 'Faltan $days dias';
  }

  Color _colorFromHex(String value) {
    final cleaned = value.replaceAll('#', '').trim();
    if (cleaned.length != 6) {
      debugPrint('Color de circulo invalido (longitud): $value');
      return const Color(0xFF708DB4);
    }

    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed == null) {
      debugPrint('Color de circulo invalido (parse): $value');
      return const Color(0xFF708DB4);
    }

    return Color(0xFF000000 | parsed);
  }

  String _formatDate(DateTime date) {
    return DateLabels.monthDayYear(date);
  }

  DeckSummary get _deckSummary {
    final upcomingContacts = _upcomingBirthdayContacts;
    final total = upcomingContacts.length;
    final avatars = upcomingContacts
        .take(3)
        .map((contact) => contact.initials)
        .toList();

    if (total > 3) {
      avatars.add('+${total - 3}');
    }

    return DeckSummary(
      totalBirthdays: total,
      title: '$total Cumpleanos\nproximos 14 dias',
      subtitle: total == 0
          ? 'Tu red esta vacia. Agrega tu primer contacto.'
          : 'Activa recordatorios y prepara un detalle a tiempo.',
      avatars: avatars,
    );
  }

  List<PulseItem> get _pulseItems {
    final items = <PulseItem>[];
    for (final contact in _upcomingBirthdayContacts.take(3)) {
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

    final lowered = value.toLowerCase();
    final sorted = _profiles.values.toList()
      ..sort((a, b) => b.name.length.compareTo(a.name.length));

    for (final entry in sorted) {
      final name = entry.name.toLowerCase();
      final firstName = name.split(' ').first;
      final initials = entry.initials.toLowerCase();
      if (lowered.contains('@$name') || lowered.contains('@$firstName') || lowered.contains('@$initials')) {
        return entry;
      }
    }

    final match = RegExp(r'@([^\s:]+)').firstMatch(value.trim());
    final mention = match?.group(1)?.trim().toLowerCase() ?? '';
    if (mention.isEmpty) {
      return _activeProfile;
    }

    for (final entry in _profiles.values) {
      final name = entry.name.toLowerCase();
      final initials = entry.initials.toLowerCase();
      if (name.contains(mention) || mention.contains(initials) || initials.contains(mention)) {
        return entry;
      }
    }

    return _activeProfile;
  }

  bool _hasExplicitMention(String value) {
    return RegExp(r'@[^\s:]+').hasMatch(value);
  }

  Future<ContactProfile?> _pickContactForSpark() async {
    if (_profiles.isEmpty || !mounted) {
      return null;
    }

    final contacts = _profiles.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return showModalBottomSheet<ContactProfile>(
      context: context,
      backgroundColor: const Color(0xFF101A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona contacto',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: contacts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        tileColor: Colors.white.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0x223B4A63),
                          child: Text(contact.initials),
                        ),
                        title: Text(contact.name),
                        subtitle: Text(
                          contact.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(contact),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      _profileReturnIndex = _birthdaysTabIndex;
      _noteReceipt = null;
      _currentIndex = _profileTabIndex;
    });
  }

  void _backFromProfile() {
    setState(() {
      _currentIndex = _profileReturnIndex;
    });
  }

  void _onNavTap(int index) {
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
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF101A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _AccountSheet(
          user: user,
          onSaveName: (value) {
            return Supabase.instance.client.auth.updateUser(
              UserAttributes(data: {'full_name': value}),
            );
          },
          onSavePassword: (value) {
            return Supabase.instance.client.auth.updateUser(
              UserAttributes(password: value),
            );
          },
          onSignOut: () async {
            SupabaseSyncService.instance.clearSessionCache();
            await Supabase.instance.client.auth.signOut();
          },
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
            birthday: input.birthday,
          ),
        ),
      );
    } on SupabaseSyncException {
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo guardar el contacto. Intenta nuevamente.';
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
        _sparkFeedback = 'No se pudo guardar el contacto. Revisa tu conexion e intenta de nuevo.';
      });
      return;
    }

    unawaited(HapticsService.success());

    final savedRecord = record;

    final profile = _profileFromRemoteContact(savedRecord);
    final birthday = _birthdayFromRemoteContact(savedRecord);

    setState(() {
      _remoteContactsByName[savedRecord.fullName] = savedRecord;
      _profiles[profile.name] = profile;
      _birthdayContacts = [
        birthday,
        ..._birthdayContacts.where((item) => item.name != savedRecord.fullName),
      ];
      _activeProfileName = profile.name;
      _currentIndex = _birthdaysTabIndex;
      _sparkFeedback = 'Contacto guardado: ${profile.name}';
    });

    unawaited(_syncBirthdayNotifications());
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
                  'Acciones del contacto.',
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
                      await _editInterests(profileName);
                    },
                    icon: const Icon(Icons.interests_rounded),
                    label: const Text('Editar intereses'),
                  ),
                ),
                const SizedBox(height: 10),
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

  Future<void> _editInterests(String profileName) async {
    final profile = _profiles[profileName];
    if (profile == null || !mounted) {
      return;
    }

    final labels = profile.interests.map((entry) => entry.label).toList(growable: true);
    final inputController = TextEditingController();

    final updated = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intereses de $profileName',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final label in labels)
                          InputChip(
                            label: Text(label),
                            onDeleted: () {
                              setSheetState(() => labels.remove(label));
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: inputController,
                      decoration: const InputDecoration(
                        hintText: 'Agregar interes manual',
                        prefixIcon: Icon(Icons.add_circle_outline_rounded),
                      ),
                      onSubmitted: (value) {
                        final clean = value.trim();
                        if (clean.isEmpty || labels.contains(clean)) {
                          return;
                        }
                        setSheetState(() {
                          labels.add(clean);
                          inputController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(labels),
                        child: const Text('Guardar intereses'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    inputController.dispose();

    if (!mounted || updated == null) {
      return;
    }

    final mapped = [
      for (final label in updated)
        ProfileInterest(label: label, icon: _interestIconForLabel(label)),
    ];

    final remote = _remoteContactsByName[profileName];
    if (remote != null) {
      unawaited(
        SupabaseSyncService.instance.saveContactInterests(
          contactId: remote.id,
          interestLabels: updated,
        ),
      );
    }

    setState(() {
      _profiles[profileName] = profile.copyWith(interests: mapped);
      _sparkFeedback = 'Intereses actualizados para $profileName.';
    });
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
            birthday: input.birthday,
          ),
        ),
      );
    } on SupabaseSyncException {
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo actualizar el contacto. Intenta nuevamente.';
      });
      return;
    } catch (_) {
      updated = null;
    }

    if (!mounted || updated == null) {
      unawaited(HapticsService.warning());
      setState(() {
        _sparkFeedback = 'No se pudo actualizar el contacto. Verifica los datos e intenta nuevamente.';
      });
      return;
    }

    unawaited(HapticsService.success());

    final updatedRecord = updated;

    final profile = _profileFromRemoteContact(updatedRecord);
    final birthday = _birthdayFromRemoteContact(updatedRecord);

    setState(() {
      _remoteContactsByName.remove(oldName);
      _remoteContactsByName[updatedRecord.fullName] = updatedRecord;

      _profiles.remove(oldName);
      _profiles[profile.name] = profile;

      _birthdayContacts = [
        birthday,
        ..._birthdayContacts.where((item) => item.name != oldName && item.name != updatedRecord.fullName),
      ];

      _activeProfileName = profile.name;
      _sparkFeedback = 'Contacto actualizado: ${profile.name}';
    });

    unawaited(_syncBirthdayNotifications());
  }

  Future<void> _confirmAndDeleteContact(String name) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar contacto?'),
          content: Text('Esto eliminara permanentemente a $name y sus notas.'),
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
    } on SupabaseSyncException {
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo eliminar el contacto. Intenta nuevamente.';
      });
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo eliminar el contacto. Intenta nuevamente.';
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
      _activeProfileName = _profiles.isEmpty ? '' : _profiles.keys.first;
      _currentIndex = _homeTabIndex;
      _sparkFeedback = 'Contacto eliminado: $name';
    });

    unawaited(_syncBirthdayNotifications());
  }

  Future<void> _submitSparkFromHome(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _sparkFeedback = 'Escribe una nota antes de guardar.';
      });
      return;
    }

    if (_profiles.isEmpty) {
      setState(() {
        _sparkFeedback = 'No hay contactos aun. Crea uno desde Contactos con el boton +.';
      });
      return;
    }

    ContactProfile targetProfile;
    if (_hasExplicitMention(trimmed)) {
      targetProfile = _resolveProfileForSpark(trimmed);
    } else {
      final selected = await _pickContactForSpark();
      if (!mounted || selected == null) {
        return;
      }
      targetProfile = selected;
    }

    final parsed = QuickSparkParser.parse(input: trimmed, profile: targetProfile);
    if (parsed == null) {
      unawaited(HapticsService.warning());
      setState(() {
        _sparkFeedback = 'Nota no valida. Escribe una nota (ej: @Juan ...).';
      });
      return;
    }

    unawaited(_saveSparkToSupabase(targetProfile: targetProfile, parsed: parsed));
  }

  void _submitSparkForActiveProfile(String value) {
    final target = _profiles[_activeProfileName] ?? _activeProfile;
    _submitSparkForProfile(value: value, targetProfile: target);
  }

  void _submitSparkForProfile({
    required String value,
    required ContactProfile targetProfile,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _sparkFeedback = 'Escribe una nota antes de guardar.';
      });
      return;
    }

    if (_profiles.isEmpty) {
      setState(() {
        _sparkFeedback = 'No hay contactos aun. Crea uno desde Contactos con el boton +.';
      });
      return;
    }

    final parsed = QuickSparkParser.parse(input: trimmed, profile: targetProfile);
    if (parsed == null) {
      unawaited(HapticsService.warning());
      setState(() {
        _sparkFeedback = 'Nota no valida. Escribe una nota (ej: @Juan ...).';
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
    } on SupabaseSyncException {
      unawaited(HapticsService.warning());
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo guardar la nota. Intenta nuevamente.';
      });
      return;
    } catch (_) {
      unawaited(HapticsService.warning());
      if (!mounted) {
        return;
      }
      setState(() {
        _sparkFeedback = 'No se pudo guardar la nota. Intenta nuevamente.';
      });
      return;
    }

    unawaited(HapticsService.success());

    if (!mounted) {
      return;
    }

    final latestProfile = _profiles[targetProfile.name] ?? targetProfile;
    final updatedInterests = [...latestProfile.interests, ...parsed.inferredInterests];
    final dedupedInterests = <ProfileInterest>[];
    final seenInterests = <String>{};
    for (final interest in updatedInterests) {
      final key = interest.label.trim().toLowerCase();
      if (seenInterests.add(key)) {
        dedupedInterests.add(interest);
      }
    }

    final addedLabels = parsed.inferredInterests.map((entry) => entry.label).toList();

    final persistedProfile = latestProfile.copyWith(
      interests: dedupedInterests.take(10).toList(),
      sparks: [parsed.spark, ...latestProfile.sparks],
    );

    final remote = _remoteContactsByName[targetProfile.name];
    SupabaseContactRecord? maybeBirthdayUpdated;
    if (remote != null && parsed.inferredBirthday != null) {
      try {
        maybeBirthdayUpdated = await SupabaseSyncService.instance.updateContactById(
          contactId: remote.id,
          payload: CreateContactPayload(
            fullName: remote.fullName,
            circleName: remote.circleName,
            circlePriority: remote.circlePriority,
            circleColorHex: remote.circleColorHex,
            birthday: parsed.inferredBirthday,
          ),
        );
      } catch (_) {
        maybeBirthdayUpdated = null;
      }
    }

    if (remote != null) {
      unawaited(
        SupabaseSyncService.instance.saveContactInterests(
          contactId: remote.id,
          interestLabels: [for (final interest in persistedProfile.interests) interest.label],
        ),
      );
    }

    setState(() {
      if (maybeBirthdayUpdated != null) {
        final updatedContact = maybeBirthdayUpdated;
        _remoteContactsByName[targetProfile.name] = updatedContact;
        _birthdayContacts = [
          _birthdayFromRemoteContact(updatedContact),
          ..._birthdayContacts.where((entry) => entry.name != updatedContact.fullName),
        ];
      }
      _profiles[targetProfile.name] = persistedProfile;
      _activeProfileName = targetProfile.name;
        _sparkFeedback = addedLabels.isEmpty
          ? 'Nota guardada para ${targetProfile.name}.'
          : 'Nota guardada para ${targetProfile.name}. Nuevos tags: ${addedLabels.join(', ')}';

      if (parsed.inferredBirthday != null) {
        _sparkFeedback = 'Nota guardada y cumpleanos actualizado para ${targetProfile.name}.';
      }
    });

    if (maybeBirthdayUpdated != null) {
      unawaited(_syncBirthdayNotifications());
    }
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
        onSubmitSpark: (value) {
          unawaited(_submitSparkFromHome(value));
        },
        sparkFeedback: _sparkFeedback,
      ),
      BirthdayStackScreen(
        contacts: _birthdayContacts,
        todayCount: _todayBirthdayContacts.length,
        onBack: () => setState(() => _currentIndex = 0),
        onOpenSearch: _openSearch,
        onSendNote: _sendBirthdayNote,
        onOpenContact: (contact) {
          if (!_profiles.containsKey(contact.name)) {
            return;
          }
          setState(() {
            _activeProfileName = contact.name;
            _profileReturnIndex = _birthdaysTabIndex;
            _currentIndex = _profileTabIndex;
          });
        },
        onAddContact: _onAddContact,
      ),
      ProfileCanvasScreen(
        profile: _activeProfile,
        onSubmitSpark: _submitSparkForActiveProfile,
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
              top: MediaQuery.of(context).padding.top,
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
        bottomNavigationBar: (_noteReceipt != null || _currentIndex == _profileTabIndex)
          ? null
          : Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                12 + MediaQuery.of(context).padding.bottom,
              ),
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

class _AccountSheet extends StatefulWidget {
  const _AccountSheet({
    required this.user,
    required this.onSaveName,
    required this.onSavePassword,
    required this.onSignOut,
  });

  final User user;
  final Future<void> Function(String value) onSaveName;
  final Future<void> Function(String value) onSavePassword;
  final Future<void> Function() onSignOut;

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  String? _feedback;
  bool _isSavingName = false;
  bool _isSavingPassword = false;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: (widget.user.userMetadata?['full_name'] as String?)?.trim() ?? '',
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final value = _nameController.text.trim();
    if (value.isEmpty) {
      setState(() => _feedback = 'Escribe un nombre valido.');
      return;
    }

    setState(() {
      _isSavingName = true;
      _feedback = null;
    });

    try {
      await widget.onSaveName(value);
      if (!mounted) {
        return;
      }
      setState(() => _feedback = 'Nombre actualizado.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _feedback = 'No se pudo actualizar el nombre.');
    } finally {
      if (mounted) {
        setState(() => _isSavingName = false);
      }
    }
  }

  Future<void> _savePassword() async {
    final value = _passwordController.text;
    if (value.length < 6) {
      setState(() => _feedback = 'La clave debe tener al menos 6 caracteres.');
      return;
    }

    setState(() {
      _isSavingPassword = true;
      _feedback = null;
    });

    try {
      await widget.onSavePassword(value);
      if (!mounted) {
        return;
      }
      setState(() {
        _passwordController.clear();
        _feedback = 'Clave actualizada.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _feedback = 'No se pudo actualizar la clave.');
    } finally {
      if (mounted) {
        setState(() => _isSavingPassword = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut) {
      return;
    }

    setState(() => _isSigningOut = true);

    try {
      if (mounted) {
        Navigator.of(context).pop();
      }
      await widget.onSignOut();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _feedback = 'No se pudo cerrar sesion. Intenta nuevamente.';
        _isSigningOut = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi cuenta',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.user.email ?? 'Usuario autenticado',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9AA8C0),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nombre visible',
                  hintText: 'Tu nombre en la app',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _isSavingName ? null : _saveName,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(_isSavingName ? 'Guardando...' : 'Guardar nombre'),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nueva clave',
                  hintText: 'Minimo 6 caracteres',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _isSavingPassword ? null : _savePassword,
                  icon: const Icon(Icons.password_rounded),
                  label: Text(_isSavingPassword ? 'Actualizando...' : 'Actualizar clave'),
                ),
              ),
              if (_feedback != null) ...[
                const SizedBox(height: 12),
                Text(
                  _feedback!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFF4C025),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _isSigningOut ? null : _signOut,
                  child: Text(_isSigningOut ? 'Cerrando sesion...' : 'Cerrar sesion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}