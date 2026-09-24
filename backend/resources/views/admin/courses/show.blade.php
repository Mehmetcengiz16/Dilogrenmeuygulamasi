<x-admin-layout :title="$course->title" :breadcrumbs="['Kurslar' => route('admin.courses.index'), $course->title => null]">
    <x-slot:actions>
        <a href="{{ route('admin.courses.edit', $course) }}" class="btn-soft"><span class="material-symbols-outlined text-[18px]">edit</span>Kursu Düzenle</a>
    </x-slot:actions>

    <div class="relative mb-6 overflow-hidden rounded-[28px] bg-primary-container p-6 text-white shadow-[0_16px_36px_rgba(108,92,231,0.28)]">
        <div class="pointer-events-none absolute -right-10 -top-10 h-44 w-44 rounded-full bg-primary-fixed/20 blur-2xl"></div>
        <div class="relative flex flex-wrap items-center gap-2">
            <span class="chip bg-white/20">{{ $course->level }}</span>
            <span class="chip bg-white/20">{{ $course->units->count() }} ünite · {{ $course->units->sum(fn ($u) => $u->lessons->count()) }} ders</span>
            <span class="chip {{ $course->is_published ? 'bg-tertiary-fixed text-on-tertiary-fixed' : 'bg-white/20' }}">{{ $course->is_published ? 'Yayında' : 'Taslak' }}</span>
        </div>
        <h1 class="relative mt-3 text-[28px] font-bold leading-9">{{ $course->title }}</h1>
        <p class="relative mt-1 text-sm text-white/85">{{ $course->description }}</p>
    </div>

    <div class="mb-3 flex items-center justify-between">
        <h2 class="text-lg font-semibold">Üniteler ve dersler</h2>
        <span class="flex items-center gap-1 text-xs text-on-surface-variant"><span class="material-symbols-outlined text-[16px]">drag_indicator</span>Sıralamak için sürükleyin</span>
    </div>

    <div class="grid gap-4" data-sortable="{{ route('admin.units.reorder', $course) }}">
        @foreach ($course->units as $unit)
            <div class="card p-5" data-id="{{ $unit->id }}">
                <div class="flex items-center gap-3">
                    <span class="material-symbols-outlined cursor-grab text-on-surface-variant" data-handle>drag_indicator</span>
                    <span class="flex h-9 w-9 items-center justify-center rounded-full bg-secondary-fixed text-sm font-bold text-secondary">{{ $loop->iteration }}</span>
                    <div class="min-w-0 flex-1">
                        <div class="flex items-center gap-2">
                            <h3 class="font-semibold">{{ $unit->title }}</h3>
                            @unless ($unit->is_published)<span class="chip-muted">Taslak</span>@endunless
                        </div>
                        <p class="truncate text-xs text-on-surface-variant">{{ $unit->description }}</p>
                    </div>
                    <a href="{{ route('admin.lessons.create', $unit) }}" class="btn-soft btn-sm"><span class="material-symbols-outlined text-[16px]">add</span>Ders</a>
                    <a href="{{ route('admin.units.edit', $unit) }}" class="btn-soft btn-sm"><span class="material-symbols-outlined text-[16px]">edit</span></a>
                    <x-delete-button :action="route('admin.units.destroy', $unit)" confirm="Ünite ve içindeki tüm dersler silinecek. Emin misiniz?" />
                </div>

                <div class="mt-4 grid min-h-6 gap-2 pl-10" data-sortable="{{ route('admin.lessons.reorder', $unit) }}">
                    @forelse ($unit->lessons as $lesson)
                        <div class="flex items-center gap-3 rounded-2xl bg-surface-low px-3 py-2.5" data-id="{{ $lesson->id }}">
                            <span class="material-symbols-outlined cursor-grab text-[18px] text-on-surface-variant" data-handle>drag_indicator</span>
                            <span class="material-symbols-outlined text-[20px] text-primary">{{ ['vocabulary' => 'menu_book', 'listening' => 'headphones', 'speaking' => 'record_voice_over', 'grammar' => 'spellcheck'][$lesson->skill] ?? 'school' }}</span>
                            <a href="{{ route('admin.lessons.show', $lesson) }}" class="min-w-0 flex-1 truncate text-sm font-semibold hover:text-primary">{{ $lesson->title }}</a>
                            <span class="chip-muted">{{ $lesson->exercises_count }} alıştırma</span>
                            <span class="chip-primary">{{ $lesson->xp_reward }} XP</span>
                            <span class="hidden text-xs text-on-surface-variant sm:inline">{{ $lesson->estimated_minutes }} dk</span>
                            @unless ($lesson->is_published)<span class="chip-muted">Taslak</span>@endunless
                        </div>
                    @empty
                        <p class="text-xs text-on-surface-variant">Bu ünitede henüz ders yok.</p>
                    @endforelse
                </div>
            </div>
        @endforeach
    </div>

    <form method="POST" action="{{ route('admin.units.store', $course) }}" class="card mt-6 grid gap-4 md:grid-cols-[1fr_1fr_auto_auto] md:items-end">
        @csrf
        <x-field name="title" label="Yeni ünite adı" required />
        <x-field name="description" label="Açıklama" />
        <x-field name="is_published" label="Yayında" type="checkbox" :value="true" class="pb-3" />
        <button class="btn-primary"><span class="material-symbols-outlined text-[18px]">add</span>Ünite Ekle</button>
    </form>
</x-admin-layout>
