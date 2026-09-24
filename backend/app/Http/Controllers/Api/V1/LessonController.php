<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Resources\ExerciseResource;
use App\Models\Lesson;
use App\Services\ProgressService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LessonController extends ApiController
{
    public function __construct(private ProgressService $progress) {}

    public function show(Request $request, Lesson $lesson): JsonResponse
    {
        abort_unless($lesson->is_published, 404);
        if (! $this->progress->canAccess($request->user(), $lesson)) {
            return $this->fail('Bu ders henüz kilitli', 403);
        }

        $lesson->load(['exercises.options', 'unit.course']);

        return $this->ok([
            'id' => $lesson->id,
            'title' => $lesson->title,
            'description' => $lesson->description,
            'type' => $lesson->type,
            'skill' => $lesson->skill,
            'xp_reward' => $lesson->xp_reward,
            'time_limit_seconds' => $lesson->time_limit_seconds,
            'unit' => ['id' => $lesson->unit->id, 'title' => $lesson->unit->title],
            'exercises' => ExerciseResource::collection($lesson->exercises),
        ]);
    }

    public function complete(Request $request, Lesson $lesson): JsonResponse
    {
        abort_unless($lesson->is_published, 404);
        if (! $this->progress->canAccess($request->user(), $lesson)) {
            return $this->fail('Bu ders henüz kilitli', 403);
        }

        $data = $request->validate([
            'answers' => ['required', 'array'],
            'answers.*.exercise_id' => ['required', 'integer'],
            'answers.*.is_correct' => ['required', 'boolean'],
            'duration_seconds' => ['required', 'integer', 'min:0'],
        ]);

        $result = $this->progress->completeLesson($request->user(), $lesson, $data['answers'], $data['duration_seconds']);

        return $this->ok($result, 'Ders tamamlandı');
    }
}
