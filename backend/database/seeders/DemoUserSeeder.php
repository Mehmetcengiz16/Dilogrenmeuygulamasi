<?php

namespace Database\Seeders;

use App\Models\Course;
use App\Models\DailyActivity;
use App\Models\Language;
use App\Models\LessonProgress;
use App\Models\User;
use App\Models\UserCourse;
use App\Models\UserWord;
use App\Models\XpLog;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

/** Ana sayfa tasarımındaki durumu yansıtan demo kullanıcı: 10 ders, 7 günlük seri. */
class DemoUserSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::create([
            'name' => 'Selin',
            'email' => 'selin@linguaai.test',
            'password' => 'password',
            'native_language_id' => Language::where('code', 'tr')->value('id'),
            'daily_goal_minutes' => 15,
        ]);

        $course = Course::first();
        $lessons = $course->orderedPublishedLessons();
        $completed = $lessons->take(10);

        foreach ($completed as $i => $lesson) {
            LessonProgress::create([
                'user_id' => $user->id, 'lesson_id' => $lesson->id, 'status' => 'completed',
                'score' => 80 + ($i * 3) % 20, 'attempts' => 1, 'completed_at' => now()->subDays(10 - $i),
            ]);
            foreach ($lesson->words as $word) {
                UserWord::create(['user_id' => $user->id, 'word_id' => $word->id, 'strength' => 2, 'next_review_at' => now()->addDays($i % 3 - 1)]);
            }
        }
        $next = $lessons->get(10);
        LessonProgress::create(['user_id' => $user->id, 'lesson_id' => $next->id, 'status' => 'unlocked']);
        UserCourse::create([
            'user_id' => $user->id, 'course_id' => $course->id, 'current_lesson_id' => $lessons->last()->id,
            'started_at' => now()->subDays(14), 'is_active' => true,
        ]);
        // Tasarımdaki "Ders #14 – İngilizce Dinleme ve Telaffuz" kartı için son dersi de aç.
        LessonProgress::create(['user_id' => $user->id, 'lesson_id' => $lessons->last()->id, 'status' => 'unlocked']);

        // Son iki hafta aktivite: dün dahil 6 gün + bugün %80 hedef = 7 günlük seri.
        $totalXp = 0;
        for ($d = 13; $d >= 0; $d--) {
            if ($d > 6 && $d % 3 === 0) {
                continue;
            }
            $seconds = $d === 0 ? 12 * 60 : (10 + $d % 4 * 3) * 60;
            $xp = $d === 0 ? 40 : 60;
            DailyActivity::create([
                'user_id' => $user->id, 'date' => Carbon::today()->subDays($d)->toDateString(),
                'seconds' => $seconds, 'xp' => $xp, 'lessons_completed' => 1,
            ]);
            XpLog::create(['user_id' => $user->id, 'amount' => $xp, 'source' => 'lesson', 'created_at' => Carbon::today()->subDays($d)]);
            $totalXp += $xp;
        }

        $user->update([
            'total_xp' => $totalXp,
            'current_streak' => 7,
            'longest_streak' => 9,
            'last_activity_date' => Carbon::today(),
        ]);
    }
}
