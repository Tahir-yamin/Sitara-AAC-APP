import 'dart:math';

class Phrase {
  final String urdu;
  final String romanUrdu;
  final String english;

  const Phrase({
    required this.urdu,
    required this.romanUrdu,
    required this.english,
  });

  String get ttsText => urdu;
  String get displayText => '$urdu\n$romanUrdu';
}

class PhrasePool {
  static final _rng = Random();

  static const _good = [
    Phrase(urdu: 'شاباش!', romanUrdu: 'Shabash!', english: 'Well done!'),
    Phrase(urdu: 'بلکل سہی!', romanUrdu: 'Bilkul sahi!', english: 'Exactly right!'),
    Phrase(urdu: 'بہت اچھا!', romanUrdu: 'Bohat acha!', english: 'Very good!'),
    Phrase(urdu: 'واہ! صحیح جواب!', romanUrdu: 'Wah! Sahi jawab!', english: 'Wow! Correct answer!'),
    Phrase(urdu: 'کمال ہے!', romanUrdu: 'Kamaal hai!', english: 'Amazing!'),
  ];

  static const _great = [
    Phrase(urdu: 'واہ واہ! کمال!', romanUrdu: 'Wah wah! Kamaal!', english: 'Brilliant!'),
    Phrase(urdu: 'بہت خوب!', romanUrdu: 'Bohat khoob!', english: 'Excellent!'),
    Phrase(urdu: 'زبردست!', romanUrdu: 'Zabardast!', english: 'Fantastic!'),
    Phrase(urdu: 'سوپر! ایک اور کرو!', romanUrdu: 'Super! Ek aur karo!', english: 'Super! One more!'),
    Phrase(urdu: 'شاندار!', romanUrdu: 'Shandaar!', english: 'Splendid!'),
  ];

  static const _amazing = [
    Phrase(urdu: 'تم چیمپئن ہو!', romanUrdu: 'Tum champion ho!', english: 'You are a champion!'),
    Phrase(urdu: 'شیر بچہ!', romanUrdu: 'Sher bacha!', english: 'Brave one!'),
    Phrase(urdu: 'تم بہت ہوشیار ہو!', romanUrdu: 'Tum bohat hoshiyar ho!', english: 'You are so smart!'),
    Phrase(urdu: 'ماشاللہ! بہت بہت اچھا!', romanUrdu: 'Masha Allah! Bohat bohat acha!', english: 'Outstanding!'),
    Phrase(urdu: 'سپر ہیرو!', romanUrdu: 'Superhero!', english: 'Superhero!'),
  ];

  static List<String> get greatTierRomanUrdu =>
      _great.map((p) => p.romanUrdu).toList();

  static List<String> get amazingTierRomanUrdu =>
      _amazing.map((p) => p.romanUrdu).toList();

  static Phrase pickPraise({required int streak}) {
    final pool = streak >= 6 ? _amazing : (streak >= 3 ? _great : _good);
    return pool[_rng.nextInt(pool.length)];
  }
}
