<?php

namespace App\Http\Controllers\Admin;

use App\Models\Language;
use Illuminate\Validation\Rule;

class LanguageController extends CrudController
{
    protected function config(): array
    {
        return [
            'title' => 'Diller', 'singular' => 'Dil', 'route' => 'admin.languages', 'icon' => 'language',
            'model' => Language::class, 'search' => ['name', 'code'], 'orderBy' => ['name' => 'asc'],
            'columns' => ['flag' => 'Bayrak', 'name' => 'Ad', 'code' => 'Kod', 'is_active' => 'Durum'],
            'fields' => [
                'name' => ['label' => 'Dil adı', 'rules' => 'required|string|max:60'],
                'code' => ['label' => 'ISO kodu (en, de, tr)', 'rules' => fn ($item) => ['required', 'string', 'max:8', Rule::unique('languages', 'code')->ignore($item)]],
                'flag' => ['label' => 'Bayrak emojisi', 'rules' => 'nullable|string|max:16', 'help' => 'Örn: 🇬🇧'],
                'is_active' => ['label' => 'Aktif', 'type' => 'checkbox', 'rules' => 'boolean', 'default' => true],
            ],
        ];
    }
}
