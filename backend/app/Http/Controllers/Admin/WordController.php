<?php

namespace App\Http\Controllers\Admin;

use App\Models\Course;
use App\Models\Language;
use App\Models\Word;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class WordController extends CrudController
{
    protected function config(): array
    {
        return [
            'title' => 'Kelime Bankası', 'singular' => 'Kelime', 'route' => 'admin.words', 'icon' => 'menu_book',
            'subtitle' => 'Ana sayfadaki "Günün Sözü", kelime defteri ve çeviri sözlüğü buradan beslenir.',
            'model' => Word::class, 'search' => ['word', 'translation'], 'orderBy' => ['word' => 'asc'],
            'columns' => ['word' => 'Kelime', 'translation' => 'Çeviri', 'language.name' => 'Dil', 'level' => 'Seviye', 'example_sentence' => 'Örnek cümle'],
            'extraActions' => [['url' => route('admin.words.import'), 'icon' => 'upload_file', 'label' => 'CSV İçe Aktar']],
            'fields' => [
                'language_id' => ['label' => 'Dil', 'options' => Language::pluck('name', 'id')->all(), 'rules' => 'required|exists:languages,id'],
                'level' => ['label' => 'Seviye', 'options' => array_combine(Course::LEVELS, Course::LEVELS), 'rules' => 'required'],
                'word' => ['label' => 'Kelime', 'rules' => 'required|string|max:255'],
                'translation' => ['label' => 'Çeviri', 'rules' => 'required|string|max:255'],
                'pronunciation' => ['label' => 'Okunuş', 'rules' => 'nullable|string|max:255'],
                'example_sentence' => ['label' => 'Örnek cümle', 'type' => 'textarea', 'rules' => 'nullable|string|max:500'],
                'example_translation' => ['label' => 'Örnek cümlenin çevirisi', 'type' => 'textarea', 'rules' => 'nullable|string|max:500'],
                'audio' => ['label' => 'Telaffuz sesi (mp3/m4a, en fazla 2 MB)', 'type' => 'file', 'column' => 'audio_path', 'store' => 'audio', 'accept' => 'audio/*', 'rules' => 'nullable|file|mimes:mp3,m4a,mp4,aac|max:2048'],
                'image' => ['label' => 'Görsel (en fazla 1 MB)', 'type' => 'file', 'column' => 'image_path', 'store' => 'images', 'accept' => 'image/*', 'rules' => 'nullable|image|max:1024'],
            ],
        ];
    }

    protected function query()
    {
        return Word::with('language');
    }

    public function importForm(): View
    {
        return view('admin.words.import', ['languages' => Language::pluck('name', 'id')]);
    }

    /** CSV biçimi: word,translation,example_sentence,example_translation,level (ilk satır başlık). */
    public function import(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'language_id' => 'required|exists:languages,id',
            'csv' => 'required|file|mimes:csv,txt|max:2048',
        ]);

        $handle = fopen($request->file('csv')->getRealPath(), 'r');
        $header = array_map(fn ($h) => strtolower(trim($h, " \t\n\r\0\x0B\u{FEFF}")), fgetcsv($handle) ?: []);
        if (! in_array('word', $header) || ! in_array('translation', $header)) {
            return back()->withErrors(['csv' => 'CSV başlığında en az "word" ve "translation" sütunları olmalı.']);
        }

        $created = 0;
        $updated = 0;
        while (($row = fgetcsv($handle)) !== false) {
            if (count($row) !== count($header)) {
                continue;
            }
            $r = array_combine($header, $row);
            if (blank($r['word']) || blank($r['translation'])) {
                continue;
            }
            $word = Word::updateOrCreate(
                ['language_id' => $data['language_id'], 'word' => trim($r['word'])],
                array_filter([
                    'translation' => trim($r['translation']),
                    'example_sentence' => $r['example_sentence'] ?? null,
                    'example_translation' => $r['example_translation'] ?? null,
                    'level' => in_array($r['level'] ?? '', Course::LEVELS) ? $r['level'] : null,
                ], fn ($v) => $v !== null && $v !== ''),
            );
            $word->wasRecentlyCreated ? $created++ : $updated++;
        }
        fclose($handle);

        return redirect()->route('admin.words.index')->with('status', "{$created} kelime eklendi, {$updated} kelime güncellendi");
    }
}
