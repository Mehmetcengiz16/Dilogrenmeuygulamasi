<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Badge;
use App\Models\DailyActivity;
use App\Services\ProgressService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class StatsController extends ApiController
{
    public function __invoke(Request $request, ProgressService $progress): JsonResponse
    {
        $user = $request->user();
        $from = Carbon::today()->subDays(6);
        $activities = DailyActivity::where('user_id', $user->id)->where('date', '>=', $from)
            ->get()->keyBy(fn ($a) => $a->date->toDateString());

        $history = [];
        for ($i = 0; $i < 7; $i++) {
            $d = $from->copy()->addDays($i)->toDateString();
            $history[] = ['date' => $d, 'xp' => $activities->get($d)?->xp ?? 0, 'minutes' => intdiv($activities->get($d)?->seconds ?? 0, 60)];
        }

        $owned = $user->badges()->get()->keyBy('id');

        return $this->ok([
            'total_xp' => $user->total_xp,
            'current_streak' => $progress->effectiveStreak($user),
            'longest_streak' => $user->longest_streak,
            'completed_lessons' => $user->lessonProgress()->where('status', 'completed')->count(),
            'learned_words' => $user->userWords()->count(),
            'xp_history' => $history,
            'badges' => Badge::orderBy('threshold')->get()->map(fn ($b) => [
                'code' => $b->code,
                'name' => $b->name,
                'description' => $b->description,
                'icon' => $b->icon,
                'earned' => $owned->has($b->id),
                'earned_at' => $owned->get($b->id)?->pivot->earned_at,
            ]),
        ]);
    }
}
