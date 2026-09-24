<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Resources\ExerciseResource;
use App\Models\UserWord;
use App\Models\Word;
use App\Services\ReviewService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WordController extends ApiController
{
    public function index(Request $request): JsonResponse
    {
        $query = $request->user()->userWords()->with('word')->latest('updated_at');

        match ($request->query('filter', 'learned')) {
            'favorite' => $query->where('is_favorite', true),
            'review' => $query->where('next_review_at', '<=', now()),
            default => null,
        };

        $page = $query->paginate(30);

        return $this->paginated($page, $page->getCollection()->map(fn (UserWord $uw) => $this->present($uw)));
    }

    public function review(Request $request, Word $word, ReviewService $reviews): JsonResponse
    {
        $data = $request->validate(['correct' => ['required', 'boolean']]);
        $userWord = UserWord::firstOrCreate(['user_id' => $request->user()->id, 'word_id' => $word->id]);

        return $this->ok($this->present($reviews->review($userWord, $data['correct'])->load('word')));
    }

    public function favorite(Request $request, Word $word): JsonResponse
    {
        $userWord = UserWord::firstOrCreate(['user_id' => $request->user()->id, 'word_id' => $word->id]);
        $userWord->update(['is_favorite' => ! $userWord->is_favorite]);

        return $this->ok($this->present($userWord->load('word')));
    }

    private function present(UserWord $uw): array
    {
        return [
            'id' => $uw->word->id,
            'word' => $uw->word->word,
            'translation' => $uw->word->translation,
            'pronunciation' => $uw->word->pronunciation,
            'example_sentence' => $uw->word->example_sentence,
            'example_translation' => $uw->word->example_translation,
            'audio_url' => ExerciseResource::url($uw->word->audio_path),
            'image_url' => ExerciseResource::url($uw->word->image_path),
            'strength' => $uw->strength,
            'is_favorite' => $uw->is_favorite,
            'next_review_at' => $uw->next_review_at?->toIso8601String(),
        ];
    }
}
