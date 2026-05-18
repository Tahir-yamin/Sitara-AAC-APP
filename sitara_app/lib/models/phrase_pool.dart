import 'dart:math';

class Phrase {
  final String urdu;
  final String romanUrdu;
  final String english;
  final String audioAsset;

  const Phrase({
    required this.urdu,
    required this.romanUrdu,
    required this.english,
    required this.audioAsset,
  });

  String get ttsText => urdu;
  String get displayText => '$urdu\n$romanUrdu';
}

/// Praise phrase pools for Sitara AAC game.
///
/// TEXT RULES
/// • [urdu]       — clean Urdu script, spoken by ur-PK TTS engine.
///                  Short (≤ 4 words). No English words here.
/// • [romanUrdu]  — ENERGETIC mix of English + Roman Urdu, spoken by
///                  South-Asian English TTS when ur-PK is unavailable.
///                  Starts with a high-energy English word so even the
///                  English-TTS fallback sounds excited.
/// • [audioAsset] — pre-recorded female Pakistani-accented MP3 (first choice).
///
/// WRONG ANSWER — short, warm, never demoralising.
/// CORRECT     — escalating energy: good → great → amazing.
class PhrasePool {
  static final _rng = Random();

  // ── Wrong answer ────────────────────────────────────────────────────────────
  static const tryAgain = Phrase(
    urdu: 'اوہو! کوئی بات نہیں!',
    romanUrdu: 'Oho! Koi baat nahi!',
    english: 'Oho! Never mind!',
    audioAsset: 'audio/koi_baat_nai.mp3',
  );

  // ── Named constants (also wired into pools below) ───────────────────────────
  static const shabash = Phrase(
    urdu: 'شاباش!',
    romanUrdu: 'Wow! Shabash!',
    english: 'Well done!',
    audioAsset: 'audio/shabash.mp3',
  );

  static const bohatAcha = Phrase(
    urdu: 'بہت اچھا!',
    romanUrdu: 'Yes! Bohat Acha!',
    english: 'Very good!',
    audioAsset: 'audio/bohat_acha.mp3',
  );

  static const zabardast = Phrase(
    urdu: 'زبردست!',
    romanUrdu: 'Amazing! Zabardast!',
    english: 'Fantastic!',
    audioAsset: 'audio/zabardast.mp3',
  );

  // ── Streak tier 1 — first 1-2 correct answers ───────────────────────────────
  static const _good = [
    shabash,
    Phrase(
      urdu: 'بلکل سہی!',
      romanUrdu: 'Yes! Bilkul Sahi!',
      english: 'Exactly right!',
      audioAsset: 'audio/praise_1.mp3',
    ),
    bohatAcha,
    Phrase(
      urdu: 'واہ! سہی جواب!',
      romanUrdu: 'WOW! Correct! Wah!',
      english: 'Wow! Correct!',
      audioAsset: 'audio/praise_3.mp3',
    ),
    Phrase(
      urdu: 'کمال ہے!',
      romanUrdu: 'Amazing! Kamaal!',
      english: 'Amazing!',
      audioAsset: 'audio/praise_4.mp3',
    ),
  ];

  // ── Streak tier 2 — streak ≥ 3 ──────────────────────────────────────────────
  static const _great = [
    Phrase(
      urdu: 'واہ واہ! کمال!',
      romanUrdu: 'WOW WOW! Brilliant! Kamaal!',
      english: 'Brilliant!',
      audioAsset: 'audio/praise_5.mp3',
    ),
    Phrase(
      urdu: 'بہت خوب!',
      romanUrdu: 'Excellent! Bohat Khoob!',
      english: 'Excellent!',
      audioAsset: 'audio/praise_6.mp3',
    ),
    zabardast,
    Phrase(
      urdu: 'شاندار!',
      romanUrdu: 'Incredible! Shandaar!',
      english: 'Splendid!',
      audioAsset: 'audio/praise_9.mp3',
    ),
  ];

  // ── Streak tier 3 — streak ≥ 6 ──────────────────────────────────────────────
  static const _amazing = [
    Phrase(
      urdu: 'شیر بچہ! واہ!',
      romanUrdu: 'Sher Bacha! You ROCK! WOW!',
      english: 'Brave champion!',
      audioAsset: 'audio/praise_11.mp3',
    ),
    Phrase(
      urdu: 'ماشاءاللہ! واہ!',
      romanUrdu: 'Masha Allah! OUTSTANDING! Wow!',
      english: 'Outstanding!',
      audioAsset: 'audio/praise_13.mp3',
    ),
  ];

  static List<String> get greatTierRomanUrdu =>
      _great.map((p) => p.romanUrdu).toList();

  static List<String> get amazingTierRomanUrdu =>
      _amazing.map((p) => p.romanUrdu).toList();

  /// Matches a phrase string (from agent trigger_reward) to the nearest
  /// pre-recorded Phrase, normalising punctuation and case.
  static Phrase? findPhrase(String text) {
    String clean(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'[!.?]'), '');
    final normalised = clean(text);
    final all = [..._good, ..._great, ..._amazing, tryAgain];
    for (final p in all) {
      if (clean(p.urdu) == clean(text) ||
          clean(p.romanUrdu) == normalised ||
          clean(p.english) == normalised) {
        return p;
      }
    }
    return null;
  }

  static Phrase pickPraise({required int streak}) {
    final pool = streak >= 6 ? _amazing : (streak >= 3 ? _great : _good);
    return pool[_rng.nextInt(pool.length)];
  }
}
