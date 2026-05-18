import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

/// Singleton TTS service — speaks card names in Urdu then English.
/// Falls back to Roman Urdu (en-IN/en-PK engine) when ur-PK voice is unavailable.
/// Works on Android, iOS, and Web (HTML5 Audio for MP3, Web Speech API for TTS).
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  TtsService._internal() {
    _init().then((_) {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    }).catchError((e) {
      debugPrint('TtsService init error: $e');
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    });
  }

  final FlutterTts _tts = FlutterTts();
  final Completer<void> _initCompleter = Completer<void>();
  bool _ready = false;
  bool _urduAvailable = false;
  Map<String, String>? _femaleUrduVoice;

  Future<void> _init() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.1);
    _tts.setErrorHandler((msg) => debugPrint('TtsService error: $msg'));

    // Check ur-PK on ALL platforms — web browsers (Chrome/Firefox/Edge) support
    // ur-PK via the Web Speech API. No kIsWeb guard needed.
    try {
      _urduAvailable = await _tts.isLanguageAvailable('ur-PK') == true;
    } catch (_) {
      _urduAvailable = false;
    }

    if (_urduAvailable && !kIsWeb) {
      // Voice selection only on mobile/desktop — web doesn't expose voice objects.
      try {
        final List<dynamic>? voices = await _tts.getVoices;
        if (voices != null) {
          // Find a female voice. Typically 'ur-pk-x-urc' or 'ura' are female. 'urb' is male.
          for (var v in voices) {
            final name = v['name'].toString().toLowerCase();
            final locale = v['locale'].toString();
            final gender = v['gender']?.toString().toLowerCase();
            if (locale.contains('ur-PK') || locale.contains('ur_PK')) {
              if (gender == 'female' ||
                  name.contains('female') ||
                  name.contains('urc') ||
                  name.contains('ura') ||
                  name.contains('urf')) {
                _femaleUrduVoice = {
                  'name': v['name'].toString(),
                  'locale': v['locale'].toString()
                };
                break;
              }
            }
          }
          // Fallback: take first ur-PK voice that isn't 'urb' (the default male)
          if (_femaleUrduVoice == null) {
            for (var v in voices) {
              final name = v['name'].toString().toLowerCase();
              final locale = v['locale'].toString();
              if ((locale.contains('ur-PK') || locale.contains('ur_PK')) &&
                  !name.contains('urb')) {
                _femaleUrduVoice = {
                  'name': v['name'].toString(),
                  'locale': v['locale'].toString()
                };
                break;
              }
            }
          }
        }
      } catch (_) {}
    }

    if (!_urduAvailable) {
      debugPrint('TtsService: ur-PK not available; will use Roman Urdu via en-IN/en-PK/en-US');
    }

    _ready = true;
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    await _initCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }

  Future<void> _setUrduProfile() async {
    await _tts.setLanguage('ur-PK');
    if (_femaleUrduVoice != null) {
      await _tts.setVoice(_femaleUrduVoice!);
    }
    await _tts.setPitch(1.1);
    await _tts.setSpeechRate(0.40); // Slower for clarity with children
  }

  Future<void> _setEnglishProfile() async {
    // Pakistani / South Asian accent preference: en-PK → en-IN → en-US
    final hasEnPk = await _tts.isLanguageAvailable('en-PK') == true;
    final hasEnIn = await _tts.isLanguageAvailable('en-IN') == true;

    if (hasEnPk) {
      await _tts.setLanguage('en-PK');
    } else if (hasEnIn) {
      await _tts.setLanguage('en-IN');
    } else {
      await _tts.setLanguage('en-US');
    }

    await _tts.setPitch(1.1);
    await _tts.setSpeechRate(0.45);
  }

  /// Speak the card name: Urdu first, then English.
  /// Works on Android, iOS, and Web — no kIsWeb early return needed.
  Future<void> speakCard(
    String nameUrdu,
    String nameEnglish, {
    String? nameRomanUrdu,
  }) async {
    await _ensureReady();
    if (!_ready) return;

    try {
      await _tts.stop();

      if (_urduAvailable) {
        await _setUrduProfile();
        await _tts.speak(nameUrdu);
        await _awaitCompletion();
        await Future.delayed(const Duration(milliseconds: 400));
      } else if (nameRomanUrdu != null && nameRomanUrdu.isNotEmpty) {
        // Roman Urdu via South Asian English voice
        await _setEnglishProfile();
        await _tts.speak(nameRomanUrdu);
        await _awaitCompletion();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      await _setEnglishProfile();
      await _tts.speak(nameEnglish);
    } catch (e) {
      debugPrint('TtsService.speakCard error: $e');
    }
  }

  /// Speak arbitrary text. For agent praise phrases (language: 'ur-PK').
  Future<void> speak(String text, {String language = 'en-US'}) async {
    await _ensureReady();
    if (!_ready) return;

    try {
      await _tts.stop();

      if (language == 'ur-PK' && _urduAvailable) {
        await _setUrduProfile();
      } else {
        // Try the requested language; fall back gracefully
        try {
          final langOk =
              language == 'en-US' || await _tts.isLanguageAvailable(language) == true;
          await _tts.setLanguage(langOk ? language : 'en-US');
        } catch (_) {
          await _tts.setLanguage('en-US');
        }
        await _tts.setPitch(1.1);
        await _tts.setSpeechRate(0.45);
      }

      await _tts.speak(text);
    } catch (e) {
      debugPrint('TtsService.speak error: $e');
    }
  }

  // Keep a single AudioPlayer instance — never dispose() a singleton player.
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Play a pre-recorded female Pakistani-accented praise MP3.
  /// audioplayers uses HTML5 Audio on web — no kIsWeb guard needed.
  Future<void> speakPraise(dynamic phrase) async {
    try {
      await _tts.stop();
      await _audioPlayer.stop();

      await _audioPlayer.play(AssetSource(phrase.audioAsset));
      await _audioPlayer.onPlayerComplete.first;
    } catch (e) {
      debugPrint('TtsService.speakPraise error: $e');
      // Fallback: live TTS in best available voice
      try {
        if (_urduAvailable) {
          await _setUrduProfile();
          await _tts.speak(phrase.urdu);
        } else {
          await _setEnglishProfile();
          await _tts.speak(phrase.romanUrdu);
        }
      } catch (_) {}
    }
  }

  /// Stop all audio immediately (called on screen dispose).
  /// Uses stop() only — never dispose() so singleton survives across sessions.
  Future<void> stop() async {
    try {
      await _tts.stop();
      await _audioPlayer.stop();
    } catch (_) {}
  }

  Future<void> _awaitCompletion() async {
    final c = _SimpleCompleter();
    _tts.setCompletionHandler(c.complete);
    _tts.setErrorHandler((_) => c.complete());
    await c.future.timeout(const Duration(seconds: 4), onTimeout: () {});
    _tts.setErrorHandler((msg) => debugPrint('TtsService error: $msg'));
  }
}

class _SimpleCompleter {
  final Completer<void> _c = Completer<void>();
  Future<void> get future => _c.future;
  void complete() {
    if (!_c.isCompleted) _c.complete();
  }
}
