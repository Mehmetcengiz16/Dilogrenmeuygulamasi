<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasManyThrough;
use Illuminate\Database\Eloquent\SoftDeletes;

class Course extends Model
{
    use SoftDeletes;

    public const LEVELS = ['A1', 'A2', 'B1', 'B2', 'C1'];

    protected $fillable = ['source_language_id', 'target_language_id', 'title', 'description', 'level', 'is_published'];

    protected $casts = ['is_published' => 'boolean'];

    public function sourceLanguage(): BelongsTo
    {
        return $this->belongsTo(Language::class, 'source_language_id');
    }

    public function targetLanguage(): BelongsTo
    {
        return $this->belongsTo(Language::class, 'target_language_id');
    }

    public function units(): HasMany
    {
        return $this->hasMany(Unit::class)->orderBy('order');
    }

    public function lessons(): HasManyThrough
    {
        return $this->hasManyThrough(Lesson::class, Unit::class);
    }

    public function scopePublished($query)
    {
        return $query->where('is_published', true);
    }

    /** Yayındaki dersleri ünite + ders sırasına göre döner. */
    public function orderedPublishedLessons()
    {
        return Lesson::query()
            ->select('lessons.*')
            ->join('units', 'units.id', '=', 'lessons.unit_id')
            ->where('units.course_id', $this->id)
            ->where('units.is_published', true)
            ->where('lessons.is_published', true)
            ->whereNull('units.deleted_at')
            ->orderBy('units.order')->orderBy('lessons.order')->orderBy('lessons.id')
            ->get();
    }
}
