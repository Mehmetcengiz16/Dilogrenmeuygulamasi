<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Resources\UserResource;
use App\Models\Language;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\Rules\Password as PasswordRule;

class AuthController extends ApiController
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'confirmed', PasswordRule::min(8)],
            'daily_goal_minutes' => ['nullable', 'integer', 'in:5,10,15,20,30'],
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'daily_goal_minutes' => $data['daily_goal_minutes'] ?? 15,
            'native_language_id' => Language::where('code', 'tr')->value('id'),
        ]);

        return $this->ok($this->tokenPayload($user), 'Kayıt başarılı', status: 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $data['email'])->first();
        if (! $user || ! Hash::check($data['password'], $user->password)) {
            return $this->fail('E-posta veya şifre hatalı', 401);
        }
        if ($user->status !== 'active') {
            return $this->fail('Hesabınız askıya alınmış', 403);
        }

        return $this->ok($this->tokenPayload($user), 'Giriş başarılı');
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate(['email' => ['required', 'email']]);
        Password::sendResetLink($request->only('email'));

        // Hesap varlığını sızdırmamak için her durumda aynı yanıt.
        return $this->ok(null, 'Hesap mevcutsa şifre sıfırlama bağlantısı gönderildi');
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->ok(null, 'Çıkış yapıldı');
    }

    private function tokenPayload(User $user): array
    {
        return [
            'token' => $user->createToken('mobile')->plainTextToken,
            'user' => new UserResource($user),
        ];
    }
}
