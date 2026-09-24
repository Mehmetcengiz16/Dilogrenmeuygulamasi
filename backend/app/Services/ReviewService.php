<?php

namespace App\Services;

use App\Models\UserWord;

/** Basit aralıklı tekrar (spaced repetition): güç 0–5, doğru cevapta aralık katlanarak uzar. */
class ReviewService
{
    private const INTERVAL_DAYS = [0, 1, 3, 7, 14, 30];

    public function review(UserWord $userWord, bool $correct): UserWord
    {
        $strength = $correct ? min($userWord->strength + 1, 5) : max($userWord->strength - 1, 0);

        $userWord->update([
            'strength' => $strength,
            'next_review_at' => now()->addDays(self::INTERVAL_DAYS[$strength])->addHours($strength === 0 ? 4 : 0),
        ]);

        return $userWord;
    }
}
