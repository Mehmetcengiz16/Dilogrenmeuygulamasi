<x-admin-layout :title="$c['title']" :breadcrumbs="[$c['title'] => null]">
    <x-slot:actions>
        @foreach ($c['extraActions'] ?? [] as $a)
            <a href="{{ $a['url'] }}" class="btn-soft"><span class="material-symbols-outlined text-[18px]">{{ $a['icon'] }}</span>{{ $a['label'] }}</a>
        @endforeach
        @unless ($c['readonly'] ?? false)
            <a href="{{ route($c['route'].'.create') }}" class="btn-primary"><span class="material-symbols-outlined text-[18px]">add</span>Yeni {{ $c['singular'] }}</a>
        @endunless
    </x-slot:actions>

    <div class="mb-6 flex flex-wrap items-end justify-between gap-4">
        <div>
            <h1 class="text-[28px] font-bold leading-9 tracking-tight">{{ $c['title'] }}</h1>
            @isset($c['subtitle'])<p class="text-sm text-on-surface-variant">{{ $c['subtitle'] }}</p>@endisset
        </div>
        @if (! empty($c['search']))
            <form class="flex items-center gap-2 rounded-full bg-white p-1.5 pl-4 shadow-[0_8px_24px_rgba(108,92,231,0.09)]">
                <span class="material-symbols-outlined text-[20px] text-on-surface-variant">search</span>
                <input name="q" value="{{ request('q') }}" placeholder="Ara..." class="w-56 bg-transparent text-sm outline-none">
                <button class="btn-primary btn-sm">Ara</button>
            </form>
        @endif
    </div>

    <div class="card overflow-hidden p-0">
        @if ($items->isEmpty())
            <x-empty :icon="$c['icon']" />
        @else
            <table class="data-table">
                <thead><tr>
                    @foreach ($c['columns'] as $label)<th>{{ $label }}</th>@endforeach
                    <th class="text-right">İşlemler</th>
                </tr></thead>
                <tbody>
                @foreach ($items as $item)
                    <tr>
                        @foreach ($c['columns'] as $key => $label)<td>{!! $cell($item, $key) !!}</td>@endforeach
                        <td class="whitespace-nowrap text-right">
                            @isset($c['showRoute'])
                                <a href="{{ route($c['showRoute'], $item) }}" class="btn-soft btn-sm"><span class="material-symbols-outlined text-[16px]">visibility</span></a>
                            @endisset
                            @unless ($c['readonly'] ?? false)
                                <a href="{{ route($c['route'].'.edit', $item) }}" class="btn-soft btn-sm"><span class="material-symbols-outlined text-[16px]">edit</span></a>
                                <x-delete-button :action="route($c['route'].'.destroy', $item)" />
                            @endunless
                        </td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        @endif
    </div>
    <div class="mt-4">{{ $items->links() }}</div>
</x-admin-layout>
