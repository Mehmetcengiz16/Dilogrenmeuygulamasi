<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class XpLog extends Model
{
    protected $fillable = ['user_id', 'amount', 'source'];

    protected $casts = [];

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
}
