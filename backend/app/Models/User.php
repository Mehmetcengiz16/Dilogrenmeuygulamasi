<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $fillable = [
        'name', 'email', 'password', 'avatar_path', 'native_language_id', 'daily_goal_minutes',
        'total_xp', 'current_streak', 'longest_streak', 'last_activity_date', 'status',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'last_activity_date' => 'date',
            'password' => 'hashed',
        ];
    }

    public function avatarUrl(): ?string
    {
        return $this->avatar_path ? Storage::disk('public')->url($this->avatar_path) : null;
    }

    public function nativeLanguage(): BelongsTo
    {
        return $this->belongsTo(Language::class, 'native_language_id');
    }

    public function userCourses(): HasMany
    {
        return $this->hasMany(UserCourse::class);
    }

    public function activeUserCourse(): ?UserCourse
    {
        return $this->userCourses()->where('is_active', true)->with('course')->first();
    }

    public function lessonProgress(): HasMany
    {
        return $this->hasMany(LessonProgress::class);
    }

    public function userWords(): HasMany
    {
        return $this->hasMany(UserWord::class);
    }

    public function xpLogs(): HasMany
    {
        return $this->hasMany(XpLog::class);
    }

    public function dailyActivities(): HasMany
    {
        return $this->hasMany(DailyActivity::class);
    }

    public function badges(): BelongsToMany
    {
        return $this->belongsToMany(Badge::class, 'user_badges')->withPivot('earned_at');
    }

    public function savedTranslations(): HasMany
    {
        return $this->hasMany(SavedTranslation::class);
    }

    public function chatMessages(): HasMany
    {
        return $this->hasMany(ChatMessage::class);
    }
}
