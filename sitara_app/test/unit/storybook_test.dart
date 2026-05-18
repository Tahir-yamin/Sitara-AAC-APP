import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sitara/services/local_db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Storybook Cooldown Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalDbService.instance.init();
    });

    test('getLastStoryPlayTime returns null initially', () {
      final time = LocalDbService.instance.getLastStoryPlayTime();
      expect(time, isNull);
    });

    test('saveLastStoryPlayTime persists timestamp and returns it correctly', () async {
      final now = DateTime.now();
      await LocalDbService.instance.saveLastStoryPlayTime(now);

      final persisted = LocalDbService.instance.getLastStoryPlayTime();
      expect(persisted, isNotNull);
      expect(persisted!.year, equals(now.year));
      expect(persisted.month, equals(now.month));
      expect(persisted.day, equals(now.day));
      expect(persisted.hour, equals(now.hour));
      expect(persisted.minute, equals(now.minute));
    });
  });
}
