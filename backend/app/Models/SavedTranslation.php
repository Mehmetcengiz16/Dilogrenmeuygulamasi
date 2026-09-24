<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SavedTranslation extends Model
{
    protected $fillable = ['user_id', 'source_lang', 'target_lang', 'source_text', 'translated_text', 'pronunciation', 'is_favorite'];

    protected $casts = ['is_favorite' => 'boolean'];

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
}
