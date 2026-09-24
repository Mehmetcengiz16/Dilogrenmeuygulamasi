<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Badge extends Model
{
    protected $fillable = ['code', 'name', 'description', 'icon', 'rule', 'threshold'];

    protected $casts = [];
}
