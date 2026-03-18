import 'package:flutter/material.dart';

import '../../core/constants/circle_labels.dart';
import '../../core/utils/date_labels.dart';

class CreateContactInput {
  const CreateContactInput({
    required this.fullName,
    required this.circleName,
    required this.birthday,
  });

  final String fullName;
  final String circleName;
  final DateTime? birthday;
}

class ContactFormInitialData {
  const ContactFormInitialData({
    required this.fullName,
    required this.circleName,
    required this.birthday,
  });

  final String fullName;
  final String circleName;
  final DateTime? birthday;
}

Future<CreateContactInput?> showCreateContactSheet(BuildContext context) {
  return showContactFormSheet(context);
}

Future<CreateContactInput?> showEditContactSheet(
  BuildContext context, {
  required ContactFormInitialData initial,
}) {
  return showContactFormSheet(
    context,
    title: 'Editar contacto',
    subtitle: 'Actualiza este contacto y sincronizalo con tu cuenta.',
    submitLabel: 'Guardar cambios',
    initial: initial,
  );
}

Future<CreateContactInput?> showContactFormSheet(
  BuildContext context, {
  String title = 'Nuevo contacto',
  String subtitle = 'Guarda un contacto y sincronizalo con tu cuenta.',
  String submitLabel = 'Guardar contacto',
  ContactFormInitialData? initial,
}) {
  return showModalBottomSheet<CreateContactInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF101A2A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _CreateContactSheetBody(
      title: title,
      subtitle: subtitle,
      submitLabel: submitLabel,
      initial: initial,
    ),
  );
}

class _CreateContactSheetBody extends StatefulWidget {
  const _CreateContactSheetBody({
    required this.title,
    required this.subtitle,
    required this.submitLabel,
    this.initial,
  });

  final String title;
  final String subtitle;
  final String submitLabel;
  final ContactFormInitialData? initial;

  @override
  State<_CreateContactSheetBody> createState() => _CreateContactSheetBodyState();
}

class _CreateContactSheetBodyState extends State<_CreateContactSheetBody> {
  final _nameController = TextEditingController();

  String _selectedCircle = CircleLabels.acquaintances;
  DateTime? _birthday;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameController.text = initial.fullName;
      _selectedCircle = CircleLabels.normalize(initial.circleName);
      _birthday = initial.birthday;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDay = _safeDay(now.year - 25, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, initialDay),
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year + 1),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() => _birthday = selected);
  }

  void _submit() {
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      setState(() {
        _validationError = 'Escribe un nombre para guardar el contacto.';
      });
      return;
    }

    if (_validationError != null) {
      setState(() => _validationError = null);
    }

    Navigator.of(context).pop(
      CreateContactInput(
        fullName: fullName,
        circleName: _selectedCircle,
        birthday: _birthday,
      ),
    );
  }

  int _safeDay(int year, int month, int preferredDay) {
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextMonthYear = month == 12 ? year + 1 : year;
    final lastDay = DateTime(nextMonthYear, nextMonth, 0).day;
    return preferredDay.clamp(1, lastDay).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + insets),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9AA8C0),
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_validationError != null) {
                  setState(() => _validationError = null);
                }
              },
              decoration: _inputDecoration(
                hint: 'Nombre completo',
                icon: Icons.person_rounded,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCircle,
                  isExpanded: true,
                  menuMaxHeight: 320,
                  dropdownColor: const Color(0xFF132033),
                  iconEnabledColor: const Color(0xFFF4EBD0),
                  style: const TextStyle(color: Color(0xFFF4EBD0), fontWeight: FontWeight.w700),
                  items: CircleLabels.values
                      .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCircle = value);
                    }
                  },
                ),
              ),
            ),
            if (_validationError != null) ...[
              const SizedBox(height: 10),
              Text(
                _validationError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFF4C025),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _birthday == null
                        ? 'Sin cumpleaños'
                      : DateLabels.monthDayYear(_birthday!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFE8DFC5),
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickBirthday,
                  icon: const Icon(Icons.cake_rounded),
                  label: const Text('Elegir fecha'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF4C025),
                  foregroundColor: const Color(0xFF17130A),
                ),
                child: Text(widget.submitLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xAA9AA8C0)),
      prefixIcon: Icon(icon, color: const Color(0xAA9AA8C0)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xFFF4C025)),
      ),
    );
  }
}
