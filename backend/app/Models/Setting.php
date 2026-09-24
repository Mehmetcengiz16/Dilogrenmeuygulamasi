<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Crypt;

/** Admin panelden düzenlenen ayarlar. Gizli değerler (API anahtarları) APP_KEY ile şifrelenir. */
class Setting extends Model
{
    protected $primaryKey = 'key';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = ['key', 'value', 'is_encrypted'];

    protected $casts = ['is_encrypted' => 'boolean'];

    private const CACHE_KEY = 'app_settings';

    public static function get(string $key, mixed $default = null): mixed
    {
        $all = Cache::rememberForever(self::CACHE_KEY, fn () => static::all()->mapWithKeys(fn (Setting $s) => [
            $s->key => $s->is_encrypted && $s->value !== null ? Crypt::decryptString($s->value) : $s->value,
        ])->all());

        $value = $all[$key] ?? null;

        return $value === null || $value === '' ? $default : $value;
    }

    public static function set(string $key, ?string $value, bool $encrypted = false): void
    {
        static::updateOrCreate(['key' => $key], [
            'value' => $encrypted && $value !== null && $value !== '' ? Crypt::encryptString($value) : $value,
            'is_encrypted' => $encrypted,
        ]);
        Cache::forget(self::CACHE_KEY);
    }
}
