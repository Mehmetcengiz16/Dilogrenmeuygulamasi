<?php

namespace App\Http\Controllers\Admin;

use App\Enums\ExerciseType;
use App\Http\Controllers\Controller;
use App\Models\Exercise;
use App\Models\Lesson;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class ExerciseController extends Controller
{
    public function create(Lesson $lesson): View
    {
        return view('admin.exercises.form', ['lesson' => $lesson->load('unit.course'), 'exercise' => null]);
    }

    public function store(Request $request, Lesson $lesson): RedirectResponse
    {
        $this->save($request, new Exercise(['lesson_id' => $lesson->id, 'order' => ($lesson->exercises()->max('order') ?? 0) + 1]));

        return redirect()->route('admin.lessons.show', $lesson)->with('status', 'Alıştırma eklendi');
    }

    public function edit(Exercise $exercise): View
    {
        return view('admin.exercises.form', ['lesson' => $exercise->lesson->load('unit.course'), 'exercise' => $exercise->load('options')]);
    }

    public function update(Request $request, Exercise $exercise): RedirectResponse
    {
        $this->save($request, $exercise);

        return redirect()->route('admin.lessons.show', $exercise->lesson_id)->with('status', 'Alıştırma güncellendi');
    }

    public function destroy(Exercise $exercise): RedirectResponse
    {
        $exercise->delete();

        return back()->with('status', 'Alıştırma silindi');
    }

    public function reorder(Request $request, Lesson $lesson)
    {
        $ids = $request->validate(['ids' => 'required|array', 'ids.*' => 'integer'])['ids'];
        foreach ($ids as $i => $id) {
            $lesson->exercises()->whereKey($id)->update(['order' => $i + 1]);
        }

        return response()->json(['success' => true]);
    }

    private function save(Request $request, Exercise $exercise): void
    {
        $data = $request->validate([
            'type' => ['required', Rule::enum(ExerciseType::class)],
            'category' => 'nullable|string|max:60',
            'instruction' => 'nullable|string|max:120',
            'prompt' => 'required|string|max:1000',
            'prompt_translation' => 'nullable|string|max:1000',
            'answer' => 'nullable|string|max:500',
            'explanation' => 'nullable|string|max:500',
            'xp' => 'required|integer|min:0|max:100',
            'image_url' => 'nullable|url|max:1024',
            'image' => 'nullable|image|max:1024',
            'audio' => 'nullable|file|mimes:mp3,m4a,mp4,aac|max:2048',
            'remove_image' => 'boolean',
            'remove_audio' => 'boolean',
            'options' => 'nullable|array',
            'options.*.text' => 'nullable|string|max:255',
            'options.*.translation' => 'nullable|string|max:255',
            'options.*.pair_key' => 'nullable|string|max:20',
            'options.*.is_correct' => 'nullable|boolean',
        ]);

        $type = ExerciseType::from($data['type']);
        $options = collect($data['options'] ?? [])->filter(fn ($o) => filled($o['text'] ?? null))->values();
        $this->validateByType($type, $data, $options);

        if ($type === ExerciseType::SentenceOrder && $options->isEmpty()) {
            $options = collect(preg_split('/\s+/', trim($data['answer'])))->shuffle()
                ->map(fn ($w) => ['text' => $w, 'is_correct' => true]);
        }

        DB::transaction(function () use ($request, $exercise, $data, $type, $options) {
            $exercise->fill([
                'type' => $type,
                'category' => $data['category'] ?? null,
                'instruction' => $data['instruction'] ?? null,
                'prompt' => $data['prompt'],
                'prompt_translation' => $data['prompt_translation'] ?? null,
                'correct_answer' => filled($data['answer'] ?? null) ? ['text' => trim($data['answer'])] : null,
                'explanation' => $data['explanation'] ?? null,
                'xp' => $data['xp'],
            ]);

            $this->media($request, $exercise, 'image', 'image_path', 'images', $data['image_url'] ?? null);
            $this->media($request, $exercise, 'audio', 'audio_path', 'audio');
            $exercise->save();

            $exercise->options()->delete();
            foreach ($options as $i => $o) {
                $exercise->options()->create([
                    'text' => $o['text'],
                    'translation' => $o['translation'] ?? null,
                    'pair_key' => $o['pair_key'] ?? null,
                    'is_correct' => (bool) ($o['is_correct'] ?? false) || in_array($type, [ExerciseType::MatchPairs, ExerciseType::SentenceOrder], true),
                    'order' => $i + 1,
                ]);
            }
        });
    }

    private function validateByType(ExerciseType $type, array $data, $options): void
    {
        $error = match ($type) {
            ExerciseType::MultipleChoice, ExerciseType::ImageSelect => match (true) {
                $options->count() < 2 => 'En az 2 seçenek girin.',
                ! $options->contains(fn ($o) => ! empty($o['is_correct'])) => 'En az bir seçeneği doğru olarak işaretleyin.',
                default => null,
            },
            ExerciseType::MatchPairs => $options->count() < 4 || $options->groupBy('pair_key')->contains(fn ($g, $k) => blank($k) || $g->count() !== 2)
                ? 'Eşleştirmede her çift anahtarı (ör. p1) tam iki seçenekte kullanılmalı; en az 2 çift girin.'
                : null,
            ExerciseType::FillBlank, ExerciseType::ListenWrite, ExerciseType::SentenceOrder => blank($data['answer'] ?? null)
                ? 'Bu alıştırma tipi için doğru cevap zorunludur.'
                : null,
        };

        if ($type === ExerciseType::FillBlank && ! str_contains($data['prompt'], '___')) {
            $error ??= 'Boşluk doldurma sorusunda boşluğu ___ (üç alt çizgi) ile belirtin.';
        }
        if ($error) {
            throw ValidationException::withMessages(['options' => $error]);
        }
    }

    private function media(Request $request, Exercise $exercise, string $input, string $column, string $folder, ?string $url = null): void
    {
        $old = $exercise->{$column};
        $deleteOld = fn () => $old && ! str_starts_with($old, 'http') ? Storage::disk('public')->delete($old) : null;

        if ($request->hasFile($input)) {
            $deleteOld();
            $exercise->{$column} = $request->file($input)->store($folder, 'public');
        } elseif ($url) {
            $deleteOld();
            $exercise->{$column} = $url;
        } elseif ($request->boolean('remove_'.$input)) {
            $deleteOld();
            $exercise->{$column} = null;
        }
    }
}
