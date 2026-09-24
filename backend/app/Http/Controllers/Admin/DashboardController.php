<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\DailyActivity;
use App\Models\Exercise;
use App\Models\Lesson;
use App\Models\LessonProgress;
use App\Models\User;
use App\Models\Word;
use Illuminate\Support\Carbon;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __invoke(): View
    {
        $from = Carbon::today()->subDays(29);

        $registrations = User::where('created_at', '>=', $from)
            ->selectRaw('DATE(created_at) as d, COUNT(*) as c')->groupBy('d')->pluck('c', 'd');
        $completions = LessonProgress::where('completed_at', '>=', $from)
            ->selectRaw('DATE(completed_at) as d, COUNT(*) as c')->groupBy('d')->pluck('c', 'd');

        $days = collect(range(0, 29))->map(function ($i) use ($from, $registrations, $completions) {
            $d = $from->copy()->addDays($i)->toDateString();

            return ['date' => $d, 'registrations' => (int) ($registrations[$d] ?? 0), 'lessons' => (int) ($completions[$d] ?? 0)];
        });

        return view('admin.dashboard', [
            'stats' => [
                ['Toplam kullanıcı', User::count(), 'group', 'bg-primary-fixed text-primary'],
                ['Aktif (7 gün)', DailyActivity::where('date', '>=', Carbon::today()->subDays(6))->distinct('user_id')->count('user_id'), 'bolt', 'bg-tertiary-fixed text-tertiary'],
                ['Tamamlanan ders', LessonProgress::where('status', 'completed')->count(), 'task_alt', 'bg-secondary-fixed text-secondary'],
                ['İçerik', Lesson::count().' ders · '.Exercise::count().' alıştırma · '.Word::count().' kelime', 'library_books', 'bg-surface-container text-on-surface-variant'],
            ],
            'days' => $days,
            'latestUsers' => User::latest()->limit(5)->get(),
            'aiEnabled' => app(\App\Services\AiService::class)->enabled(),
        ]);
    }
}
