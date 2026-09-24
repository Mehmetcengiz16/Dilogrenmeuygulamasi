<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Lesson;
use App\Models\Unit;
use App\Models\Word;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class LessonController extends Controller
{
    private function rules(): array
    {
        return [
            'title' => 'required|string|max:120',
            'description' => 'nullable|string|max:500',
            'type' => 'required|in:'.implode(',', array_keys(Lesson::TYPES)),
            'skill' => 'required|in:'.implode(',', array_keys(Lesson::SKILLS)),
            'xp_reward' => 'required|integer|min:0|max:500',
            'estimated_minutes' => 'required|integer|min:1|max:180',
            'time_limit_seconds' => 'nullable|integer|min:30|max:7200',
            'is_published' => 'boolean',
            'word_ids' => 'nullable|array',
            'word_ids.*' => 'integer|exists:words,id',
        ];
    }

    public function create(Unit $unit): View
    {
        return view('admin.lessons.form', ['unit' => $unit, 'lesson' => null, 'words' => $this->words($unit)]);
    }

    public function store(Request $request, Unit $unit): RedirectResponse
    {
        $data = $request->validate($this->rules());
        $lesson = $unit->lessons()->create(collect($data)->except('word_ids')->all() + ['order' => ($unit->lessons()->max('order') ?? 0) + 1]);
        $lesson->words()->sync($data['word_ids'] ?? []);

        return redirect()->route('admin.lessons.show', $lesson)->with('status', 'Ders oluşturuldu, şimdi alıştırma ekleyebilirsiniz');
    }

    public function show(Lesson $lesson): View
    {
        $lesson->load(['unit.course', 'exercises.options', 'words']);

        return view('admin.lessons.show', compact('lesson'));
    }

    public function edit(Lesson $lesson): View
    {
        return view('admin.lessons.form', ['unit' => $lesson->unit, 'lesson' => $lesson->load('words'), 'words' => $this->words($lesson->unit)]);
    }

    public function update(Request $request, Lesson $lesson): RedirectResponse
    {
        $data = $request->validate($this->rules());
        $lesson->update(collect($data)->except('word_ids')->all());
        $lesson->words()->sync($data['word_ids'] ?? []);

        return redirect()->route('admin.lessons.show', $lesson)->with('status', 'Ders güncellendi');
    }

    public function destroy(Lesson $lesson): RedirectResponse
    {
        $courseId = $lesson->unit->course_id;
        $lesson->delete();

        return redirect()->route('admin.courses.show', $courseId)->with('status', 'Ders silindi');
    }

    public function reorder(Request $request, Unit $unit)
    {
        $ids = $request->validate(['ids' => 'required|array', 'ids.*' => 'integer'])['ids'];
        foreach ($ids as $i => $id) {
            // Başka üniteden sürüklenen ders de bu üniteye taşınır.
            Lesson::whereKey($id)->whereHas('unit', fn ($q) => $q->where('course_id', $unit->course_id))
                ->update(['order' => $i + 1, 'unit_id' => $unit->id]);
        }

        return response()->json(['success' => true]);
    }

    private function words(Unit $unit)
    {
        return Word::where('language_id', $unit->course->target_language_id)->orderBy('word')->pluck('word', 'id');
    }
}
