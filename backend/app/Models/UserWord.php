<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserWord extends Model
{
    protected $fillable = ['user_id', 'word_id', 'strength', 'next_review_at', 'is_favorite'];

    protected $casts = ['next_review_at' => 'datetime', 'is_favorite' => 'boolean'];

    public function user(): BelongsTo { return $this->belongsTo(User::class); }

    public function word(): BelongsTo { return $this->belongsTo(Word::class); }
}
