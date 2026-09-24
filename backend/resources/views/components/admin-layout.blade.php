<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $title ?? 'Admin' }} · LinguaAI</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="bg-surface font-sans text-on-surface antialiased">
@php
    $nav = [
        ['admin.dashboard', 'dashboard', 'Dashboard', 'admin'],
        ['admin.languages.index', 'language', 'Diller', 'admin/languages*'],
        ['admin.courses.index', 'school', 'Kurslar ve Dersler', 'admin/courses*|admin/units*|admin/lessons*|admin/exercises*'],
        ['admin.words.index', 'menu_book', 'Kelime Bankası', 'admin/words*'],
        ['admin.phrases.index', 'translate', 'Kalıplar ve Deyimler', 'admin/phrases*'],
        ['admin.scenarios.index', 'smart_toy', 'AI Senaryoları', 'admin/scenarios*'],
        ['admin.tips.index', 'tips_and_updates', 'Günün İpuçları', 'admin/tips*'],
        ['admin.users.index', 'group', 'Kullanıcılar', 'admin/users*'],
    ];
    if (auth('admin')->user()->isSuper()) {
        $nav[] = ['admin.settings.ai.edit', 'neurology', 'Yapay Zekâ Ayarları', 'admin/settings/ai*'];
        $nav[] = ['admin.admins.index', 'admin_panel_settings', 'Adminler', 'admin/admins*'];
    }
@endphp
<div class="flex min-h-screen">
    <aside class="fixed inset-y-0 left-0 z-30 hidden w-64 flex-col gap-1 bg-white/80 p-4 shadow-[0_0_32px_rgba(108,92,231,0.08)] backdrop-blur-xl lg:flex">
        <a href="{{ route('admin.dashboard') }}" class="mb-6 flex items-center gap-2 px-2 pt-2">
            <span class="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-primary-container to-[#8072f6] text-white shadow-[0_6px_16px_rgba(108,92,231,0.35)]">
                <span class="material-symbols-outlined text-[20px]">translate</span>
            </span>
            <span class="text-lg font-bold tracking-tight text-primary">LinguaAI</span>
            <span class="chip-muted ml-auto">Admin</span>
        </a>
        @foreach ($nav as [$route, $icon, $label, $pattern])
            @php $active = collect(explode('|', $pattern))->contains(fn ($p) => request()->is($p)); @endphp
            <a href="{{ route($route) }}"
               class="flex items-center gap-3 rounded-full px-4 py-2.5 text-sm font-semibold transition {{ $active ? 'bg-primary text-white shadow-[0_8px_20px_rgba(83,65,205,0.3)]' : 'text-on-surface-variant hover:bg-surface-low hover:text-on-surface' }}">
                <span class="material-symbols-outlined text-[20px]">{{ $icon }}</span>{{ $label }}
            </a>
        @endforeach
        <div class="mt-auto rounded-2xl bg-surface-low p-3">
            <div class="text-sm font-semibold">{{ auth('admin')->user()->name }}</div>
            <div class="text-xs text-on-surface-variant">{{ auth('admin')->user()->isSuper() ? 'Süper Admin' : 'Editör' }}</div>
            <form method="POST" action="{{ route('admin.logout') }}" class="mt-2">
                @csrf
                <button class="btn-soft btn-sm w-full"><span class="material-symbols-outlined text-[16px]">logout</span>Çıkış</button>
            </form>
        </div>
    </aside>

    <main class="flex-1 lg:pl-64">
        <header class="sticky top-0 z-20 flex h-16 items-center justify-between bg-surface/80 px-6 backdrop-blur-xl shadow-[0_1px_8px_rgba(0,0,0,0.04)]">
            <div class="flex items-center gap-2 text-sm text-on-surface-variant">
                @foreach ($breadcrumbs ?? [] as $label => $url)
                    @if ($url)<a href="{{ $url }}" class="hover:text-primary">{{ $label }}</a><span class="material-symbols-outlined text-[16px]">chevron_right</span>
                    @else<span class="font-semibold text-on-surface">{{ $label }}</span>@endif
                @endforeach
            </div>
            <div class="flex items-center gap-2">{{ $actions ?? '' }}</div>
        </header>

        <div class="mx-auto max-w-6xl p-6">
            @if (session('status'))
                <div class="mb-4 flex items-center gap-2 rounded-2xl bg-tertiary-fixed/40 px-4 py-3 text-sm font-semibold text-tertiary">
                    <span class="material-symbols-outlined text-[20px]">check_circle</span>{{ session('status') }}
                </div>
            @endif
            @if ($errors->any())
                <div class="mb-4 rounded-2xl bg-error-container px-4 py-3 text-sm text-error">
                    <div class="font-semibold">Lütfen hataları düzeltin:</div>
                    <ul class="mt-1 list-inside list-disc">@foreach ($errors->all() as $e)<li>{{ $e }}</li>@endforeach</ul>
                </div>
            @endif
            {{ $slot }}
        </div>
    </main>
</div>
</body>
</html>
