<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;

class Admin extends Authenticatable
{
    public const ROLE_SUPER = 'super_admin';
    public const ROLE_EDITOR = 'editor';

    protected $fillable = ['name', 'email', 'password', 'role'];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return ['password' => 'hashed'];
    }

    public function isSuper(): bool
    {
        return $this->role === self::ROLE_SUPER;
    }
}
