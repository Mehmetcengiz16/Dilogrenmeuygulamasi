<?php

use App\Http\Controllers\Admin;
use Illuminate\Support\Facades\Route;

Route::redirect('/', '/admin');

Route::prefix('admin')->name('admin.')->group(function () {
    Route::middleware('guest:admin')->group(function () {
        Route::get('login', [Admin\AuthController::class, 'showLogin'])->name('login');
        Route::post('login', [Admin\AuthController::class, 'login'])->name('login.store');
    });

    Route::middleware('auth:admin')->group(function () {
        Route::post('logout', [Admin\AuthController::class, 'logout'])->name('logout');
        Route::get('/', Admin\DashboardController::class)->name('dashboard');

        Route::resource('languages', Admin\LanguageController::class)->except('show');
        Route::resource('courses', Admin\CourseController::class);

        Route::post('courses/{course}/units', [Admin\UnitController::class, 'store'])->name('units.store');
        Route::post('courses/{course}/units/reorder', [Admin\UnitController::class, 'reorder'])->name('units.reorder');
        Route::resource('units', Admin\UnitController::class)->only(['edit', 'update', 'destroy']);

        Route::get('units/{unit}/lessons/create', [Admin\LessonController::class, 'create'])->name('lessons.create');
        Route::post('units/{unit}/lessons', [Admin\LessonController::class, 'store'])->name('lessons.store');
        Route::post('units/{unit}/lessons/reorder', [Admin\LessonController::class, 'reorder'])->name('lessons.reorder');
        Route::resource('lessons', Admin\LessonController::class)->only(['show', 'edit', 'update', 'destroy']);

        Route::get('lessons/{lesson}/exercises/create', [Admin\ExerciseController::class, 'create'])->name('exercises.create');
        Route::post('lessons/{lesson}/exercises', [Admin\ExerciseController::class, 'store'])->name('exercises.store');
        Route::post('lessons/{lesson}/exercises/reorder', [Admin\ExerciseController::class, 'reorder'])->name('exercises.reorder');
        Route::resource('exercises', Admin\ExerciseController::class)->only(['edit', 'update', 'destroy']);

        Route::get('words/import', [Admin\WordController::class, 'importForm'])->name('words.import');
        Route::post('words/import', [Admin\WordController::class, 'import'])->name('words.import.store');
        Route::resource('words', Admin\WordController::class)->except('show');
        Route::resource('phrases', Admin\PhraseController::class)->except('show');
        Route::resource('scenarios', Admin\ScenarioController::class)->except('show');
        Route::resource('tips', Admin\TipController::class)->except('show');

        Route::get('users', [Admin\UserController::class, 'index'])->name('users.index');
        Route::get('users/{user}', [Admin\UserController::class, 'show'])->name('users.show');
        Route::post('users/{user}/toggle-status', [Admin\UserController::class, 'toggleStatus'])->name('users.toggle');

        Route::resource('admins', Admin\AdminUserController::class)->except('show')->middleware('super');

        Route::middleware('super')->prefix('settings/ai')->name('settings.ai.')->group(function () {
            Route::get('/', [Admin\AiSettingsController::class, 'edit'])->name('edit');
            Route::put('/', [Admin\AiSettingsController::class, 'update'])->name('update');
            Route::post('test', [Admin\AiSettingsController::class, 'test'])->name('test');
            Route::post('models', [Admin\AiSettingsController::class, 'refreshModels'])->name('models');
        });
    });
});
