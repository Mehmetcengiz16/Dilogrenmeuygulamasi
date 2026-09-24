<?php

namespace App\Services;

use App\Models\Badge;
use App\Models\Course;
use App\Models\DailyActivity;
use App\Models\Lesson;
use App\Models\LessonProgress;
use App\Models\User;
use App\Models\UserCourse;
use App\Models\UserWord;
use App\Models\XpLog;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class ProgressService
{
    /** Kursa kaydolur (veya aktif kurs yapar) ve ilk dersi açar. */
    public function enroll(User $user, Course $course): UserCourse
    {
        return DB::transaction(function () use ($user, $course) {
            $user->userCourses()->where('course_id', '!=', $course->id)->update(['is_active' => false]);

            $userCourse = UserCourse::firstOrNew(['user_id' => $user->id, 'course_id' => $course->id]);
            $userCourse->is_active = true;
            $userCourse->started_at ??= now();

            if (! $userCourse->current_lesson_id) {
                $first = $course->orderedPublishedLessons()->first();
                $userCourse->current_lesson_id = $first?->id;
                if ($first) {
                    LessonProgress::firstOrCreate(
                        ['user_id' => $user->id, 'lesson_id' => $first->id],
                        ['status' => 'unlocked'],
                    );
                }
            }
            $userCourse->save();

            return $userCourse;
        });
    }

    /** Kullanıcı için dersin durumunu döner: locked / unlocked / completed. */
    public function statusMap(User $user, Course $course): array
    {
        $lessons = $course->orderedPublishedLessons();
        $progress = LessonProgress::where('user_id', $user->id)
            ->whereIn('lesson_id', $lessons->pluck('id'))
            ->get()->keyBy('lesson_id');

        $map = [];
        $previousCompleted = true;
        foreach ($lessons as $lesson) {
            $p = $progress->get($lesson->id);
            $status = $p?->status ?? ($previousCompleted ? 'unlocked' : 'locked');
            $map[$lesson->id] = ['status' => $status, 'score' => $p?->score ?? 0];
            $previousCompleted = $status === 'completed';
        }

        return $map;
    }

    public function canAccess(User $user, Lesson $lesson): bool
    {
        $course = $lesson->unit->course;
        $map = $this->statusMap($user, $course);

        return ($map[$lesson->id]['status'] ?? 'locked') !== 'locked';
    }

    /**
     * Ders sonucunu işler. XP ve puan sunucuda hesaplanır; istemciden gelen XP'ye güvenilmez.
     *
     * @param  array<int, array{exercise_id:int, is_correct:bool}>  $answers
     */
    public function completeLesson(User $user, Lesson $lesson, array $answers, int $durationSeconds): array
    {
        return DB::transaction(function () use ($user, $lesson, $answers, $durationSeconds) {
            $exercises = $lesson->exercises()->get()->keyBy('id');
            $answerMap = collect($answers)->keyBy('exercise_id');

            $correct = 0;
            $exerciseXp = 0;
            foreach ($exercises as $exercise) {
                if ((bool) ($answerMap->get($exercise->id)['is_correct'] ?? false)) {
                    $correct++;
                    $exerciseXp += $exercise->xp;
                }
            }
            $total = max($exercises->count(), 1);
            $mistakes = $exercises->count() - $correct;
            $score = (int) round($correct / $total * 100);

            $progress = LessonProgress::firstOrNew(['user_id' => $user->id, 'lesson_id' => $lesson->id]);
            $firstCompletion = $progress->status !== 'completed';

            // Tekrar oynanan derste XP'nin yarısı verilir.
            $xp = $exerciseXp + ($score >= 50 ? $lesson->xp_reward : 0);
            if (! $firstCompletion) {
                $xp = intdiv($xp, 2);
            }

            $progress->fill([
                'status' => 'completed',
                'score' => max($progress->score ?? 0, $score),
                'mistakes' => $mistakes,
                'attempts' => ($progress->attempts ?? 0) + 1,
                'completed_at' => now(),
            ])->save();

            $this->addXp($user, $xp, 'lesson');
            $streak = $this->recordActivity($user, min($durationSeconds, 3 * 3600), $xp, 1);

            $nextLesson = $this->unlockNext($user, $lesson);
            $this->learnWords($user, $lesson);
            $newBadges = $this->checkBadges($user->fresh());

            return [
                'score' => $score,
                'correct' => $correct,
                'total' => $exercises->count(),
                'xp_earned' => $xp,
                'total_xp' => $user->fresh()->total_xp,
                'streak' => $streak,
                'next_lesson_id' => $nextLesson?->id,
                'new_badges' => $newBadges,
            ];
        });
    }

    public function addXp(User $user, int $amount, string $source): void
    {
        if ($amount <= 0) {
            return;
        }
        XpLog::create(['user_id' => $user->id, 'amount' => $amount, 'source' => $source]);
        $user->increment('total_xp', $amount);
    }

    /** Günlük aktiviteyi kaydeder ve seriyi günceller. Güncel seriyi döner. */
    public function recordActivity(User $user, int $seconds, int $xp = 0, int $lessons = 0): int
    {
        $today = Carbon::today();
        $activity = DailyActivity::firstOrCreate(['user_id' => $user->id, 'date' => $today->toDateString()]);
        $activity->increment('seconds', $seconds);
        $activity->increment('xp', $xp);
        $activity->increment('lessons_completed', $lessons);

        $last = $user->last_activity_date;
        if (! $last || ! $last->isSameDay($today)) {
            $user->current_streak = $last && $last->isSameDay($today->copy()->subDay())
                ? $user->current_streak + 1
                : 1;
            $user->longest_streak = max($user->longest_streak, $user->current_streak);
            $user->last_activity_date = $today;
            $user->save();
        }

        return $user->current_streak;
    }

    /** Dün aktivite yoksa seri kırılmıştır; okuma anında düzeltilir. */
    public function effectiveStreak(User $user): int
    {
        $last = $user->last_activity_date;
        if (! $last || $last->lt(Carbon::yesterday())) {
            return 0;
        }

        return $user->current_streak;
    }

    private function unlockNext(User $user, Lesson $lesson): ?Lesson
    {
        $course = $lesson->unit->course;
        $lessons = $course->orderedPublishedLessons();
        $index = $lessons->search(fn ($l) => $l->id === $lesson->id);
        $next = $index === false ? null : $lessons->get($index + 1);

        if ($next) {
            LessonProgress::firstOrCreate(
                ['user_id' => $user->id, 'lesson_id' => $next->id],
                ['status' => 'unlocked'],
            );
        }

        UserCourse::where('user_id', $user->id)->where('course_id', $course->id)
            ->update(['current_lesson_id' => $next?->id ?? $lesson->id]);

        return $next;
    }

    private function learnWords(User $user, Lesson $lesson): void
    {
        foreach ($lesson->words()->pluck('words.id') as $wordId) {
            UserWord::firstOrCreate(
                ['user_id' => $user->id, 'word_id' => $wordId],
                ['strength' => 1, 'next_review_at' => now()->addDay()],
            );
        }
    }

    /** @return array<int, array{code:string, name:string}> */
    private function checkBadges(User $user): array
    {
        $owned = $user->badges()->pluck('badges.id')->all();
        $earned = [];

        foreach (Badge::whereNotIn('id', $owned)->get() as $badge) {
            $value = match ($badge->rule) {
                'xp' => $user->total_xp,
                'streak' => $user->current_streak,
                'lessons' => $user->lessonProgress()->where('status', 'completed')->count(),
                'words' => $user->userWords()->count(),
                default => 0,
            };
            if ($value >= $badge->threshold) {
                $user->badges()->attach($badge->id, ['earned_at' => now()]);
                $earned[] = ['code' => $badge->code, 'name' => $badge->name, 'icon' => $badge->icon];
            }
        }

        return $earned;
    }
}
