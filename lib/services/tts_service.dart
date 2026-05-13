// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isSpeaking = false;

  static Function(String text, int start, int end, String word)? onProgress;
  static Function()? onComplete;

  static Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      onComplete?.call();
    });
    _tts.setProgressHandler((text, start, end, word) {
      onProgress?.call(text, start, end, word);
    });
  }

  static int getWordCount(String text) =>
      text.trim().split(RegExp(r'\s+')).length;

  static Duration getEstimatedDuration(String text, double rate) {
    final wc = getWordCount(text);
    final adjustedWpm = 150.0 * rate;
    return Duration(milliseconds: (wc / adjustedWpm * 60 * 1000).round());
  }

  static Future<void> speak(String text) async {
    await _tts.stop();
    _isSpeaking = true;
    await _tts.speak(text);
  }

  static Future<void> pause() async {
    _isSpeaking = false;
    await _tts.pause();
  }

  static Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  static Future<void> setSpeed(double rate) async =>
      await _tts.setSpeechRate(rate);

  static bool isSpeaking() => _isSpeaking;
}