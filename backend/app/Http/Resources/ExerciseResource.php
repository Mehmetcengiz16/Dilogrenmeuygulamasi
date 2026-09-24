<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class ExerciseResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type->value,
            'category' => $this->category,
            'instruction' => $this->instruction,
            'prompt' => $this->prompt,
            'prompt_translation' => $this->prompt_translation,
            'correct_answer' => $this->correct_answer,
            'explanation' => $this->explanation,
            'audio_url' => self::url($this->audio_path),
            'image_url' => self::url($this->image_path),
            'xp' => $this->xp,
            'options' => $this->options->map(fn ($o) => [
                'id' => $o->id,
                'text' => $o->text,
                'translation' => $o->translation,
                'image_url' => self::url($o->image_path),
                'audio_url' => self::url($o->audio_path),
                'is_correct' => $o->is_correct,
                'pair_key' => $o->pair_key,
            ])->values(),
        ];
    }

    public static function url(?string $path): ?string
    {
        if (! $path) {
            return null;
        }

        return str_starts_with($path, 'http') ? $path : Storage::disk('public')->url($path);
    }
}
