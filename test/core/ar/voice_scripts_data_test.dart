import 'package:ar_science_explorer/core/ar/voice_scripts_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kVoiceScripts', () {
    test('onboarding has 6 lines per language and mentions the app name', () {
      final onboarding = kVoiceScripts['onboarding']!;
      expect(onboarding['en']!.length, 6);
      expect(onboarding['Filipino']!.length, 6);
      expect(onboarding['en']!.first, contains('AR Science Explorer'));
    });

    test('top-level keys are onboarding plus exactly q1w1..q1w5', () {
      final lessonKeys = kVoiceScripts.keys.where((k) => k != 'onboarding');
      expect(lessonKeys.toSet(), {'q1w1', 'q1w2', 'q1w3', 'q1w4', 'q1w5'});
    });

    test('q1w1 has 3 English lines with the exact expected first line', () {
      final q1w1En = kVoiceScripts['q1w1']!['en']!;
      expect(q1w1En.length, 3);
      expect(
        q1w1En.first,
        "Scientists use models to explain things too small to see directly. Let's explore how the particle model helps us understand matter.",
      );
    });
  });
}
