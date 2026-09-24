<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatMessage extends Model
{
    protected $fillable = ['user_id', 'scenario_id', 'role', 'content'];

    protected $casts = [];

    public function user(): BelongsTo { return $this->belongsTo(User::class); }

    public function scenario(): BelongsTo { return $this->belongsTo(ConversationScenario::class, 'scenario_id'); }
}
