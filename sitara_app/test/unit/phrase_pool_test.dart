import 'package:flutter_test/flutter_test.dart';
import 'package:sitara/models/phrase_pool.dart';

void main() {
  group('PhrasePool', () {
    test('pickPraise returns a Phrase for streak 0', () {
      final phrase = PhrasePool.pickPraise(streak: 0);
      expect(phrase.urdu, isNotEmpty);
      expect(phrase.romanUrdu, isNotEmpty);
      expect(phrase.english, isNotEmpty);
    });

    test('pickPraise returns great tier phrase for streak >= 3', () {
      for (int i = 0; i < 20; i++) {
        final phrase = PhrasePool.pickPraise(streak: 3);
        expect(
          PhrasePool.greatTierRomanUrdu.contains(phrase.romanUrdu) ||
          PhrasePool.amazingTierRomanUrdu.contains(phrase.romanUrdu),
          isTrue,
          reason: 'Expected great/amazing tier at streak 3, got: ${phrase.romanUrdu}',
        );
      }
    });

    test('pickPraise returns amazing tier phrase for streak >= 6', () {
      for (int i = 0; i < 20; i++) {
        final phrase = PhrasePool.pickPraise(streak: 6);
        expect(
          PhrasePool.amazingTierRomanUrdu.contains(phrase.romanUrdu),
          isTrue,
          reason: 'Expected amazing tier at streak 6, got: ${phrase.romanUrdu}',
        );
      }
    });

    test('Phrase.ttsText returns Urdu script string', () {
      final phrase = PhrasePool.pickPraise(streak: 0);
      expect(phrase.ttsText, equals(phrase.urdu));
    });
  });
}
