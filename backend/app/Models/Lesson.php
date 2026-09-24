<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Lesson extends Model
{
    use SoftDeletes;

    public const TYPES = ['standard' => 'Standart', 'review' => 'Tekrar', 'test' => 'Test'];

    public const SKILLS = [
        'vocabulary' => 'Kelime',
        'listening' => 'Dinleme',
        'speaking' => 'Konuşma',
        'grammar' => 'Dil Bilgisi',
    ];

    protected $fillable = [
        'unit_id', 'title', 'description', 'type', 'skill', 'xp_reward',
        'estimated_minutes', 'time_limit_seconds', 'order', 'is_published',
    ];

    protected $casts = ['is_published' => 'boolean'];

    public function unit(): BelongsTo
    {
        return $this->belongsTo(Unit::class);
    }

    public function exercises(): HasMany
    {
        return $this->hasMany(Exercise::class)->orderBy('order');
    }

    public function words(): BelongsToMany
    {
        return $this->belongsToMany(Word::class, 'lesson_word');
    }
}
