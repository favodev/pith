import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';

class NoteSuccessScreen extends StatefulWidget {
  const NoteSuccessScreen({
    super.key,
    required this.receipt,
    required this.onClose,
    required this.onReturnToDashboard,
    required this.onViewDetails,
  });

  final NoteDeliveryReceipt receipt;
  final VoidCallback onClose;
  final VoidCallback onReturnToDashboard;
  final VoidCallback onViewDetails;

  @override
  State<NoteSuccessScreen> createState() => _NoteSuccessScreenState();
}

class _NoteSuccessScreenState extends State<NoteSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 860),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF00A0C12),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final curve = Curves.easeOutCubic.transform(_controller.value);

            return Stack(
              children: [
                const Positioned.fill(child: _SuccessConfetti()),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFF4C025),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'P',
                              style: TextStyle(
                                color: Color(0xFF181103),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'PITH',
                            style: TextStyle(
                              color: Color(0xFFF4EBD0),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              foregroundColor: const Color(0xFFF4C025),
                              backgroundColor: const Color(0x1AF4C025),
                              minimumSize: const Size(48, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 360),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.scale(
                                scale: 0.82 + (0.18 * curve),
                                child: Opacity(
                                  opacity: curve,
                                  child: _SuccessCore(accent: widget.receipt.accent),
                                ),
                              ),
                              const SizedBox(height: 34),
                              Opacity(
                                opacity: curve,
                                child: const Column(
                                  children: [
                                    Text(
                                        'Nota guardada',
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 34,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Tu nota fue guardada en tu memoria privada de relacion.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xB39AA8C0),
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 38),
                              Opacity(
                                opacity: curve,
                                child: _RecipientCard(receipt: widget.receipt),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: widget.onReturnToDashboard,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF4C025),
                                foregroundColor: const Color(0xFF171104),
                                minimumSize: const Size.fromHeight(64),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text(
                                'Volver al inicio',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: widget.onViewDetails,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFB8C0D4),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                                minimumSize: const Size.fromHeight(64),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text(
                                'Ver detalles',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SuccessCore extends StatelessWidget {
  const _SuccessCore({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.22), width: 2),
            ),
          ),
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.08), width: 2),
            ),
          ),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.24),
                  blurRadius: 34,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, size: 62, color: Color(0xFF181103)),
          ),
        ],
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.receipt});

  final NoteDeliveryReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: receipt.accent.withValues(alpha: 0.86),
            ),
            alignment: Alignment.center,
            child: Text(
              receipt.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.recipientLabel,
                  style: const TextStyle(
                    color: Color(0x99C7D2E0),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  receipt.recipientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF2EEE3),
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0x1EF4C025),
              border: Border.all(color: const Color(0x33F4C025)),
            ),
            child: Text(
              receipt.statusLabel,
              style: const TextStyle(
                color: Color(0xFFF4C025),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessConfetti extends StatelessWidget {
  const _SuccessConfetti();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _AccentDot(top: 0.24, left: 0.22, color: Color(0xFFF4C025), size: 6),
        _AccentDot(top: 0.31, left: 0.74, color: Color(0x66F4C025), size: 6),
        _AccentDot(top: 0.67, left: 0.28, color: Color(0x66AAB4C5), size: 5),
        _AccentLine(top: 0.43, left: 0.79, angle: 0.8, color: Color(0xFFF4C025)),
        _AccentLine(top: 0.78, left: 0.16, angle: 0.14, color: Color(0x99D4A827)),
        _AccentLine(top: 0.47, left: 0.12, angle: -0.7, color: Color(0x66AAB4C5)),
      ],
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.top,
    required this.left,
    required this.color,
    required this.size,
  });

  final double top;
  final double left;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment(left * 2 - 1, top * 2 - 1),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _AccentLine extends StatelessWidget {
  const _AccentLine({
    required this.top,
    required this.left,
    required this.angle,
    required this.color,
  });

  final double top;
  final double left;
  final double angle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment(left * 2 - 1, top * 2 - 1),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 1.5,
          height: 16,
          color: color,
        ),
      ),
    );
  }
}