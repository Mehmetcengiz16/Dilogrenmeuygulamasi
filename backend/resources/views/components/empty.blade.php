@props(['icon' => 'inbox', 'text' => 'Henüz kayıt yok.'])
<div class="flex flex-col items-center justify-center gap-2 py-12 text-on-surface-variant">
    <span class="flex h-14 w-14 items-center justify-center rounded-full bg-primary-fixed text-primary">
        <span class="material-symbols-outlined">{{ $icon }}</span>
    </span>
    <p class="text-sm">{{ $text }}</p>
    {{ $slot }}
</div>
