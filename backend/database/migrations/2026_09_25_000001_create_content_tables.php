<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('languages', function (Blueprint $table) {
            $table->id();
            $table->string('code', 8)->unique();
            $table->string('name');
            $table->string('flag', 16)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('courses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('source_language_id')->constrained('languages');
            $table->foreignId('target_language_id')->constrained('languages');
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('level', 4)->default('A1');
            $table->boolean('is_published')->default(false);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('units', function (Blueprint $table) {
            $table->id();
            $table->foreignId('course_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->unsignedInteger('order')->default(0);
            $table->boolean('is_published')->default(false);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('lessons', function (Blueprint $table) {
            $table->id();
            $table->foreignId('unit_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('type', 16)->default('standard');
            $table->string('skill', 16)->default('vocabulary');
            $table->unsignedInteger('xp_reward')->default(20);
            $table->unsignedInteger('estimated_minutes')->default(10);
            $table->unsignedInteger('time_limit_seconds')->nullable();
            $table->unsignedInteger('order')->default(0);
            $table->boolean('is_published')->default(false);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('exercises', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lesson_id')->constrained()->cascadeOnDelete();
            $table->string('type', 24);
            $table->string('category')->nullable();
            $table->string('instruction')->nullable();
            $table->text('prompt');
            $table->text('prompt_translation')->nullable();
            $table->json('correct_answer')->nullable();
            $table->text('explanation')->nullable();
            $table->string('audio_path', 1024)->nullable();
            $table->string('image_path', 1024)->nullable();
            $table->unsignedInteger('xp')->default(10);
            $table->unsignedInteger('order')->default(0);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('exercise_options', function (Blueprint $table) {
            $table->id();
            $table->foreignId('exercise_id')->constrained()->cascadeOnDelete();
            $table->string('text');
            $table->string('translation')->nullable();
            $table->string('image_path', 1024)->nullable();
            $table->string('audio_path', 1024)->nullable();
            $table->boolean('is_correct')->default(false);
            $table->string('pair_key')->nullable();
            $table->unsignedInteger('order')->default(0);
            $table->timestamps();
        });

        Schema::create('words', function (Blueprint $table) {
            $table->id();
            $table->foreignId('language_id')->constrained();
            $table->string('word');
            $table->string('translation');
            $table->string('pronunciation')->nullable();
            $table->text('example_sentence')->nullable();
            $table->text('example_translation')->nullable();
            $table->string('audio_path', 1024)->nullable();
            $table->string('image_path', 1024)->nullable();
            $table->string('level', 4)->default('A1');
            $table->timestamps();
            $table->softDeletes();
            $table->index(['language_id', 'word']);
        });

        Schema::create('lesson_word', function (Blueprint $table) {
            $table->foreignId('lesson_id')->constrained()->cascadeOnDelete();
            $table->foreignId('word_id')->constrained()->cascadeOnDelete();
            $table->primary(['lesson_id', 'word_id']);
        });

        // Çeviri ekranı: hızlı kalıplar (quick) ve günün deyimi (idiom)
        Schema::create('phrases', function (Blueprint $table) {
            $table->id();
            $table->foreignId('language_id')->constrained();
            $table->string('type', 16)->default('quick');
            $table->string('text');
            $table->string('translation');
            $table->string('emoji', 16)->nullable();
            $table->string('pronunciation')->nullable();
            $table->string('image_path', 1024)->nullable();
            $table->unsignedInteger('order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // AI sohbet ekranı: önerilen konuşma senaryoları
        Schema::create('conversation_scenarios', function (Blueprint $table) {
            $table->id();
            $table->foreignId('language_id')->constrained();
            $table->string('title');
            $table->string('description')->nullable();
            $table->string('icon', 32)->default('forum');
            $table->string('level', 4)->default('A2');
            $table->unsignedInteger('estimated_minutes')->default(15);
            $table->text('opening_message');
            $table->text('system_prompt')->nullable();
            $table->boolean('is_featured')->default(false);
            $table->unsignedInteger('order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Ana sayfa: günün ipucu
        Schema::create('tips', function (Blueprint $table) {
            $table->id();
            $table->text('text');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('badges', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('name');
            $table->string('description')->nullable();
            $table->string('icon', 32)->default('military_tech');
            $table->string('rule', 24);
            $table->unsignedInteger('threshold');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        foreach (['badges', 'tips', 'conversation_scenarios', 'phrases', 'lesson_word', 'words',
            'exercise_options', 'exercises', 'lessons', 'units', 'courses', 'languages'] as $t) {
            Schema::dropIfExists($t);
        }
    }
};
