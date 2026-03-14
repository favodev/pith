import 'package:flutter/material.dart';

class CreateContactInput {
  const CreateContactInput({
    required this.fullName,
    required this.circleName,
    required this.locationName,
    required this.birthday,
  });

  final String fullName;
  final String circleName;
  final String locationName;
  final DateTime? birthday;
}

Future<CreateContactInput?> showCreateContactSheet(BuildContext context) {
  return showModalBottomSheet<CreateContactInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF101A2A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _CreateContactSheetBody(),
  );
}

class _CreateContactSheetBody extends StatefulWidget {
  const _CreateContactSheetBody();

  @override
  State<_CreateContactSheetBody> createState() => _CreateContactSheetBodyState();
}

class _CreateContactSheetBodyState extends State<_CreateContactSheetBody> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCircle = 'VIP';
  DateTime? _birthday;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
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
      return;
    }

    Navigator.of(context).pop(
      CreateContactInput(
        fullName: fullName,
        circleName: _selectedCircle,
        locationName: _locationController.text.trim(),
        birthday: _birthday,
      ),
    );
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
              'Nuevo contacto',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Guarda un contacto y sincronizalo con tu cuenta.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9AA8C0),
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                hint: 'Nombre completo',
                icon: Icons.person_rounded,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _locationController,
              textInputAction: TextInputAction.done,
              decoration: _inputDecoration(
                hint: 'Ciudad o ubicacion',
                icon: Icons.location_on_rounded,
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
                  dropdownColor: const Color(0xFF132033),
                  iconEnabledColor: const Color(0xFFF4EBD0),
                  style: const TextStyle(color: Color(0xFFF4EBD0), fontWeight: FontWeight.w700),
                  items: const [
                    DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                    DropdownMenuItem(value: 'Family', child: Text('Family')),
                    DropdownMenuItem(value: 'Inner Circle', child: Text('Inner Circle')),
                    DropdownMenuItem(value: 'All Contacts', child: Text('All Contacts')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCircle = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _birthday == null
                        ? 'Sin cumpleanos'
                        : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
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
                child: const Text('Guardar contacto'),
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
