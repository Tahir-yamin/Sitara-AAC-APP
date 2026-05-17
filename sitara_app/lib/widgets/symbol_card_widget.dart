import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/symbol_card.dart';
import '../services/tts_service.dart';

/// SymbolCardWidget
/// Displays a professional ARASAAC pictogram (CC BY-NC-SA) loaded from CDN.
/// Falls back to a large emoji if the network image fails (offline mode).
class SymbolCardWidget extends StatefulWidget {
  final SymbolCard card;
  final VoidCallback onTap;
  /// When false, the widget skips its own TTS (e.g. game_screen handles it).
  final bool speakOnTap;
  /// Triggers bounce animation + green flash when set to true.
  final bool showCorrect;
  /// Triggers shake animation + red flash when set to true.
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

  // Per-category accent colours
  static const Map<String, Color> _categoryColors = {
    'animals':        Color(0xFF43C59E), // teal-green
    'food':           Color(0xFFFFB800), // warm amber
    'family':         Color(0xFFFF6584), // rose-pink
    'emotions':       Color(0xFF6C63FF), // indigo
    'daily_routines': Color(0xFF00BCD4), // cyan
    'transport':      Color(0xFFFF9800), // orange
  };

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _bounceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(SymbolCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showCorrect && !oldWidget.showCorrect) {
      setState(() => _flashColor = Colors.greenAccent);
      _bounceController.forward(from: 0);
    }
    if (widget.showIncorrect && !oldWidget.showIncorrect) {
      setState(() => _flashColor = Colors.redAccent);
      _shakeController.forward(from: 0);
    }
    if (!widget.showCorrect && !widget.showIncorrect) {
      setState(() => _flashColor = null);
    }
  }

  Color get _accent =>
      _categoryColors[widget.card.category] ?? const Color(0xFF6C63FF);

  bool get _isNetworkImage =>
      widget.card.imagePath.startsWith('http');

  Widget _emojiFallback() => LayoutBuilder(
    builder: (ctx, constraints) => Center(
      child: Text(
        widget.card.emoji,
        style: TextStyle(fontSize: constraints.maxHeight * 0.65),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.card.nameEnglish}, ${widget.card.nameRomanUrdu}',
      button: true,
      enabled: true,
      child: GestureDetector(
        onTapDown: (_) {
          _scaleController.forward();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          _scaleController.reverse();
          setState(() => _isPressed = false);
          // 🔊 Speak card name (unless caller suppresses it for its own TTS flow)
          if (widget.speakOnTap) {
            TtsService().speakCard(widget.card.nameUrdu, widget.card.nameEnglish);
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
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: _flashColor?.withValues(alpha: 0.15) ?? Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _flashColor ?? (_isPressed ? _accent : _accent.withValues(alpha: 0.28)),
                width: (_flashColor != null || _isPressed) ? 3.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_flashColor ?? _accent).withValues(alpha: _isPressed ? 0.28 : 0.12),
                  blurRadius: _isPressed ? 20 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── PICTOGRAM ──────────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                    child: _isNetworkImage
                        ? Image.network(
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
                                  color: _accent,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (ctx, e, s) => _emojiFallback(),
                          )
                        : Image.asset(
                            widget.card.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, e, s) => _emojiFallback(),
                          ),
                  ),
                ),

                // ── LABEL BAR ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.10),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Urdu — large, RTL, Noto Nastaliq Urdu for correct script rendering
                      Text(
                        widget.card.nameUrdu,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.notoNastaliqUrdu(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _accent,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1),
                      // English — small, grey
                      Text(
                        widget.card.nameEnglish,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
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

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
}
