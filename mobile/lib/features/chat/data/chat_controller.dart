import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_controller.dart';

class Scenario {
  Scenario({required this.id, required this.title, this.description, required this.icon, required this.openingMessage});
  final int id;
  final String title;
  final String? description;
  final String icon;
  final String openingMessage;

  factory Scenario.fromJson(Map<String, dynamic> j) => Scenario(
        id: j['id'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        icon: j['icon'] as String? ?? 'forum',
        openingMessage: j['opening_message'] as String,
      );
}

class ChatMessage {
  ChatMessage({required this.role, required this.content, this.translation});
  final String role;
  final String content;
  final String? translation;
  bool get isUser => role == 'user';
}

class ChatState {
  const ChatState({
    this.aiOnline = false,
    this.aiProvider,
    this.scenarios = const [],
    this.scenario,
    this.messages = const [],
    this.sending = false,
    this.accuracy,
    this.fluency,
    this.error,
    this.loaded = false,
  });

  final bool aiOnline;
  final String? aiProvider;
  final List<Scenario> scenarios;
  final Scenario? scenario;
  final List<ChatMessage> messages;
  final bool sending;
  final int? accuracy;
  final String? fluency;
  final String? error;
  final bool loaded;

  ChatMessage? get lastAssistant => messages.lastWhereOrNull((m) => !m.isUser);
  ChatMessage? get lastUser => messages.lastWhereOrNull((m) => m.isUser);

  ChatState copyWith({
    bool? aiOnline,
    String? aiProvider,
    List<Scenario>? scenarios,
    Scenario? scenario,
    bool clearScenario = false,
    List<ChatMessage>? messages,
    bool? sending,
    int? accuracy,
    String? fluency,
    String? error,
    bool? loaded,
  }) =>
      ChatState(
        aiOnline: aiOnline ?? this.aiOnline,
        aiProvider: aiProvider ?? this.aiProvider,
        scenarios: scenarios ?? this.scenarios,
        scenario: clearScenario ? null : (scenario ?? this.scenario),
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        accuracy: accuracy ?? this.accuracy,
        fluency: fluency ?? this.fluency,
        error: error,
        loaded: loaded ?? this.loaded,
      );
}

extension<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);

class ChatController extends Notifier<ChatState> {
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  ChatState build() {
    Future.microtask(load);
    return const ChatState();
  }

  Future<void> load({int? scenarioId}) async {
    try {
      final d = await _api.get<Map<String, dynamic>>('/chat/scenarios');
      final scenarios = (d['scenarios'] as List).map((s) => Scenario.fromJson(s as Map<String, dynamic>)).toList();
      state = state.copyWith(
        aiOnline: d['ai_online'] as bool,
        aiProvider: d['ai_provider'] as String?,
        scenarios: scenarios,
        loaded: true,
      );
      if (scenarioId != null) {
        await selectScenario(scenarios.where((s) => s.id == scenarioId).firstOrNull);
      } else {
        await _loadHistory();
      }
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message, loaded: true);
    }
  }

  Future<void> selectScenario(Scenario? s) async {
    state = state.copyWith(scenario: s, clearScenario: s == null, messages: const []);
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final sid = state.scenario?.id;
    final list = await _api.get<List<dynamic>>('/chat/messages', query: {'scenario_id': ?sid});
    final messages = list
        .map((m) => ChatMessage(role: (m as Map)['role'] as String, content: m['content'] as String))
        .toList();
    // Yeni senaryoda sohbeti Lina'nın açılış mesajı başlatır.
    if (messages.isEmpty) {
      messages.add(ChatMessage(
        role: 'assistant',
        content: state.scenario?.openingMessage ??
            'Merhaba ${_firstName()}! Bugün hangi konuda pratik yapalım? Bir senaryo seç ya da bana yaz.',
      ));
    }
    state = state.copyWith(messages: messages);
  }

  String _firstName() => ref.read(authControllerProvider).value?.name.split(' ').first ?? '';

  Future<ChatMessage?> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.sending) return null;
    state = state.copyWith(sending: true, messages: [...state.messages, ChatMessage(role: 'user', content: message)]);
    try {
      final d = await _api.post<Map<String, dynamic>>('/chat/messages', data: {
        'message': message,
        'scenario_id': ?state.scenario?.id,
      });
      final reply = ChatMessage(role: 'assistant', content: d['reply'] as String, translation: d['translation'] as String?);
      final fb = d['feedback'] as Map<String, dynamic>?;
      state = state.copyWith(
        sending: false,
        messages: [...state.messages, reply],
        accuracy: fb?['accuracy'] as int?,
        fluency: fb?['fluency'] as String?,
      );
      return reply;
    } on ApiException catch (e) {
      state = state.copyWith(sending: false, error: e.message);
      return null;
    }
  }

  Future<void> clear() async {
    await _api.delete('/chat/messages', query: {'scenario_id': ?state.scenario?.id});
    state = state.copyWith(messages: const []);
    await _loadHistory();
  }
}
