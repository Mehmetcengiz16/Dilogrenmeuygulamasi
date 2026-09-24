<x-admin-layout :title="$lesson->title"
    :breadcrumbs="['Kurslar' => route('admin.courses.index'), $lesson->unit->course->title => route('admin.courses.show', $lesson->unit->course), $lesson->title => null]">
    <x-slot:actions>
        <a href="{{ route('admin.lessons.edit', $lesson) }}" class="btn-soft"><span class="material-symbols-outlined text-[18px]">edit</span>Dersi Düzenle</a>
        <x-delete-button :action="route('admin.lessons.destroy', $lesson)" label="Sil" confirm="Ders ve tüm alıştırmaları silinecek. Emin misiniz?" />
        <a href="{{ route('admin.exercises.create', $lesson) }}" class="btn-primary"><span class="material-symbols-outlined text-[18px]">add</span>Alıştırma Ekle</a>
    </x-slot:actions>

    <div class="mb-6 flex flex-wrap items-end justify-between gap-4">
        <div>
            <div class="mb-2 flex flex-wrap gap-2">
                <span class="chip-primary">{{ \App\Models\Lesson::SKILLS[$lesson->skill] ?? $lesson->skill }}</span>
                <span class="chip-muted">{{ \App\Models\Lesson::TYPES[$lesson->type] ?? $lesson->type }}</span>
                <span class="chip-ok">{{ $lesson->xp_reward }} XP</span>
                <span class="chip-muted">{{ $lesson->estimated_minutes }} dk</span>
                @if ($lesson->time_limit_seconds)<span class="chip-muted">Süre: {{ gmdate('i:s', $lesson->time_limit_seconds) }}</span>@endif
                @unless ($lesson->is_published)<span class="chip-muted">Taslak</span>@endunless
            </div>
            <h1 class="text-[28px] font-bold leading-9 tracking-tight">{{ $lesson->title }}</h1>
            <p class="text-sm text-on-surface-variant">{{ $lesson->description }}</p>
        </div>
    </div>

    @if ($lesson->words->isNotEmpty())
        <div class="mb-6 flex flex-wrap items-center gap-2">
            <span class="text-xs font-semibold text-on-surface-variant">Kelimeler:</span>
            @foreach ($lesson->words as $w)<span class="chip bg-white px-3 py-1 shadow-sm">{{ $w->word }} · <span class="font-normal text-on-surface-variant">{{ $w->translation }}</span></span>@endforeach
        </div>
    @endif

    @if ($lesson->exercises->isEmpty())
        <div class="card"><x-empty icon="quiz" text="Bu derste henüz alıştırma yok."><a href="{{ route('admin.exercises.create', $lesson) }}" class="btn-primary mt-2">İlk alıştırmayı ekle</a></x-empty></div>
    @else
        <div class="grid gap-3" data-sortable="{{ route('admin.exercises.reorder', $lesson) }}">
            @foreach ($lesson->exercises as $ex)
                <div class="card flex items-start gap-4 p-5" data-id="{{ $ex->id }}">
                    <span class="material-symbols-outlined cursor-grab pt-1 text-on-surface-variant" data-handle>drag_indicator</span>
                    <span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary-container text-sm font-bold text-white">{{ $loop->iteration }}</span>
                    @if ($ex->image_path)
                        <img src="{{ \App\Http\Resources\ExerciseResource::url($ex->image_path) }}" class="h-16 w-16 shrink-0 rounded-2xl object-cover" alt="">
                    @endif
                    <div class="min-w-0 flex-1">
                        <div class="mb-1 flex flex-wrap gap-2">
                            <span class="chip-primary">{{ $ex->type->label() }}</span>
                            @if ($ex->category)<span class="chip-muted">{{ $ex->category }}</span>@endif
                            <span class="chip-ok">+{{ $ex->xp }} XP</span>
                            @if ($ex->audio_path)<span class="chip-muted"><span class="material-symbols-outlined text-[14px]">volume_up</span>Ses</span>@endif
                        </div>
                        <p class="font-semibold">{{ $ex->prompt }}</p>
                        @if ($ex->prompt_translation)<p class="text-xs text-on-surface-variant">{{ $ex->prompt_translation }}</p>@endif
                        <div class="mt-2 flex flex-wrap gap-1.5">
                            @if ($ex->correct_answer)
                                <span class="chip bg-tertiary-fixed/50 text-tertiary">Cevap: {{ $ex->correct_answer['text'] ?? '' }}</span>
                            @endif
                            @if ($ex->type !== \App\Enums\ExerciseType::SentenceOrder)
                                @foreach ($ex->options as $o)
                                    <span class="chip {{ $o->is_correct && $ex->type !== \App\Enums\ExerciseType::MatchPairs ? 'bg-tertiary-fixed/50 text-tertiary' : 'bg-surface-low text-on-surface-variant' }}">
                                        {{ $o->text }}@if ($o->pair_key) <span class="opacity-60">[{{ $o->pair_key }}]</span>@endif
                                    </span>
                                @endforeach
                            @endif
                        </div>
                    </div>
                    <div class="flex shrink-0 gap-1">
                        <a href="{{ route('admin.exercises.edit', $ex) }}" class="btn-soft btn-sm"><span class="material-symbols-outlined text-[16px]">edit</span></a>
                        <x-delete-button :action="route('admin.exercises.destroy', $ex)" />
                    </div>
                </div>
            @endforeach
        </div>
    @endif
</x-admin-layout>
