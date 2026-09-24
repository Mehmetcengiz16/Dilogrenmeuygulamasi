<?php

namespace App\Enums;

enum ExerciseType: string
{
    case MultipleChoice = 'multiple_choice';
    case MatchPairs = 'match_pairs';
    case FillBlank = 'fill_blank';
    case SentenceOrder = 'sentence_order';
    case ListenWrite = 'listen_write';
    case ImageSelect = 'image_select';

    public function label(): string
    {
        return match ($this) {
            self::MultipleChoice => 'Çoktan seçmeli',
            self::MatchPairs => 'Eşleştirme',
            self::FillBlank => 'Boşluk doldurma',
            self::SentenceOrder => 'Cümle kurma (kelime sıralama)',
            self::ListenWrite => 'Dinle ve yaz',
            self::ImageSelect => 'Görselden kelime',
        };
    }

    /** Seçenek (exercise_options) kullanan tipler. */
    public function usesOptions(): bool
    {
        return in_array($this, [self::MultipleChoice, self::MatchPairs, self::ImageSelect, self::SentenceOrder], true);
    }

    public static function options(): array
    {
        return collect(self::cases())->mapWithKeys(fn ($c) => [$c->value => $c->label()])->all();
    }
}
