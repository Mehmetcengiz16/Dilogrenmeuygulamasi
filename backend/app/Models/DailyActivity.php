<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DailyActivity extends Model
{
    protected $fillable = ['user_id', 'date', 'seconds', 'xp', 'lessons_completed'];

    protected $casts = ['date' => 'date'];

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
}
