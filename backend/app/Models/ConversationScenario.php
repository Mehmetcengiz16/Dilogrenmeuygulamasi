<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ConversationScenario extends Model
{
    protected $fillable = [
        'language_id', 'title', 'description', 'icon', 'level', 'estimated_minutes',
        'opening_message', 'system_prompt', 'is_featured', 'order', 'is_active',
    ];

    protected $casts = ['is_featured' => 'boolean', 'is_active' => 'boolean'];

    public function language(): BelongsTo
    {
        return $this->belongsTo(Language::class);
    }
}
