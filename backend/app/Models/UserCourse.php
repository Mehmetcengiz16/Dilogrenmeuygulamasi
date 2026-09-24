<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserCourse extends Model
{
    protected $fillable = ['user_id', 'course_id', 'current_lesson_id', 'started_at', 'is_active'];

    protected $casts = ['started_at' => 'datetime', 'is_active' => 'boolean'];

    public function user(): BelongsTo { return $this->belongsTo(User::class); }

    public function course(): BelongsTo { return $this->belongsTo(Course::class); }

    public function currentLesson(): BelongsTo { return $this->belongsTo(Lesson::class, 'current_lesson_id'); }
}
