<?php

namespace App\Http\Controllers\Admin;

use App\Models\Language;
use App\Models\Phrase;
use Illuminate\Database\Eloquent\Model;

/** Çeviri ekranındaki "Hızlı Kalıplar" ve "Günün Deyimi". */
class PhraseController extends CrudController
{
    protected function config(): array
    {
        return [
            'title' => 'Kalıplar ve Deyimler', 'singular' => 'Kalıp', 'route' => 'admin.phrases', 'icon' => 'translate',
            'subtitle' => 'Çeviri ekranındaki hızlı kalıp çipleri ve günün deyimi kartı buradan beslenir.',
            'model' => Phrase::class, 'search' => ['text', 'translation'], 'orderBy' => ['type' => 'desc', 'order' => 'asc'],
            'columns' => ['emoji' => '', 'text' => 'Metin', 'translation' => 'Çeviri', 'type' => 'Tür', 'language.name' => 'Dil', 'is_active' => 'Durum'],
            'fields' => [
                'language_id' => ['label' => 'Dil', 'options' => Language::pluck('name', 'id')->all(), 'rules' => 'required|exists:languages,id'],
                'type' => ['label' => 'Tür', 'options' => Phrase::TYPES, 'rules' => 'required|in:quick,idiom'],
                'text' => ['label' => 'Metin (hedef dil)', 'rules' => 'required|string|max:255'],
                'translation' => ['label' => 'Türkçe karşılığı', 'rules' => 'required|string|max:255'],
                'emoji' => ['label' => 'Emoji', 'rules' => 'nullable|string|max:16'],
                'pronunciation' => ['label' => 'Okunuş', 'rules' => 'nullable|string|max:255', 'help' => 'Örn: /me-ra-ba/'],
                'image' => ['label' => 'Görsel (deyim kartı)', 'type' => 'file', 'column' => 'image_path', 'store' => 'images', 'accept' => 'image/*', 'rules' => 'nullable|image|max:1024'],
                'order' => ['label' => 'Sıra', 'type' => 'number', 'rules' => 'nullable|integer|min:0', 'default' => 0],
                'is_active' => ['label' => 'Aktif', 'type' => 'checkbox', 'rules' => 'boolean', 'default' => true],
            ],
        ];
    }

    protected function query()
    {
        return Phrase::with('language');
    }

    protected function cell(Model $item, string $key): string
    {
        return $key === 'type'
            ? '<span class="chip-primary">'.e(Phrase::TYPES[$item->type] ?? $item->type).'</span>'
            : parent::cell($item, $key);
    }
}
