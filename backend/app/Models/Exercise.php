<?php

namespace App\Models;

use App\Enums\ExerciseType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Exercise extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'lesson_id', 'type', 'category', 'instruction', 'prompt', 'prompt_translation',
        'correct_answer', 'explanation', 'audio_path', 'image_path', 'xp', 'order',
    ];

    protected $casts = [
        'type' => ExerciseType::class,
        'correct_answer' => 'array',
    ];

    public function lesson(): BelongsTo
    {
        return $this->belongsTo(Lesson::class);
    }

    public function options(): HasMany
    {
        return $this->hasMany(ExerciseOption::class)->orderBy('order');
    }
}
