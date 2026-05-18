import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'local_db_service.dart';

/// Singleton TTS service — speaks card names in Urdu then English.
///
/// Strategy (in priority order):
///   1. Pre-recorded female Urdu MP3 via [audioPath] (audioplayers → HTML5 Audio on web)
///   2. Live ur-PK synthesis via Web Speech API / flutter_tts if voice is available
///   3. Roman Urdu fallback via South Asian English voice
///   4. English name as final fallback
///
/// Works on Android, iOS, and Web with natural female Pakistani voice.
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Completer<void> _initCompleter = Completer<void>();

  bool _ready = false;
  bool _urduAvailable = false;
  Map<String, String>? _femaleUrduVoice;
  Map<String, String>? _femaleFallbackVoice;

  // Pre-recorded audio files with incorrect accents or poor energy to be bypassed
  static const Set<String> _badAudioAssets = {
    'assets/audio/behan.mp3',
    'assets/audio/dara.mp3',
    'assets/audio/doodh.mp3',
    'assets/audio/kashti.mp3',
    'assets/audio/mehnat.mp3',
    'assets/audio/nahana.mp3',
    'assets/audio/titli.mp3',
    'assets/audio/bohat_acha.mp3',
    'assets/audio/shabash.mp3',
    'assets/audio/praise_0.mp3',
    'assets/audio/praise_2.mp3',
    'audio/behan.mp3',
    'audio/dara.mp3',
    'audio/doodh.mp3',
    'audio/kashti.mp3',
    'audio/mehnat.mp3',
    'audio/nahana.mp3',
    'audio/titli.mp3',
    'audio/bohat_acha.mp3',
    'audio/shabash.mp3',
    'audio/praise_0.mp3',
    'audio/praise_2.mp3',
  };

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

    // Voice selection only on mobile/desktop — web doesn't expose voice objects.
    if (!kIsWeb) {
      try {
        final List<dynamic>? voices = await _tts.getVoices;
        if (voices != null) {
          // 1. Find a female Urdu voice. Typically 'ur-pk-x-urc' or 'ura' are female.
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
          // Fallback Urdu: take first ur-PK voice that isn't 'urb' (the default male)
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

          // 2. Find any English female voice to serve as English/Roman Urdu female fallback
          for (var v in voices) {
            final name = v['name'].toString().toLowerCase();
            final locale = v['locale'].toString();
            final gender = v['gender']?.toString().toLowerCase();
            if (locale.startsWith('en') || name.contains('zira') || name.contains('hazel') || name.contains('jessa') || name.contains('female')) {
              if (gender == 'female' ||
                  name.contains('female') ||
                  name.contains('zira') ||
                  name.contains('hazel') ||
                  name.contains('jessa') ||
                  name.contains('kalpana') ||
                  name.contains('heera') ||
                  name.contains('ananya') ||
                  name.contains('jessica') ||
                  name.contains('samantha')) {
                _femaleFallbackVoice = {
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
      debugPrint(
          'TtsService: ur-PK not available — using pre-recorded audio assets or English/Roman Urdu female fallback.');
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
    await _tts.setSpeechRate(0.40);
  }

  Future<void> _setEnglishProfile() async {
    // If a clear female fallback voice (like Microsoft Zira) is found, prioritize it to ensure female TTS
    if (_femaleFallbackVoice != null) {
      await _tts.setLanguage(_femaleFallbackVoice!['locale']!);
      await _tts.setVoice(_femaleFallbackVoice!);
    } else {
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
    }

    await _tts.setPitch(1.1);
    await _tts.setSpeechRate(0.45);
  }

  /// Speak the card name using pre-recorded Urdu audio first, then English TTS.
  ///
  /// [audioPath] — asset path to the pre-recorded Urdu word MP3
  ///   (e.g. 'assets/audio/billi.mp3'). When provided and the file loads
  ///   successfully, the female Google-generated Urdu voice plays directly.
  ///
  /// Falls back to Web Speech API ur-PK or Roman Urdu if audio is unavailable.
  Future<void> speakCard(
    String nameUrdu,
    String nameEnglish, {
    String? nameRomanUrdu,
    String? audioPath,
  }) async {
    await _ensureReady();
    if (!_ready) return;

    final mode = LocalDbService.instance.getTtsLanguageMode();

    try {
      await _tts.stop();
      await _audioPlayer.stop();

      // If english mode, skip Urdu completely and only speak English
      if (mode == 'english') {
        await _setEnglishProfile();
        await _tts.speak(nameEnglish);
        return;
      }

      // If we get here, it's either bilingual or urdu-only.
      bool playedAudio = false;

      // ── 1. Pre-recorded female Urdu MP3 (best quality) ──
      // Bypass if the pre-recorded audio asset has incorrect pronunciation/accent
      if (audioPath != null && audioPath.isNotEmpty && !_badAudioAssets.contains(audioPath)) {
        try {
          // Strip 'assets/' prefix — AssetSource adds it automatically.
          final assetKey = audioPath.startsWith('assets/')
              ? audioPath.substring('assets/'.length)
              : audioPath;
          await _audioPlayer.play(AssetSource(assetKey));
          await _audioPlayer.onPlayerComplete.first
              .timeout(const Duration(seconds: 6));
          playedAudio = true;
        } catch (e) {
          debugPrint('TtsService: audio asset failed ($audioPath): $e');
        }
      }

      if (!playedAudio) {
        // ── 2. Live ur-PK synthesis (mobile / browser with Urdu voice) ─────────
        if (_urduAvailable) {
          await _setUrduProfile();
          await _tts.speak(nameUrdu);
          await _awaitCompletion();
          await Future.delayed(const Duration(milliseconds: 400));
        } else if (nameRomanUrdu != null && nameRomanUrdu.isNotEmpty) {
          // ── 3. Roman Urdu via South Asian English voice ──────────────────────
          await _setEnglishProfile();
          await _tts.speak(nameRomanUrdu);
          await _awaitCompletion();
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      // ── 4. English name (only spoken after Urdu if mode is bilingual) ──────────────────────────
      if (mode == 'bilingual') {
        await Future.delayed(const Duration(milliseconds: 300));
        await _setEnglishProfile();
        await _tts.speak(nameEnglish);
      }
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

  /// Play a pre-recorded female Pakistani-accented praise MP3.
  /// audioplayers uses HTML5 Audio on web — works without any special config.
  Future<void> speakPraise(dynamic phrase) async {
    try {
      await _tts.stop();
      await _audioPlayer.stop();

      // If this is one of the poorly pronounced pre-recordings, bypass it and use dynamic female live TTS!
      if (_badAudioAssets.contains(phrase.audioAsset) || phrase.audioAsset == 'audio/mehnat.mp3') {
        throw Exception("Bypass bad praise audio for short, excited live TTS");
      }

      await _audioPlayer.play(AssetSource(phrase.audioAsset));
      await _audioPlayer.onPlayerComplete.first;
    } catch (e) {
      debugPrint('TtsService.speakPraise error: $e');
      // Fallback: live TTS — must be FEMALE and energetic.
      //
      // Strategy: only use ur-PK TTS when we confirmed a female Urdu voice
      // during init. If _femaleUrduVoice is null the engine would use the
      // default (often male) Urdu voice — in that case use the English female
      // profile instead (which uses _femaleFallbackVoice if one was found).
      try {
        if (_urduAvailable && _femaleUrduVoice != null) {
          // Confirmed female ur-PK voice — use it with excitement settings.
          await _setUrduProfile();
          await _tts.setPitch(1.3);
          await _tts.setSpeechRate(0.56);
          await _tts.speak(phrase.urdu);
          await _awaitCompletion();
        } else {
          // No confirmed female Urdu voice → English female profile.
          // romanUrdu is already energetic mixed text (e.g. "Wow! Phir se!")
          await _setEnglishProfile();
          await _tts.setPitch(1.2);
          await _tts.setSpeechRate(0.58);
          await _tts.speak(phrase.romanUrdu);
          await _awaitCompletion();
        }
      } catch (_) {}
    }
  }

  /// Speak a story page or narrator line slowly and soothingly.
  Future<void> speakNarratorLine(String text) async {
    await _ensureReady();
    if (!_ready) return;

    try {
      await _tts.stop();
      await _audioPlayer.stop();

      // South Asian or standard English voice but even slower (0.35 rate) for clear speech training
      final hasEnPk = await _tts.isLanguageAvailable('en-PK') == true;
      final hasEnIn = await _tts.isLanguageAvailable('en-IN') == true;

      if (hasEnPk) {
        await _tts.setLanguage('en-PK');
      } else if (hasEnIn) {
        await _tts.setLanguage('en-IN');
      } else {
        await _tts.setLanguage('en-US');
      }

      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.35); // Slow, clear pronunciation for autistic kids

      await _tts.speak(text);
      await _awaitCompletion();
    } catch (e) {
      debugPrint('TtsService.speakNarratorLine error: $e');
    }
  }

  /// Speak a childlike sound cue with high pitch for sensory play (e.g. Boing, Ting, Toot-toot)
  Future<void> speakSoundCue(String soundText) async {
    await _ensureReady();
    if (!_ready) return;
    try {
      await _tts.stop();
      await _audioPlayer.stop();
      await _setEnglishProfile();
      await _tts.setPitch(1.8); // childish high pitch
      await _tts.setSpeechRate(0.8); // fast, bouncy sound
      await _tts.speak(soundText);
    } catch (e) {
      debugPrint('TtsService.speakSoundCue error: $e');
    }
  }

  /// Stop all audio immediately (called on screen dispose).
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
