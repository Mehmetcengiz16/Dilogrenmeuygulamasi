import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService();
  ref.onDispose(service.dispose);
  return service;
});

/// Sesli dinleme: içerikte ses dosyası varsa onu çalar, yoksa cihazın TTS motoruyla okur.
class SpeechService {
  final _tts = FlutterTts();
  final _player = AudioPlayer();
  double rate = 1.0;

  Future<void> speak(String text, {String language = 'en-US', String? audioUrl}) async {
    await stop();
    if (audioUrl != null) {
      try {
        await _player.setUrl(audioUrl);
        await _player.setSpeed(rate);
        await _player.play();
        return;
      } catch (_) {
        // Ses dosyası açılamazsa TTS'e düş.
      }
    }
    await _tts.setLanguage(language);
    // flutter_tts hızında 0.5 ≈ normal konuşma hızı.
    await _tts.setSpeechRate(0.5 * rate);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _player.stop();
    await _tts.stop();
  }

  void dispose() {
    _player.dispose();
    _tts.stop();
  }
}

/// Metnin diline göre kaba bir TTS dili seçer (Türkçe karakter varsa tr-TR).
String guessLanguage(String text) =>
    RegExp(r'[çğıöşüÇĞİÖŞÜ]').hasMatch(text) ? 'tr-TR' : 'en-US';
