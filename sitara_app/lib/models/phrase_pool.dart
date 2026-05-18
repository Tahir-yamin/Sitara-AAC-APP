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

class PhrasePool {
  static final _rng = Random();

  static const tryAgain = Phrase(urdu: 'محنت کرو', romanUrdu: 'Mehnat karo', english: 'Try again', audioAsset: 'audio/mehnat.mp3');
  static const shabash = Phrase(urdu: 'شاباش!', romanUrdu: 'Shabash!', english: 'Well done!', audioAsset: 'audio/shabash.mp3');
  static const bohatAcha = Phrase(urdu: 'بہت اچھا!', romanUrdu: 'Bohat acha!', english: 'Very good!', audioAsset: 'audio/bohat_acha.mp3');
  static const zabardast = Phrase(urdu: 'زبردست!', romanUrdu: 'Zabardast!', english: 'Fantastic!', audioAsset: 'audio/zabardast.mp3');

  static const _good = [
    shabash,
    Phrase(urdu: 'بلکل سہی!', romanUrdu: 'Bilkul sahi!', english: 'Exactly right!', audioAsset: 'audio/praise_1.mp3'),
    bohatAcha,
    Phrase(urdu: 'واہ! صحیح جواب!', romanUrdu: 'Wah! Sahi jawab!', english: 'Wow! Correct answer!', audioAsset: 'audio/praise_3.mp3'),
    Phrase(urdu: 'کمال ہے!', romanUrdu: 'Kamaal hai!', english: 'Amazing!', audioAsset: 'audio/praise_4.mp3'),
  ];

  static const _great = [
    Phrase(urdu: 'واہ واہ! کمال!', romanUrdu: 'Wah wah! Kamaal!', english: 'Brilliant!', audioAsset: 'audio/praise_5.mp3'),
    Phrase(urdu: 'بہت خوب!', romanUrdu: 'Bohat khoob!', english: 'Excellent!', audioAsset: 'audio/praise_6.mp3'),
    zabardast,
    Phrase(urdu: 'سوپر! ایک اور کرو!', romanUrdu: 'Super! Ek aur karo!', english: 'Super! One more!', audioAsset: 'audio/praise_8.mp3'),
    Phrase(urdu: 'شاندار!', romanUrdu: 'Shandaar!', english: 'Splendid!', audioAsset: 'audio/praise_9.mp3'),
  ];

  static const _amazing = [
    Phrase(urdu: 'تم چیمپئن ہو!', romanUrdu: 'Tum champion ho!', english: 'You are a champion!', audioAsset: 'audio/praise_10.mp3'),
    Phrase(urdu: 'شیر بچہ!', romanUrdu: 'Sher bacha!', english: 'Brave one!', audioAsset: 'audio/praise_11.mp3'),
    Phrase(urdu: 'تم بہت ہوشیار ہو!', romanUrdu: 'Tum bohat hoshiyar ho!', english: 'You are so smart!', audioAsset: 'audio/praise_12.mp3'),
    Phrase(urdu: 'ماشاللہ! بہت بہت اچھا!', romanUrdu: 'Masha Allah! Bohat bohat acha!', english: 'Outstanding!', audioAsset: 'audio/praise_13.mp3'),
    Phrase(urdu: 'سپر ہیرو!', romanUrdu: 'Superhero!', english: 'Superhero!', audioAsset: 'audio/praise_14.mp3'),
  ];

  static List<String> get greatTierRomanUrdu =>
      _great.map((p) => p.romanUrdu).toList();

  static List<String> get amazingTierRomanUrdu =>
      _amazing.map((p) => p.romanUrdu).toList();

  static Phrase? findPhrase(String text) {
    final normalizedInput = text.trim().toLowerCase().replaceAll('!', '').replaceAll('.', '').replaceAll('?', '');
    final allPhrases = [..._good, ..._great, ..._amazing, tryAgain];
    for (final p in allPhrases) {
      if (p.urdu.replaceAll('!', '').replaceAll('.', '').replaceAll('?', '').trim() == text.trim() ||
          p.romanUrdu.toLowerCase().replaceAll('!', '').replaceAll('.', '').replaceAll('?', '').trim() == normalizedInput ||
          p.english.toLowerCase().replaceAll('!', '').replaceAll('.', '').replaceAll('?', '').trim() == normalizedInput) {
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
