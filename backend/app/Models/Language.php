<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Language extends Model
{
    protected $fillable = ['code', 'name', 'flag', 'is_active'];

    protected $casts = ['is_active' => 'boolean'];

    public function words(): HasMany
    {
        return $this->hasMany(Word::class);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
