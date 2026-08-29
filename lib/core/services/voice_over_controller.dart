import 'package:flutter_tts/flutter_tts.dart';

/// Wraps FlutterTts for the AR Lab's Scan-phase narration — ported from the
/// retired web app's src/hooks/useVoiceOver.ts (Web Speech API) onto
/// on-device TTS. Language is 'en' or 'Filipino', matching
/// kVoiceScripts's keys and the student's toggle.
class VoiceOverController {
  VoiceOverController({required FlutterTts tts}) : _tts = tts {
    _tts.setCompletionHandler(_onUtteranceComplete);
  }

  final FlutterTts _tts;
  List<String> _queue = const [];
  int _index = 0;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> playAll(List<String> lines, String language) async {
    await _tts.setLanguage(language == 'en' ? 'en-US' : 'fil-PH');
    _queue = lines;
    _index = 0;
    if (_queue.isEmpty) return;
    _isPlaying = true;
    await _tts.speak(_queue[_index]);
  }

  Future<void> replay() async {
    if (_queue.isEmpty) return;
    _index = 0;
    _isPlaying = true;
    await _tts.speak(_queue[_index]);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
  }

  void _onUtteranceComplete() {
    _index += 1;
    if (_index < _queue.length) {
      _tts.speak(_queue[_index]);
    } else {
      _isPlaying = false;
    }
  }
}
