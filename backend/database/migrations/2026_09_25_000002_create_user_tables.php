<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('avatar_path')->nullable()->after('password');
            $table->foreignId('native_language_id')->nullable()->after('avatar_path')->constrained('languages');
            $table->unsignedSmallInteger('daily_goal_minutes')->default(15)->after('native_language_id');
            $table->unsignedInteger('total_xp')->default(0);
            $table->unsignedInteger('current_streak')->default(0);
            $table->unsignedInteger('longest_streak')->default(0);
            $table->date('last_activity_date')->nullable();
            $table->string('status', 16)->default('active');
            $table->softDeletes();
        });

        Schema::create('admins', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->string('role', 16)->default('editor');
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('user_courses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('course_id')->constrained()->cascadeOnDelete();
            $table->foreignId('current_lesson_id')->nullable()->constrained('lessons')->nullOnDelete();
            $table->timestamp('started_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['user_id', 'course_id']);
        });

        Schema::create('lesson_progress', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('lesson_id')->constrained()->cascadeOnDelete();
            $table->string('status', 16)->default('unlocked');
            $table->unsignedTinyInteger('score')->default(0);
            $table->unsignedInteger('mistakes')->default(0);
            $table->unsignedInteger('attempts')->default(0);
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'lesson_id']);
        });

        Schema::create('user_words', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('word_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('strength')->default(0);
            $table->timestamp('next_review_at')->nullable();
            $table->boolean('is_favorite')->default(false);
            $table->timestamps();
            $table->unique(['user_id', 'word_id']);
        });

        Schema::create('xp_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->integer('amount');
            $table->string('source', 16);
            $table->timestamps();
        });

        // Günlük hedef, seri ve haftalık takip için gün bazlı özet
        Schema::create('daily_activities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->unsignedInteger('seconds')->default(0);
            $table->unsignedInteger('xp')->default(0);
            $table->unsignedInteger('lessons_completed')->default(0);
            $table->timestamps();
            $table->unique(['user_id', 'date']);
        });

        Schema::create('user_badges', function (Blueprint $table) {
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('badge_id')->constrained()->cascadeOnDelete();
            $table->timestamp('earned_at');
            $table->primary(['user_id', 'badge_id']);
        });

        Schema::create('saved_translations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('source_lang', 8);
            $table->string('target_lang', 8);
            $table->text('source_text');
            $table->text('translated_text');
            $table->string('pronunciation')->nullable();
            $table->boolean('is_favorite')->default(false);
            $table->timestamps();
        });

        Schema::create('chat_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('scenario_id')->nullable()->constrained('conversation_scenarios')->nullOnDelete();
            $table->string('role', 16);
            $table->text('content');
            $table->timestamps();
            $table->index(['user_id', 'scenario_id']);
        });
    }

    public function down(): void
    {
        foreach (['chat_messages', 'saved_translations', 'user_badges', 'daily_activities', 'xp_logs',
            'user_words', 'lesson_progress', 'user_courses', 'admins'] as $t) {
            Schema::dropIfExists($t);
        }
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('native_language_id');
            $table->dropColumn(['avatar_path', 'daily_goal_minutes', 'total_xp', 'current_streak',
                'longest_streak', 'last_activity_date', 'status', 'deleted_at']);
        });
    }
};
