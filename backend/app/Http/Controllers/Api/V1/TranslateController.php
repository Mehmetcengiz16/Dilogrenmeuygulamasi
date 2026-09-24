<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Resources\ExerciseResource;
use App\Models\Language;
use App\Models\Phrase;
use App\Models\SavedTranslation;
use App\Services\AiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/** Anlık çeviri ekranı (anl_k_eviri_kelime_haznesi tasarımı). */
class TranslateController extends ApiController
{
    public function home(Request $request, AiService $ai): JsonResponse
    {
        $langCode = $request->query('lang', 'en');
        $languageId = Language::where('code', $langCode)->value('id');

        $quick = Phrase::where('is_active', true)->where('type', 'quick')
            ->when($languageId, fn ($q) => $q->where('language_id', $languageId))
            ->orderBy('order')->get();
        $idioms = Phrase::where('is_active', true)->where('type', 'idiom')
            ->when($languageId, fn ($q) => $q->where('language_id', $languageId))
            ->orderBy('id')->get();
        $idiom = $idioms->isNotEmpty() ? $idioms[(int) Carbon::today()->format('z') % $idioms->count()] : null;

        return $this->ok([
            'ai_online' => $ai->enabled(),
            'languages' => Language::active()->get(['code', 'name', 'flag']),
            'quick_phrases' => $quick->map(fn ($p) => $this->phrase($p)),
            'idiom_of_day' => $idiom ? $this->phrase($idiom) : null,
        ]);
    }

    public function translate(Request $request, AiService $ai): JsonResponse
    {
        $data = $request->validate([
            'text' => ['required', 'string', 'max:2000'],
            'from' => ['required', 'string', 'max:8'],
            'to' => ['required', 'string', 'max:8', 'different:from'],
        ]);

        $result = $ai->translate($data['text'], $data['from'], $data['to']);
        if ($result['source'] === 'none') {
            return $this->fail('Bu metin için çeviri bulunamadı. AI çevirisi için ANTHROPIC_API_KEY tanımlanmalı.', 422);
        }

        $saved = SavedTranslation::create([
            'user_id' => $request->user()->id,
            'source_lang' => $data['from'],
            'target_lang' => $data['to'],
            'source_text' => $data['text'],
            'translated_text' => $result['text'],
            'pronunciation' => $result['pronunciation'],
            'is_favorite' => false,
        ]);

        return $this->ok($this->saved($saved) + ['confidence' => $result['confidence'], 'source' => $result['source']]);
    }

    public function history(Request $request): JsonResponse
    {
        $query = $request->user()->savedTranslations()->latest();
        if ($request->boolean('favorites')) {
            $query->where('is_favorite', true);
        }
        $page = $query->paginate(30);

        return $this->paginated($page, $page->getCollection()->map(fn ($t) => $this->saved($t)));
    }

    public function favorite(Request $request, SavedTranslation $translation): JsonResponse
    {
        abort_unless($translation->user_id === $request->user()->id, 404);
        $translation->update(['is_favorite' => ! $translation->is_favorite]);

        return $this->ok($this->saved($translation));
    }

    private function phrase(Phrase $p): array
    {
        return [
            'id' => $p->id,
            'text' => $p->text,
            'translation' => $p->translation,
            'emoji' => $p->emoji,
            'pronunciation' => $p->pronunciation,
            'image_url' => ExerciseResource::url($p->image_path),
        ];
    }

    private function saved(SavedTranslation $t): array
    {
        return [
            'id' => $t->id,
            'source_lang' => $t->source_lang,
            'target_lang' => $t->target_lang,
            'source_text' => $t->source_text,
            'translated_text' => $t->translated_text,
            'pronunciation' => $t->pronunciation,
            'is_favorite' => $t->is_favorite,
            'created_at' => $t->created_at?->toIso8601String(),
        ];
    }
}
