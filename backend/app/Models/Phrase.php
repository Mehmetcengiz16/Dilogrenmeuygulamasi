<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Phrase extends Model
{
    public const TYPES = ['quick' => 'Hızlı kalıp', 'idiom' => 'Deyim'];

    protected $fillable = ['language_id', 'type', 'text', 'translation', 'emoji', 'pronunciation', 'image_path', 'order', 'is_active'];

    protected $casts = ['is_active' => 'boolean'];

    public function language(): BelongsTo
    {
        return $this->belongsTo(Language::class);
    }
}
