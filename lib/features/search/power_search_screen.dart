import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';

class PowerSearchScreen extends StatefulWidget {
  const PowerSearchScreen({
    super.key,
    required this.initialQuery,
    required this.results,
    required this.onClose,
    required this.onSelectResult,
  });

  final String initialQuery;
  final List<SearchContact> results;
  final VoidCallback onClose;
  final ValueChanged<SearchContact> onSelectResult;

  @override
  State<PowerSearchScreen> createState() => _PowerSearchScreenState();
}

class _PowerSearchScreenState extends State<PowerSearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final lowered = query.toLowerCase();
    final filtered = widget.results.where((result) {
      if (lowered.isEmpty) {
        return true;
      }
      return result.name.toLowerCase().contains(lowered) ||
          result.description.toLowerCase().contains(lowered);
    }).toList();

    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: const Color(0xE609111F),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFFF4EBD0),
                      ),
                      Expanded(
                        child: Text(
                          'Busqueda avanzada',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: null,
                        icon: const Icon(Icons.more_horiz_rounded),
                        disabledColor: const Color(0x66F4EBD0),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: Container(
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 18),
                        const Icon(Icons.search_rounded, color: Color(0xFFF4C025), size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              color: Color(0xFFF4EBD0),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              fillColor: Colors.transparent,
                              filled: false,
                              hintText: 'Busca lo que sea...',
                              hintStyle: TextStyle(color: Color(0xAA9AA8C0)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _controller.clear();
                            setState(() {});
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            child: const Icon(Icons.close_rounded, color: Color(0xFF9AA8C0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SearchChip(
                          label: 'Cerca: San Carlos',
                          icon: Icons.location_on_rounded,
                          selected: true,
                          trailing: Icons.expand_more_rounded,
                        ),
                        _SearchChip(
                          label: 'Contactos',
                          icon: Icons.group_rounded,
                          trailing: Icons.expand_more_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _SearchChip(
                      label: 'Recientes',
                      icon: Icons.history_rounded,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'CONTACTOS INTERESADOS EN "${query.isEmpty ? 'RAP' : query.toUpperCase()}"',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF8392AD),
                        letterSpacing: 3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      if (filtered.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 18),
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No hay coincidencias',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Prueba otra palabra clave o agrega mas contactos para mejorar los resultados.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF9AA8C0),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        for (final result in filtered)
                          _SearchResultRow(
                            contact: result,
                            onTap: () => widget.onSelectResult(result),
                          ),
                      const SizedBox(height: 24),
                      const _SearchMapCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  const _SearchChip({
    required this.label,
    required this.icon,
    this.trailing,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final IconData? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFF4C025)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x33F4C025),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: selected ? const Color(0xFF111111) : const Color(0xFF9AA8C0),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF111111) : const Color(0xFF9AA8C0),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Icon(
              trailing,
              size: 20,
              color: selected ? const Color(0xFF111111) : const Color(0xAA9AA8C0),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({required this.contact, this.onTap});

  final SearchContact contact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
                  ),
                  child: Text(
                    contact.initials,
                    style: const TextStyle(
                      color: Color(0xFFF4EBD0),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: contact.statusColor,
                      border: Border.all(color: const Color(0xFF09111F), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF9AA8C0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.auto_awesome_rounded,
              color: contact.highlighted
                  ? const Color(0xFFF4C025)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchMapCard extends StatelessWidget {
  const _SearchMapCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            color: const Color(0x22182435),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _MapPainter()),
              ),
              const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFF4C025),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x44F4C025),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: SizedBox(width: 16, height: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'BUSQUEDA ACTIVA EN SAN CARLOS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF8392AD),
            letterSpacing: 3,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final pathA = Path()
      ..moveTo(size.width * 0.05, size.height * 0.25)
      ..lineTo(size.width * 0.45, size.height * 0.30)
      ..lineTo(size.width * 0.9, size.height * 0.10);
    final pathB = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..lineTo(size.width * 0.35, size.height * 0.5)
      ..lineTo(size.width * 0.75, size.height * 0.58)
      ..lineTo(size.width * 0.95, size.height * 0.85);
    final pathC = Path()
      ..moveTo(size.width * 0.55, 0)
      ..lineTo(size.width * 0.52, size.height)
      ..moveTo(size.width * 0.25, 0)
      ..lineTo(size.width * 0.3, size.height);

    canvas.drawPath(pathA, linePaint);
    canvas.drawPath(pathB, linePaint);
    canvas.drawPath(pathC, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}