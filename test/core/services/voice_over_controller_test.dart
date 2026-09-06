import 'package:ar_science_explorer/core/services/voice_over_controller.dart';
import 'package:flutter/services.dart' show VoidCallback;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FakeFlutterTts implements FlutterTts {
  final List<String> spokenTexts = [];
  final List<String> languagesSet = [];
  bool stopped = false;
  VoidCallback? _completionHandler;

  void completeCurrentUtterance() {
    _completionHandler?.call();
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spokenTexts.add(text);
    return 1;
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    languagesSet.add(language);
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    stopped = true;
    return 1;
  }

  @override
  void setCompletionHandler(VoidCallback callback) {
    _completionHandler = callback;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('VoiceOverController', () {
    test('playAll speaks each line in order, sets language once, and clears '
        'isPlaying once the queue is exhausted', () async {
      final fakeTts = FakeFlutterTts();
      final controller = VoiceOverController(tts: fakeTts);
      final lines = ['first line', 'second line', 'third line'];

      await controller.playAll(lines, 'en');
      expect(fakeTts.languagesSet, ['en-US']);
      expect(fakeTts.spokenTexts, ['first line']);
      expect(controller.isPlaying, isTrue);

      fakeTts.completeCurrentUtterance();
      expect(fakeTts.spokenTexts, ['first line', 'second line']);
      expect(controller.isPlaying, isTrue);

      fakeTts.completeCurrentUtterance();
      expect(fakeTts.spokenTexts, ['first line', 'second line', 'third line']);
      expect(controller.isPlaying, isTrue);

      fakeTts.completeCurrentUtterance();
      expect(fakeTts.spokenTexts, ['first line', 'second line', 'third line']);
      expect(controller.isPlaying, isFalse);
    });

    test('stop cancels playback and sets isPlaying to false', () async {
      final fakeTts = FakeFlutterTts();
      final controller = VoiceOverController(tts: fakeTts);

      await controller.playAll(['a', 'b'], 'Filipino');
      expect(fakeTts.languagesSet, ['fil-PH']);
      expect(controller.isPlaying, isTrue);

      await controller.stop();
      expect(controller.isPlaying, isFalse);
      expect(fakeTts.stopped, isTrue);
    });

    test(
      'a completion callback arriving after stop() does not resume playback',
      () async {
        final fakeTts = FakeFlutterTts();
        final controller = VoiceOverController(tts: fakeTts);

        await controller.playAll(['a', 'b'], 'en');
        await controller.stop();

        fakeTts.completeCurrentUtterance();

        expect(controller.isPlaying, isFalse);
        expect(fakeTts.spokenTexts, ['a']);
      },
    );
  });
}
