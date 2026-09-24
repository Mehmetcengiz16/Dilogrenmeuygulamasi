<?php

namespace App\Http\Controllers\Admin;

use App\Models\Course;
use App\Models\Language;
use Illuminate\Database\Eloquent\Model;
use Illuminate\View\View;

class CourseController extends CrudController
{
    protected function config(): array
    {
        $languages = Language::pluck('name', 'id')->all();

        return [
            'title' => 'Kurslar', 'singular' => 'Kurs', 'route' => 'admin.courses', 'icon' => 'school',
            'subtitle' => 'Kurs → Ünite → Ders → Alıştırma hiyerarşisi. Ünite ve dersleri kurs detayından yönetin.',
            'model' => Course::class, 'search' => ['title'], 'showRoute' => 'admin.courses.show',
            'columns' => ['title' => 'Kurs', 'pair' => 'Dil çifti', 'level' => 'Seviye', 'units_count' => 'Ünite', 'lessons_count' => 'Ders', 'is_published' => 'Yayın'],
            'fields' => [
                'title' => ['label' => 'Kurs adı', 'rules' => 'required|string|max:120', 'wide' => true],
                'source_language_id' => ['label' => 'Ana dil (kaynak)', 'options' => $languages, 'rules' => 'required|exists:languages,id'],
                'target_language_id' => ['label' => 'Öğrenilen dil (hedef)', 'options' => $languages, 'rules' => 'required|exists:languages,id|different:source_language_id'],
                'level' => ['label' => 'Seviye', 'options' => array_combine(Course::LEVELS, Course::LEVELS), 'rules' => 'required|in:'.implode(',', Course::LEVELS)],
                'description' => ['label' => 'Açıklama', 'type' => 'textarea', 'rules' => 'nullable|string|max:1000'],
                'is_published' => ['label' => 'Yayında', 'type' => 'checkbox', 'rules' => 'boolean'],
            ],
        ];
    }

    protected function query()
    {
        return Course::with(['sourceLanguage', 'targetLanguage'])->withCount(['units', 'lessons']);
    }

    protected function cell(Model $item, string $key): string
    {
        return match ($key) {
            'pair' => e(($item->sourceLanguage->flag ?? '').' '.$item->sourceLanguage->name.' → '.($item->targetLanguage->flag ?? '').' '.$item->targetLanguage->name),
            'level' => '<span class="chip-primary">'.e($item->level).'</span>',
            'is_published' => $item->is_published ? '<span class="chip-ok">Yayında</span>' : '<span class="chip-muted">Taslak</span>',
            'title' => '<a class="font-semibold hover:text-primary" href="'.route('admin.courses.show', $item).'">'.e($item->title).'</a>',
            default => parent::cell($item, $key),
        };
    }

    public function show(Course $course): View
    {
        $course->load(['units' => fn ($q) => $q->with(['lessons' => fn ($l) => $l->withCount('exercises')])]);

        return view('admin.courses.show', compact('course'));
    }
}
