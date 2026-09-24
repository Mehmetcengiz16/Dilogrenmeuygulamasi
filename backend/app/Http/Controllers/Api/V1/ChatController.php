<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\ChatMessage;
use App\Models\ConversationScenario;
use App\Services\AiService;
use App\Services\ProgressService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** AI konuşma asistanı (ai_konu_ma_ses_asistan tasarımı). */
class ChatController extends ApiController
{
    private const HISTORY_LIMIT = 20;

    public function scenarios(Request $request, AiService $ai): JsonResponse
    {
        return $this->ok([
            'ai_online' => $ai->enabled(),
            'ai_provider' => $ai->enabled() ? $ai->providerLabel() : null,
            'scenarios' => ConversationScenario::where('is_active', true)->orderBy('order')->get()
                ->map(fn ($s) => [
                    'id' => $s->id,
                    'title' => $s->title,
                    'description' => $s->description,
                    'icon' => $s->icon,
                    'level' => $s->level,
                    'estimated_minutes' => $s->estimated_minutes,
                    'opening_message' => $s->opening_message,
                ]),
        ]);
    }

    public function history(Request $request): JsonResponse
    {
        $scenarioId = $request->integer('scenario_id') ?: null;
        $messages = ChatMessage::where('user_id', $request->user()->id)
            ->where('scenario_id', $scenarioId)
            ->latest('id')->limit(50)->get()->reverse()->values();

        return $this->ok($messages->map(fn ($m) => ['id' => $m->id, 'role' => $m->role, 'content' => $m->content]));
    }

    public function send(Request $request, AiService $ai, ProgressService $progress): JsonResponse
    {
        $data = $request->validate([
            'message' => ['required', 'string', 'max:1000'],
            'scenario_id' => ['nullable', 'integer', 'exists:conversation_scenarios,id'],
        ]);
        $user = $request->user();
        $scenario = isset($data['scenario_id']) ? ConversationScenario::find($data['scenario_id']) : null;

        ChatMessage::create(['user_id' => $user->id, 'scenario_id' => $scenario?->id, 'role' => 'user', 'content' => $data['message']]);

        $history = ChatMessage::where('user_id', $user->id)->where('scenario_id', $scenario?->id)
            ->latest('id')->limit(self::HISTORY_LIMIT)->get()->reverse()->values()
            ->map(fn ($m) => ['role' => $m->role, 'content' => $m->content])->all();
        // API ilk mesajın kullanıcıdan gelmesini ister.
        while ($history && $history[0]['role'] !== 'user') {
            array_shift($history);
        }

        $targetLanguage = $user->activeUserCourse()?->course->targetLanguage?->name ?? 'İngilizce';
        $result = $ai->chat($user->name, $this->englishName($targetLanguage), $scenario, $history);

        $reply = ChatMessage::create(['user_id' => $user->id, 'scenario_id' => $scenario?->id, 'role' => 'assistant', 'content' => $result['reply']]);

        // Konuşma pratiği de günlük hedefe sayılır (mesaj başına ~30 sn).
        $progress->addXp($user, 2, 'chat');
        $progress->recordActivity($user, 30, 2);

        return $this->ok([
            'id' => $reply->id,
            'reply' => $result['reply'],
            'translation' => $result['translation'],
            'feedback' => $result['feedback'],
        ]);
    }

    public function clear(Request $request): JsonResponse
    {
        ChatMessage::where('user_id', $request->user()->id)
            ->where('scenario_id', $request->integer('scenario_id') ?: null)->delete();

        return $this->ok(null, 'Sohbet temizlendi');
    }

    private function englishName(string $turkishName): string
    {
        return [
            'İngilizce' => 'English', 'Almanca' => 'German', 'İspanyolca' => 'Spanish',
            'Fransızca' => 'French', 'İtalyanca' => 'Italian', 'Türkçe' => 'Turkish',
        ][$turkishName] ?? $turkishName;
    }
}
