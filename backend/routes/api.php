<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ChatController;
use App\Http\Controllers\Api\V1\CourseController;
use App\Http\Controllers\Api\V1\HomeController;
use App\Http\Controllers\Api\V1\LessonController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\StatsController;
use App\Http\Controllers\Api\V1\TranslateController;
use App\Http\Controllers\Api\V1\WordController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::middleware('throttle:10,1')->group(function () {
        Route::post('auth/register', [AuthController::class, 'register']);
        Route::post('auth/login', [AuthController::class, 'login']);
        Route::post('auth/forgot-password', [AuthController::class, 'forgotPassword']);
    });

    Route::get('languages', [CourseController::class, 'languages']);

    Route::middleware(['auth:sanctum', 'active'])->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);

        Route::get('me', [ProfileController::class, 'show']);
        Route::match(['put', 'post'], 'me', [ProfileController::class, 'update']);
        Route::delete('me', [ProfileController::class, 'destroy']);

        Route::get('home', HomeController::class);
        Route::get('stats', StatsController::class);

        Route::get('courses', [CourseController::class, 'index']);
        Route::post('courses/{course}/enroll', [CourseController::class, 'enroll']);
        Route::get('courses/{course}/path', [CourseController::class, 'path']);

        Route::get('lessons/{lesson}', [LessonController::class, 'show']);
        Route::post('lessons/{lesson}/complete', [LessonController::class, 'complete']);

        Route::get('words', [WordController::class, 'index']);
        Route::post('words/{word}/review', [WordController::class, 'review']);
        Route::post('words/{word}/favorite', [WordController::class, 'favorite']);

        Route::get('translate/home', [TranslateController::class, 'home']);
        Route::post('translate', [TranslateController::class, 'translate'])->middleware('throttle:30,1');
        Route::get('translate/history', [TranslateController::class, 'history']);
        Route::post('translate/{translation}/favorite', [TranslateController::class, 'favorite']);

        Route::get('chat/scenarios', [ChatController::class, 'scenarios']);
        Route::get('chat/messages', [ChatController::class, 'history']);
        Route::post('chat/messages', [ChatController::class, 'send'])->middleware('throttle:20,1');
        Route::delete('chat/messages', [ChatController::class, 'clear']);
    });
});
