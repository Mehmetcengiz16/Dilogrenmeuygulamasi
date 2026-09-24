<?php

namespace App\Http\Controllers\Admin;

use App\Models\ConversationScenario;
use App\Models\Course;
use App\Models\Language;
use Illuminate\Database\Eloquent\Model;

/** AI Konuşma Asistanı ekranındaki "Önerilen Konuşma Kalıpları" ve ana sayfadaki pratik kartı. */
class ScenarioController extends CrudController
{
    protected function config(): array
    {
        return [
            'title' => 'AI Senaryoları', 'singular' => 'Senaryo', 'route' => 'admin.scenarios', 'icon' => 'smart_toy',
            'subtitle' => 'Öne çıkan senaryo ana sayfadaki "Akıcı Konuşma Pratiği" kartında gösterilir.',
            'model' => ConversationScenario::class, 'search' => ['title'], 'orderBy' => ['order' => 'asc'],
            'columns' => ['icon' => 'İkon', 'title' => 'Başlık', 'level' => 'Seviye', 'estimated_minutes' => 'Süre (dk)', 'is_featured' => 'Öne çıkan', 'is_active' => 'Durum'],
            'fields' => [
                'language_id' => ['label' => 'Dil', 'options' => Language::pluck('name', 'id')->all(), 'rules' => 'required|exists:languages,id'],
                'title' => ['label' => 'Başlık', 'rules' => 'required|string|max:120'],
                'description' => ['label' => 'Kısa açıklama', 'rules' => 'nullable|string|max:255', 'wide' => true],
                'icon' => ['label' => 'Material ikon adı', 'rules' => 'required|string|max:32', 'default' => 'forum', 'help' => 'Örn: restaurant, flight_takeoff, work'],
                'level' => ['label' => 'Seviye', 'options' => array_combine(Course::LEVELS, Course::LEVELS), 'rules' => 'required'],
                'estimated_minutes' => ['label' => 'Tahmini süre (dk)', 'type' => 'number', 'rules' => 'required|integer|min:1', 'default' => 15],
                'order' => ['label' => 'Sıra', 'type' => 'number', 'rules' => 'nullable|integer|min:0', 'default' => 0],
                'opening_message' => ['label' => 'Açılış mesajı (Lina AI)', 'type' => 'textarea', 'rules' => 'required|string|max:1000'],
                'system_prompt' => ['label' => 'Senaryo talimatı (AI için, İngilizce önerilir)', 'type' => 'textarea', 'rules' => 'nullable|string|max:2000'],
                'is_featured' => ['label' => 'Öne çıkan', 'type' => 'checkbox', 'rules' => 'boolean'],
                'is_active' => ['label' => 'Aktif', 'type' => 'checkbox', 'rules' => 'boolean', 'default' => true],
            ],
        ];
    }

    protected function cell(Model $item, string $key): string
    {
        if ($key === 'icon') {
            return '<span class="flex h-9 w-9 items-center justify-center rounded-full bg-primary-fixed text-primary"><span class="material-symbols-outlined text-[20px]">'.e($item->icon).'</span></span>';
        }
        if ($key === 'is_featured') {
            return $item->is_featured ? '<span class="chip-primary">Öne çıkan</span>' : '';
        }

        return parent::cell($item, $key);
    }
}
