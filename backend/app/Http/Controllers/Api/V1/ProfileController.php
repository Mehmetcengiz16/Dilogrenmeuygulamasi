<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Resources\UserResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends ApiController
{
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        return $this->ok([
            'user' => new UserResource($user),
            'stats' => [
                'completed_lessons' => $user->lessonProgress()->where('status', 'completed')->count(),
                'learned_words' => $user->userWords()->count(),
                'badges' => $user->badges()->count(),
            ],
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:100'],
            'daily_goal_minutes' => ['sometimes', 'integer', 'in:5,10,15,20,30'],
            'avatar' => ['sometimes', 'image', 'max:1024'],
        ]);

        if ($request->hasFile('avatar')) {
            if ($user->avatar_path) {
                Storage::disk('public')->delete($user->avatar_path);
            }
            $data['avatar_path'] = $request->file('avatar')->store('avatars', 'public');
            unset($data['avatar']);
        }
        $user->update($data);

        return $this->ok(new UserResource($user->fresh()), 'Profil güncellendi');
    }

    public function destroy(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->tokens()->delete();
        $user->update(['email' => 'deleted_'.$user->id.'_'.$user->email, 'status' => 'deleted']);
        $user->delete();

        return $this->ok(null, 'Hesabınız silindi');
    }
}
