<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Course;
use App\Models\Language;
use App\Services\ProgressService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CourseController extends ApiController
{
    public function __construct(private ProgressService $progress) {}

    public function languages(): JsonResponse
    {
        return $this->ok(Language::active()->orderBy('name')->get(['id', 'code', 'name', 'flag']));
    }

    public function index(Request $request): JsonResponse
    {
        $query = Course::published()->with(['sourceLanguage:id,code,name,flag', 'targetLanguage:id,code,name,flag']);
        if ($request->filled('source')) {
            $query->whereHas('sourceLanguage', fn ($q) => $q->where('code', $request->source));
        }
        if ($request->filled('target')) {
            $query->whereHas('targetLanguage', fn ($q) => $q->where('code', $request->target));
        }
        $activeId = $request->user()->activeUserCourse()?->course_id;

        return $this->ok($query->orderBy('level')->get()->map(fn (Course $c) => [
            'id' => $c->id,
            'title' => $c->title,
            'description' => $c->description,
            'level' => $c->level,
            'source_language' => $c->sourceLanguage,
            'target_language' => $c->targetLanguage,
            'lesson_count' => $c->orderedPublishedLessons()->count(),
            'is_active' => $c->id === $activeId,
        ]));
    }

    public function enroll(Request $request, Course $course): JsonResponse
    {
        abort_unless($course->is_published, 404);
        $this->progress->enroll($request->user(), $course);

        return $this->ok(['course_id' => $course->id], 'Kurs aktif edildi');
    }

    public function path(Request $request, Course $course): JsonResponse
    {
        abort_unless($course->is_published, 404);
        $status = $this->progress->statusMap($request->user(), $course);

        $units = $course->units()->where('is_published', true)
            ->with(['lessons' => fn ($q) => $q->where('is_published', true)->withCount('exercises')])
            ->get();

        $number = 0;

        return $this->ok([
            'course' => ['id' => $course->id, 'title' => $course->title, 'level' => $course->level],
            'units' => $units->map(fn ($unit) => [
                'id' => $unit->id,
                'title' => $unit->title,
                'description' => $unit->description,
                'lessons' => $unit->lessons->map(function ($lesson) use ($status, &$number) {
                    $number++;

                    return [
                        'id' => $lesson->id,
                        'number' => $number,
                        'title' => $lesson->title,
                        'description' => $lesson->description,
                        'type' => $lesson->type,
                        'skill' => $lesson->skill,
                        'xp_reward' => $lesson->xp_reward,
                        'estimated_minutes' => $lesson->estimated_minutes,
                        'exercise_count' => $lesson->exercises_count,
                        'status' => $status[$lesson->id]['status'] ?? 'locked',
                        'score' => $status[$lesson->id]['score'] ?? 0,
                    ];
                })->values(),
            ])->values(),
        ]);
    }
}
