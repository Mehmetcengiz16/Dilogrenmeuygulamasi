@php
    $editing = $lesson !== null;
    $selectedWords = collect(old('word_ids', $editing ? $lesson->words->pluck('id')->all() : []))->map(fn ($v) => (int) $v);
@endphp
<x-admin-layout :title="$editing ? 'Ders Düzenle' : 'Yeni Ders'"
    :breadcrumbs="['Kurslar' => route('admin.courses.index'), $unit->course->title => route('admin.courses.show', $unit->course), ($editing ? $lesson->title : 'Yeni Ders') => null]">
    <h1 class="mb-1 text-[28px] font-bold leading-9 tracking-tight">{{ $editing ? 'Ders Düzenle' : 'Yeni Ders' }}</h1>
    <p class="mb-6 text-sm text-on-surface-variant">Ünite: {{ $unit->title }}</p>

    <form method="POST" action="{{ $editing ? route('admin.lessons.update', $lesson) : route('admin.lessons.store', $unit) }}" class="card grid gap-5 md:grid-cols-2">
        @csrf
        @if ($editing) @method('PUT') @endif
        <x-field name="title" label="Ders adı" :value="$lesson?->title" required class="md:col-span-2" />
        <x-field name="description" label="Açıklama (ana sayfa kartında görünür)" type="textarea" :value="$lesson?->description" class="md:col-span-2" />
        <x-field name="type" label="Ders tipi" :options="\App\Models\Lesson::TYPES" :value="$lesson?->type ?? 'standard'" />
        <x-field name="skill" label="Beceri" :options="\App\Models\Lesson::SKILLS" :value="$lesson?->skill ?? 'vocabulary'" />
        <x-field name="xp_reward" label="Tamamlama XP'si" type="number" :value="$lesson?->xp_reward ?? 20" required />
        <x-field name="estimated_minutes" label="Tahmini süre (dk)" type="number" :value="$lesson?->estimated_minutes ?? 10" required />
        <x-field name="time_limit_seconds" label="Süre sınırı (sn)" type="number" :value="$lesson?->time_limit_seconds ?? 600" help="Quiz ekranındaki 'Kalan Süre' sayacı. Boş bırakılırsa sayaç gösterilmez." />
        <x-field name="is_published" label="Yayında" type="checkbox" :value="$lesson?->is_published ?? false" class="self-end pb-3" />

        <div class="md:col-span-2">
            <span class="label">Bu derste öğretilen kelimeler (ders bitince kullanıcının kelime defterine eklenir)</span>
            <div class="flex max-h-48 flex-wrap gap-2 overflow-y-auto rounded-2xl bg-surface-low p-3">
                @forelse ($words as $id => $word)
                    <label class="cursor-pointer">
                        <input type="checkbox" name="word_ids[]" value="{{ $id }}" class="peer hidden" @checked($selectedWords->contains($id))>
                        <span class="chip bg-white px-3 py-1 text-xs text-on-surface peer-checked:bg-primary-container peer-checked:text-white">{{ $word }}</span>
                    </label>
                @empty
                    <span class="text-xs text-on-surface-variant">Bu dil için kelime bankası boş.</span>
                @endforelse
            </div>
        </div>

        <div class="flex justify-end gap-2 md:col-span-2">
            <a href="{{ $editing ? route('admin.lessons.show', $lesson) : route('admin.courses.show', $unit->course) }}" class="btn-soft">Vazgeç</a>
            <button class="btn-primary"><span class="material-symbols-outlined text-[18px]">save</span>Kaydet</button>
        </div>
    </form>
</x-admin-layout>
