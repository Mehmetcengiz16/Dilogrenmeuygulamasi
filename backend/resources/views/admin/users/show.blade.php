<x-admin-layout :title="$user->name" :breadcrumbs="['Kullanıcılar' => route('admin.users.index'), $user->name => null]">
    <x-slot:actions>
        <form method="POST" action="{{ route('admin.users.toggle', $user) }}"
              data-confirm="{{ $user->status === 'active' ? 'Hesap dondurulacak ve tüm oturumları kapatılacak. Emin misiniz?' : 'Hesap yeniden aktif edilsin mi?' }}">
            @csrf
            @if ($user->status === 'active')
                <button class="btn-danger"><span class="material-symbols-outlined text-[18px]">block</span>Hesabı Dondur</button>
            @else
                <button class="btn-primary"><span class="material-symbols-outlined text-[18px]">lock_open</span>Aktif Et</button>
            @endif
        </form>
    </x-slot:actions>

    <div class="mb-6 flex items-center gap-4">
        <span class="flex h-16 w-16 items-center justify-center rounded-full bg-secondary-fixed text-2xl font-bold text-secondary">{{ mb_substr($user->name, 0, 1) }}</span>
        <div>
            <h1 class="text-[28px] font-bold leading-9 tracking-tight">{{ $user->name }}</h1>
            <p class="text-sm text-on-surface-variant">{{ $user->email }} · {{ $user->created_at->format('d.m.Y') }} tarihinde katıldı</p>
        </div>
        {!! $user->status === 'active' ? '<span class="chip-ok">Aktif</span>' : '<span class="chip bg-error-container text-error">Dondurulmuş</span>' !!}
    </div>

    <div class="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        @foreach ([['Toplam XP', $user->total_xp, 'bolt'], ['Güncel seri', $streak.' gün', 'local_fire_department'], ['En uzun seri', $user->longest_streak.' gün', 'trending_up'], ['Kelime', $wordCount, 'menu_book'], ['Günlük hedef', $user->daily_goal_minutes.' dk', 'flag']] as [$l, $v, $i])
            <div class="card p-4">
                <span class="material-symbols-outlined mb-2 text-primary">{{ $i }}</span>
                <div class="text-xl font-bold">{{ $v }}</div>
                <div class="text-xs text-on-surface-variant">{{ $l }}</div>
            </div>
        @endforeach
    </div>

    <div class="grid gap-6 lg:grid-cols-2">
        <div class="card">
            <h2 class="mb-4 font-semibold">Son 14 gün aktivite</h2>
            @php $max = max(1, $activity->max('seconds')); @endphp
            <div class="flex h-32 items-end gap-1.5">
                @forelse ($activity as $a)
                    <div class="flex flex-1 flex-col items-center gap-1" title="{{ $a->date->format('d.m') }}: {{ intdiv($a->seconds, 60) }} dk, {{ $a->xp }} XP">
                        <div class="w-full rounded-t-full bg-primary-container" style="height: {{ max(4, $a->seconds / $max * 100) }}px"></div>
                        <span class="text-[10px] text-on-surface-variant">{{ $a->date->format('d') }}</span>
                    </div>
                @empty
                    <p class="text-sm text-on-surface-variant">Aktivite yok.</p>
                @endforelse
            </div>
        </div>

        <div class="card">
            <h2 class="mb-4 font-semibold">Kurslar ve rozetler</h2>
            @foreach ($user->userCourses as $uc)
                <div class="mb-2 flex items-center justify-between rounded-2xl bg-surface-low px-3 py-2 text-sm">
                    <span class="font-semibold">{{ $uc->course->title }}</span>
                    {!! $uc->is_active ? '<span class="chip-ok">Aktif kurs</span>' : '' !!}
                </div>
            @endforeach
            <div class="mt-3 flex flex-wrap gap-2">
                @forelse ($user->badges as $b)
                    <span class="chip-primary px-3 py-1"><span class="material-symbols-outlined text-[14px]">{{ $b->icon }}</span>{{ $b->name }}</span>
                @empty
                    <span class="text-xs text-on-surface-variant">Henüz rozet yok.</span>
                @endforelse
            </div>
        </div>

        <div class="card lg:col-span-2">
            <h2 class="mb-4 font-semibold">Son tamamlanan dersler</h2>
            <table class="data-table">
                <thead><tr><th>Ders</th><th>Ünite</th><th>Puan</th><th>Hata</th><th>Deneme</th><th>Tarih</th></tr></thead>
                <tbody>
                @forelse ($recent as $p)
                    <tr>
                        <td class="font-semibold">{{ $p->lesson->title }}</td>
                        <td class="text-on-surface-variant">{{ $p->lesson->unit->title }}</td>
                        <td><span class="{{ $p->score >= 80 ? 'chip-ok' : 'chip-muted' }}">%{{ $p->score }}</span></td>
                        <td>{{ $p->mistakes }}</td>
                        <td>{{ $p->attempts }}</td>
                        <td class="text-xs text-on-surface-variant">{{ $p->completed_at?->format('d.m.Y H:i') }}</td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="text-center text-on-surface-variant">Henüz tamamlanan ders yok.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
    </div>
</x-admin-layout>
