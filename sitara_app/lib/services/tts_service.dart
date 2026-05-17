import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Singleton TTS service — speaks card names in Urdu then English.
/// Falls back to Roman Urdu (English engine) when ur-PK voice is not installed.
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

    if (!kIsWeb) {
      _urduAvailable = await _tts.isLanguageAvailable('ur-PK') == true;
      if (_urduAvailable) {
        try {
          final List<dynamic>? voices = await _tts.getVoices;
          if (voices != null) {
            // Find a female voice. Typically 'ur-pk-x-urc' or 'ura' are female. 'urb' is male.
            for (var v in voices) {
              final name = v['name'].toString().toLowerCase();
              final locale = v['locale'].toString();
              if (locale.contains('ur-PK') || locale.contains('ur_PK')) {
                if (name.contains('female') || name.contains('urc') || name.contains('ura') || name.contains('urf')) {
                  _femaleUrduVoice = {'name': v['name'].toString(), 'locale': v['locale'].toString()};
                  break;
                }
              }
            }
            // Fallback: take first ur-PK voice that isn't 'urb' (the default male)
            if (_femaleUrduVoice == null) {
              for (var v in voices) {
                final name = v['name'].toString().toLowerCase();
                final locale = v['locale'].toString();
                if ((locale.contains('ur-PK') || locale.contains('ur_PK')) && !name.contains('urb')) {
                  _femaleUrduVoice = {'name': v['name'].toString(), 'locale': v['locale'].toString()};
                  break;
                }
              }
            }
          }
        } catch (_) {}
      } else {
        debugPrint('TtsService: ur-PK not installed; will use Roman Urdu via en-US');
      }
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
    // Boost pitch slightly for a softer/more feminine tone if we missed the female voice
    await _tts.setPitch(_femaleUrduVoice != null ? 1.1 : 1.3);
    await _tts.setSpeechRate(0.40); // Slower for clarity
  }

  Future<void> _setEnglishProfile() async {
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.1);
    await _tts.setSpeechRate(0.45);
  }

  Future<void> speakCard(
    String nameUrdu,
    String nameEnglish, {
    String? nameRomanUrdu,
  }) async {
    await _ensureReady();
    if (!_ready) return;

    try {
      if (kIsWeb) {
        await _setEnglishProfile();
        await _tts.speak(nameEnglish);
        return;
      }

      await _tts.stop();

      if (_urduAvailable) {
        await _setUrduProfile();
        await _tts.speak(nameUrdu);
        await _awaitCompletion();
        await Future.delayed(const Duration(milliseconds: 400));
      } else if (nameRomanUrdu != null && nameRomanUrdu.isNotEmpty) {
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

  Future<void> speak(String text, {String language = 'en-US'}) async {
    await _ensureReady();
    if (!_ready) return;

    try {
      if (kIsWeb) {
        await _setEnglishProfile();
        await _tts.speak(text);
        return;
      }

      await _tts.stop();

      if (language == 'ur-PK' && _urduAvailable) {
        await _setUrduProfile();
      } else {
        final langOk = language == 'en-US' || await _tts.isLanguageAvailable(language) == true;
        await _tts.setLanguage(langOk ? language : 'en-US');
        await _tts.setPitch(1.1);
        await _tts.setSpeechRate(0.45);
      }
      
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TtsService.speak error: $e');
    }
  }

  Future<void> speakPraise(String urduText, String romanUrduFallback) async {
    await _ensureReady();
    if (!_ready) return;

    try {
      if (kIsWeb) {
        await _setEnglishProfile();
        await _tts.speak(romanUrduFallback);
        return;
      }

      await _tts.stop();

      if (_urduAvailable) {
        await _setUrduProfile();
        await _tts.speak(urduText);
      } else {
        await _setEnglishProfile();
        await _tts.speak(romanUrduFallback);
      }
    } catch (e) {
      debugPrint('TtsService.speakPraise error: $e');
      try {
        await _setEnglishProfile();
        await _tts.speak(romanUrduFallback);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
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
