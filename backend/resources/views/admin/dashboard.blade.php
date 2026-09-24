<x-admin-layout title="Dashboard" :breadcrumbs="['Dashboard' => null]">
    <div class="mb-6">
        <span class="chip-primary mb-2"><span class="h-2 w-2 animate-pulse rounded-full bg-primary"></span>Canlı</span>
        <h1 class="text-[28px] font-bold leading-9 tracking-tight">Merhaba, {{ auth('admin')->user()->name }}</h1>
        <p class="text-sm text-on-surface-variant">Uygulamanın genel durumu ve son 30 gün.</p>
    </div>

    @unless ($aiEnabled)
        <div class="mb-6 flex items-start gap-3 rounded-2xl bg-surface-low p-4 text-sm">
            <span class="material-symbols-outlined text-primary">tips_and_updates</span>
            <div>
                <div class="font-semibold">AI çevrimdışı modda</div>
                <div class="text-on-surface-variant">AI sohbet ve serbest çeviri için
                    @if (auth('admin')->user()->isSuper())
                        <a href="{{ route('admin.settings.ai.edit') }}" class="font-semibold text-primary hover:underline">Yapay Zekâ Ayarları</a>
                    @else
                        Yapay Zekâ Ayarları
                    @endif
                    sayfasından OpenRouter veya Anthropic API anahtarı girin. Anahtar olmadan çeviri sözlük/kalıplardan, sohbet hazır senaryolardan çalışır.</div>
            </div>
        </div>
    @endunless

    <div class="mb-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        @foreach ($stats as [$label, $value, $icon, $tone])
            <div class="card relative overflow-hidden">
                <span class="mb-3 flex h-10 w-10 items-center justify-center rounded-full {{ $tone }}">
                    <span class="material-symbols-outlined text-[20px]">{{ $icon }}</span>
                </span>
                <div class="text-[22px] font-bold leading-7 tracking-tight">{{ $value }}</div>
                <div class="text-xs text-on-surface-variant">{{ $label }}</div>
                <div class="pointer-events-none absolute -bottom-4 -right-4 h-16 w-16 rounded-full bg-primary-fixed/30"></div>
            </div>
        @endforeach
    </div>

    <div class="grid gap-6 lg:grid-cols-3">
        <div class="card lg:col-span-2">
            <div class="mb-4 flex items-center justify-between">
                <h2 class="text-lg font-semibold">Son 30 gün</h2>
                <div class="flex gap-3 text-xs text-on-surface-variant">
                    <span class="flex items-center gap-1"><span class="h-2.5 w-2.5 rounded-full bg-primary-container"></span>Tamamlanan ders</span>
                    <span class="flex items-center gap-1"><span class="h-2.5 w-2.5 rounded-full bg-[#3fdeb4]"></span>Yeni kayıt</span>
                </div>
            </div>
            @php $max = max(1, $days->max('lessons'), $days->max('registrations')); @endphp
            <div class="flex h-48 items-end gap-1">
                @foreach ($days as $d)
                    <div class="group relative flex h-full flex-1 items-end gap-px" title="{{ \Illuminate\Support\Carbon::parse($d['date'])->translatedFormat('d M') }}: {{ $d['lessons'] }} ders, {{ $d['registrations'] }} kayıt">
                        <div class="w-1/2 rounded-t-full bg-primary-container/80 transition group-hover:bg-primary" style="height: {{ max(2, $d['lessons'] / $max * 100) }}%"></div>
                        <div class="w-1/2 rounded-t-full bg-[#3fdeb4] transition" style="height: {{ max(2, $d['registrations'] / $max * 100) }}%"></div>
                    </div>
                @endforeach
            </div>
            <div class="mt-2 flex justify-between text-[10px] text-on-surface-variant">
                <span>{{ \Illuminate\Support\Carbon::parse($days->first()['date'])->translatedFormat('d M') }}</span>
                <span>Bugün</span>
            </div>
        </div>

        <div class="card">
            <div class="mb-4 flex items-center justify-between">
                <h2 class="text-lg font-semibold">Son kayıtlar</h2>
                <a href="{{ route('admin.users.index') }}" class="text-xs font-semibold text-primary">Tümü</a>
            </div>
            <ul class="grid gap-3">
                @forelse ($latestUsers as $u)
                    <li>
                        <a href="{{ route('admin.users.show', $u) }}" class="flex items-center gap-3 rounded-2xl p-2 hover:bg-surface-low">
                            <span class="flex h-9 w-9 items-center justify-center rounded-full bg-secondary-fixed text-sm font-bold text-secondary">{{ mb_substr($u->name, 0, 1) }}</span>
                            <span class="min-w-0 flex-1">
                                <span class="block truncate text-sm font-semibold">{{ $u->name }}</span>
                                <span class="block truncate text-xs text-on-surface-variant">{{ $u->created_at->diffForHumans() }}</span>
                            </span>
                            <span class="chip-primary">{{ $u->total_xp }} XP</span>
                        </a>
                    </li>
                @empty
                    <x-empty icon="group" text="Henüz kullanıcı yok." />
                @endforelse
            </ul>
        </div>
    </div>
</x-admin-layout>
