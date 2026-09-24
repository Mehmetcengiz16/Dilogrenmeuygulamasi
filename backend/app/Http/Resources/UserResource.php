<?php

namespace App\Http\Resources;

use App\Services\ProgressService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $active = $this->activeUserCourse();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'avatar_url' => $this->avatarUrl(),
            'daily_goal_minutes' => $this->daily_goal_minutes,
            'total_xp' => $this->total_xp,
            'current_streak' => app(ProgressService::class)->effectiveStreak($this->resource),
            'longest_streak' => $this->longest_streak,
            'active_course' => $active ? [
                'id' => $active->course->id,
                'title' => $active->course->title,
                'level' => $active->course->level,
            ] : null,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
