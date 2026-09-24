<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\ConversationScenario;
use App\Models\DailyActivity;
use App\Models\Tip;
use App\Models\Word;
use App\Services\ProgressService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/** Ana sayfa (ana_sayfa_ke_fet tasarımı) için tek istekte gereken tüm veri. */
class HomeController extends ApiController
{
    public function __invoke(Request $request, ProgressService $progress): JsonResponse
    {
        $user = $request->user();
        $userCourse = $user->activeUserCourse();
        $course = $userCourse?->course;
        $today = Carbon::today();
        $dayOfYear = (int) $today->format('z');

        // Haftalık takip: Pazartesi–Pazar
        $weekStart = $today->copy()->startOfWeek(Carbon::MONDAY);
        $activities = DailyActivity::where('user_id', $user->id)
            ->where('date', '>=', $weekStart->copy()->subWeek())
            ->get()->keyBy(fn ($a) => $a->date->toDateString());

        $todaySeconds = $activities->get($today->toDateString())?->seconds ?? 0;
        $goalSeconds = max($user->daily_goal_minutes, 1) * 60;
        $dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        $week = [];
        for ($i = 0; $i < 7; $i++) {
            $date = $weekStart->copy()->addDays($i);
            $week[] = [
                'label' => $dayNames[$i],
                'date' => $date->toDateString(),
                'done' => ($activities->get($date->toDateString())?->seconds ?? 0) > 0,
                'is_today' => $date->isSameDay($today),
            ];
        }

        $thisWeek = $activities->filter(fn ($a) => $a->date->gte($weekStart))->sum('seconds');
        $lastWeek = $activities->filter(fn ($a) => $a->date->lt($weekStart))->sum('seconds');
        $totalSeconds = DailyActivity::where('user_id', $user->id)->sum('seconds');

        $completed = $user->lessonProgress()->where('status', 'completed')->count();
        $courseLessons = $course ? $course->orderedPublishedLessons() : collect();
        $courseCompleted = $course
            ? $user->lessonProgress()->where('status', 'completed')->whereIn('lesson_id', $courseLessons->pluck('id'))->count()
            : 0;

        $current = $userCourse?->currentLesson;
        $currentNumber = $current ? $courseLessons->search(fn ($l) => $l->id === $current->id) + 1 : null;

        $targetLang = $course?->targetLanguage;
        $scenario = ConversationScenario::where('is_active', true)
            ->when($targetLang, fn ($q) => $q->where('language_id', $targetLang->id))
            ->orderByDesc('is_featured')->orderBy('order')->get();
        $featured = $scenario->isNotEmpty() ? $scenario[$dayOfYear % $scenario->count()] : null;

        $words = Word::when($targetLang, fn ($q) => $q->where('language_id', $targetLang->id))->orderBy('id')->get(['id', 'word', 'translation']);
        $wordOfDay = $words->isNotEmpty() ? $words[$dayOfYear % $words->count()] : null;

        $tips = Tip::where('is_active', true)->orderBy('id')->get(['text']);
        $tip = $tips->isNotEmpty() ? $tips[$dayOfYear % $tips->count()]->text : null;

        return $this->ok([
            'user' => [
                'name' => $user->name,
                'avatar_url' => $user->avatarUrl(),
                'streak' => $progress->effectiveStreak($user),
            ],
            'course' => $course ? [
                'id' => $course->id,
                'title' => $course->title,
                'level' => $course->level,
                'target_language' => $targetLang?->name,
            ] : null,
            'daily_goal' => [
                'goal_minutes' => $user->daily_goal_minutes,
                'done_minutes' => intdiv($todaySeconds, 60),
                'remaining_minutes' => max(0, intdiv($goalSeconds - $todaySeconds + 59, 60)),
                'percent' => min(100, (int) round($todaySeconds / $goalSeconds * 100)),
            ],
            'metrics' => [
                'total_hours' => round($totalSeconds / 3600, 1),
                'hours_change_percent' => $lastWeek > 0 ? (int) round(($thisWeek - $lastWeek) / $lastWeek * 100) : null,
                'completed_lessons' => $completed,
                'course_completed' => $courseCompleted,
                'course_total' => $courseLessons->count(),
            ],
            'week' => $week,
            'current_lesson' => $current ? [
                'id' => $current->id,
                'number' => $currentNumber,
                'title' => $current->title,
                'description' => $current->description,
                'skill' => $current->skill,
                'estimated_minutes' => $current->estimated_minutes,
            ] : null,
            'featured_scenario' => $featured ? [
                'id' => $featured->id,
                'title' => $featured->title,
                'description' => $featured->description,
                'estimated_minutes' => $featured->estimated_minutes,
                'icon' => $featured->icon,
            ] : null,
            'word_of_day' => $wordOfDay,
            'tip' => $tip,
        ]);
    }
}
