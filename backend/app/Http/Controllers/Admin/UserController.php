<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\ProgressService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class UserController extends Controller
{
    public function index(Request $request): View
    {
        $users = User::query()
            ->withCount(['lessonProgress as completed_count' => fn ($q) => $q->where('status', 'completed')])
            ->when($request->filled('q'), fn ($q) => $q->where(fn ($w) => $w
                ->where('name', 'like', '%'.$request->q.'%')
                ->orWhere('email', 'like', '%'.$request->q.'%')))
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->status))
            ->latest()->paginate(25)->withQueryString();

        return view('admin.users.index', compact('users'));
    }

    public function show(User $user, ProgressService $progress): View
    {
        $user->load(['userCourses.course', 'badges']);
        $recent = $user->lessonProgress()->with('lesson.unit')->where('status', 'completed')->latest('completed_at')->limit(10)->get();
        $activity = $user->dailyActivities()->latest('date')->limit(14)->get()->reverse()->values();

        return view('admin.users.show', [
            'user' => $user,
            'streak' => $progress->effectiveStreak($user),
            'recent' => $recent,
            'activity' => $activity,
            'wordCount' => $user->userWords()->count(),
        ]);
    }

    public function toggleStatus(User $user): RedirectResponse
    {
        $suspend = $user->status === 'active';
        $user->update(['status' => $suspend ? 'suspended' : 'active']);
        if ($suspend) {
            $user->tokens()->delete();
        }

        return back()->with('status', $suspend ? 'Hesap donduruldu' : 'Hesap yeniden aktif edildi');
    }
}
