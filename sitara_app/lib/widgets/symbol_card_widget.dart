import 'package:flutter/material.dart';
import '../models/symbol_card.dart';
import '../services/tts_service.dart';

/// SymbolCardWidget — emoji-primary AAC card.
///
/// Shows a large emoji as the guaranteed-correct visual (no CDN dependency,
/// no wrong-category images, works offline). Category colour-coding provides
/// instant visual context for children and therapists.
class SymbolCardWidget extends StatefulWidget {
  final SymbolCard card;
  final VoidCallback onTap;

  /// When false the widget skips its own TTS (game_screen handles it instead).
  final bool speakOnTap;

  /// Triggers bounce animation + green flash.
  final bool showCorrect;

  /// Triggers shake animation + red flash.
  final bool showIncorrect;

  const SymbolCardWidget({
    super.key,
    required this.card,
    required this.onTap,
    this.speakOnTap = true,
    this.showCorrect = false,
    this.showIncorrect = false,
  });

  @override
  State<SymbolCardWidget> createState() => _SymbolCardWidgetState();
}

class _SymbolCardWidgetState extends State<SymbolCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  Color? _flashColor;
  bool _isPressed = false;

  // ── Category palette ────────────────────────────────────────────────────────
  static const Map<String, _CategoryStyle> _styles = {
    'animals':        _CategoryStyle(Color(0xFF2EB87E), Color(0xFFE8FBF4), '🌿', 'Animals'),
    'food':           _CategoryStyle(Color(0xFFE8930A), Color(0xFFFFF8EC), '🍽️', 'Food'),
    'family':         _CategoryStyle(Color(0xFFE0457B), Color(0xFFFFEDF4), '❤️', 'Family'),
    'emotions':       _CategoryStyle(Color(0xFF6C63FF), Color(0xFFF0EFFE), '💜', 'Emotions'),
    'daily_routines': _CategoryStyle(Color(0xFF0097B2), Color(0xFFE5F8FB), '⭐', 'Routines'),
    'transport':      _CategoryStyle(Color(0xFFF07020), Color(0xFFFFF2EA), '🚦', 'Transport'),
  };

  _CategoryStyle get _style =>
      _styles[widget.card.category] ??
      const _CategoryStyle(Color(0xFF6C63FF), Color(0xFFF0EFFE), '✨', '');

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scaleAnim = Tween(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _bounceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.95), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0),  weight: 35),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: -9.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -9.0, end:  9.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin:  9.0, end: -5.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -5.0, end:  0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(SymbolCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showCorrect && !oldWidget.showCorrect) {
      setState(() => _flashColor = const Color(0xFF00C853));
      _bounceController.forward(from: 0);
    }
    if (widget.showIncorrect && !oldWidget.showIncorrect) {
      setState(() => _flashColor = const Color(0xFFFF1744));
      _shakeController.forward(from: 0);
    }
    if (!widget.showCorrect && !widget.showIncorrect) {
      setState(() => _flashColor = null);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final accent = _style.accent;
    final bg     = _style.bg;

    final borderColor = _flashColor ??
        (_isPressed ? accent : accent.withValues(alpha: 0.35));
    final borderWidth = (_flashColor != null || _isPressed) ? 3.0 : 1.8;

    return Semantics(
      label: '${widget.card.nameEnglish}, ${widget.card.nameRomanUrdu}',
      button: true,
      child: GestureDetector(
        onTapDown: (_) {
          _scaleController.forward();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          _scaleController.reverse();
          setState(() => _isPressed = false);
          if (widget.speakOnTap) {
            TtsService().speakCard(
              widget.card.nameUrdu,
              widget.card.nameEnglish,
              nameRomanUrdu: widget.card.nameRomanUrdu,
              audioPath: widget.card.audioPath,
            );
          }
          widget.onTap();
        },
        onTapCancel: () {
          _scaleController.reverse();
          setState(() => _isPressed = false);
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnim, _bounceAnim, _shakeAnim]),
          builder: (ctx, child) => Transform.translate(
            offset: Offset(_shakeAnim.value, 0),
            child: Transform.scale(
              scale: _scaleAnim.value * _bounceAnim.value,
              child: child,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            decoration: BoxDecoration(
              color: _flashColor != null
                  ? _flashColor!.withValues(alpha: 0.12)
                  : bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: (_flashColor ?? accent)
                      .withValues(alpha: _isPressed ? 0.30 : 0.14),
                  blurRadius: _isPressed ? 18 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, cardConstraints) {
                final cardWidth = cardConstraints.maxWidth;
                return Column(
                  children: [
                    // ── CATEGORY PILL ──────────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        cardWidth * 0.05,
                        cardWidth * 0.05,
                        cardWidth * 0.05,
                        0,
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: cardWidth * 0.05,
                            vertical: cardWidth * 0.015,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _style.label,
                            style: TextStyle(
                              fontSize: (cardWidth * 0.07).clamp(8.0, 11.0),
                              fontWeight: FontWeight.w700,
                              color: accent,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── PICTOGRAM VISUAL WITH EMOJI FALLBACK ────────────────────────
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            final size = (constraints.maxHeight * 0.86).clamp(0.0, cardWidth * 0.82);
                            return Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(size * 0.03),
                                  child: widget.card.imagePath.startsWith('assets/')
                                      ? Image.asset(
                                          widget.card.imagePath,
                                          fit: BoxFit.contain,
                                          errorBuilder: (ctx, e, s) => Center(
                                            child: Text(
                                              widget.card.emoji,
                                              style: TextStyle(fontSize: size * 0.76),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )
                                      : Image.network(
                                          widget.card.imagePath,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (ctx, child, progress) {
                                            if (progress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: progress.expectedTotalBytes != null
                                                    ? progress.cumulativeBytesLoaded /
                                                        progress.expectedTotalBytes!
                                                    : null,
                                                color: accent,
                                                strokeWidth: 2,
                                              ),
                                            );
                                          },
                                          errorBuilder: (ctx, e, s) => Center(
                                            child: Text(
                                              widget.card.emoji,
                                              style: TextStyle(fontSize: size * 0.76),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: cardWidth * 0.02),

                    // ── LABEL BAR ─────────────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: cardWidth * 0.04,
                        vertical: cardWidth * 0.04,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: const BorderRadius.only(
                          bottomLeft:  Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Urdu — Noto Nastaliq for correct script rendering
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.card.nameUrdu,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'NotoNastaliqUrdu', 
                                fontSize: (cardWidth * 0.12).clamp(11.0, 18.0),
                                fontWeight: FontWeight.w700,
                                color: accent,
                                height: 1.3,
                              ),
                            ),
                          ),
                          SizedBox(height: cardWidth * 0.01),
                          // English — small, muted
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.card.nameEnglish,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: (cardWidth * 0.08).clamp(8.0, 13.0),
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper ─────────────────────────────────────────────────────────────────────
class _CategoryStyle {
  final Color  accent;
  final Color  bg;
  final String icon;   // unused but kept for future category header use
  final String label;

  const _CategoryStyle(this.accent, this.bg, this.icon, this.label);
}
