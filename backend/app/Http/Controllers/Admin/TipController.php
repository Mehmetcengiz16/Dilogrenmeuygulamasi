<?php

namespace App\Http\Controllers\Admin;

use App\Models\Tip;

class TipController extends CrudController
{
    protected function config(): array
    {
        return [
            'title' => 'Günün İpuçları', 'singular' => 'İpucu', 'route' => 'admin.tips', 'icon' => 'tips_and_updates',
            'subtitle' => 'Ana sayfadaki "Günün İpucu" kartında her gün sırayla biri gösterilir.',
            'model' => Tip::class, 'search' => ['text'],
            'columns' => ['text' => 'İpucu', 'is_active' => 'Durum'],
            'fields' => [
                'text' => ['label' => 'İpucu metni', 'type' => 'textarea', 'rules' => 'required|string|max:500'],
                'is_active' => ['label' => 'Aktif', 'type' => 'checkbox', 'rules' => 'boolean', 'default' => true],
            ],
        ];
    }
}
