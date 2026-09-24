<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ExerciseOption extends Model
{
    protected $fillable = ['exercise_id', 'text', 'translation', 'image_path', 'audio_path', 'is_correct', 'pair_key', 'order'];

    protected $casts = ['is_correct' => 'boolean'];

    public function exercise(): BelongsTo
    {
        return $this->belongsTo(Exercise::class);
    }
}
