import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class Phrase {
  Phrase({required this.id, required this.text, required this.translation, this.emoji, this.pronunciation, this.imageUrl});
  final int id;
  final String text;
  final String translation;
  final String? emoji;
  final String? pronunciation;
  final String? imageUrl;

  factory Phrase.fromJson(Map<String, dynamic> j) => Phrase(
        id: j['id'] as int,
        text: j['text'] as String,
        translation: j['translation'] as String,
        emoji: j['emoji'] as String?,
        pronunciation: j['pronunciation'] as String?,
        imageUrl: j['image_url'] as String?,
      );
}

class Translation {
  Translation({
    required this.id,
    required this.sourceLang,
    required this.targetLang,
    required this.sourceText,
    required this.translatedText,
    this.pronunciation,
    required this.isFavorite,
    this.confidence,
  });

  final int id;
  final String sourceLang;
  final String targetLang;
  final String sourceText;
  final String translatedText;
  final String? pronunciation;
  final bool isFavorite;
  final int? confidence;

  factory Translation.fromJson(Map<String, dynamic> j) => Translation(
        id: j['id'] as int,
        sourceLang: j['source_lang'] as String,
        targetLang: j['target_lang'] as String,
        sourceText: j['source_text'] as String,
        translatedText: j['translated_text'] as String,
        pronunciation: j['pronunciation'] as String?,
        isFavorite: j['is_favorite'] as bool? ?? false,
        confidence: j['confidence'] as int?,
      );
}

class TranslateHome {
  TranslateHome({required this.aiOnline, required this.languages, required this.phrases, this.idiom});
  final bool aiOnline;
  final Map<String, ({String name, String flag})> languages;
  final List<Phrase> phrases;
  final Phrase? idiom;
}

final translateHomeProvider = FutureProvider.autoDispose<TranslateHome>((ref) async {
  final d = await ref.watch(apiClientProvider).get<Map<String, dynamic>>('/translate/home', query: {'lang': 'en'});
  return TranslateHome(
    aiOnline: d['ai_online'] as bool,
    languages: {
      for (final l in (d['languages'] as List).cast<Map<String, dynamic>>())
        l['code'] as String: (name: l['name'] as String, flag: l['flag'] as String? ?? '🌐'),
    },
    phrases: (d['quick_phrases'] as List).map((p) => Phrase.fromJson(p as Map<String, dynamic>)).toList(),
    idiom: d['idiom_of_day'] == null ? null : Phrase.fromJson(d['idiom_of_day'] as Map<String, dynamic>),
  );
});

final translationHistoryProvider = FutureProvider.autoDispose.family<List<Translation>, bool>((ref, favorites) async {
  final d = await ref.watch(apiClientProvider).get<List<dynamic>>('/translate/history', query: {if (favorites) 'favorites': 1});
  return d.map((t) => Translation.fromJson(t as Map<String, dynamic>)).toList();
});

class TranslateRepository {
  TranslateRepository(this._api);
  final ApiClient _api;

  Future<Translation> translate(String text, String from, String to) async =>
      Translation.fromJson(await _api.post<Map<String, dynamic>>('/translate', data: {'text': text, 'from': from, 'to': to}));

  Future<Translation> toggleFavorite(int id) async =>
      Translation.fromJson(await _api.post<Map<String, dynamic>>('/translate/$id/favorite'));
}

final translateRepositoryProvider = Provider((ref) => TranslateRepository(ref.watch(apiClientProvider)));
