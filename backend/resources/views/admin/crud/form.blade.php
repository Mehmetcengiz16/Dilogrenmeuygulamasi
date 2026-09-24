@php $editing = $item !== null; @endphp
<x-admin-layout :title="$c['title']" :breadcrumbs="[$c['title'] => route($c['route'].'.index'), ($editing ? 'Düzenle' : 'Yeni') => null]">
    <h1 class="mb-6 text-[28px] font-bold leading-9 tracking-tight">{{ $editing ? $c['singular'].' Düzenle' : 'Yeni '.$c['singular'] }}</h1>

    <form method="POST" enctype="multipart/form-data"
          action="{{ $editing ? route($c['route'].'.update', $item) : route($c['route'].'.store') }}" class="card grid gap-5 md:grid-cols-2">
        @csrf
        @if ($editing) @method('PUT') @endif

        @foreach ($c['fields'] as $name => $f)
            @php
                $type = $f['type'] ?? 'text';
                $value = $type === 'password' ? null : ($item ? data_get($item, $name) : ($f['default'] ?? null));
                $wide = in_array($type, ['textarea']) || ($f['wide'] ?? false);
            @endphp
            <x-field :name="$name" :label="$f['label']" :type="$type" :value="$value"
                     :options="$f['options'] ?? null" :help="$f['help'] ?? null"
                     :required="str_contains(is_string($f['rules'] ?? '') ? $f['rules'] : '', 'required')"
                     :accept="$f['accept'] ?? null" class="{{ $wide ? 'md:col-span-2' : '' }}" />
            @if ($type === 'file' && $item && $item->{$f['column']})
                <div class="-mt-3 text-xs text-on-surface-variant md:col-span-2">
                    Mevcut dosya:
                    @if (str_contains($f['accept'] ?? '', 'image'))
                        <img src="{{ \App\Http\Resources\ExerciseResource::url($item->{$f['column']}) }}" class="mt-1 h-16 rounded-xl object-cover">
                    @else
                        <audio controls src="{{ \App\Http\Resources\ExerciseResource::url($item->{$f['column']}) }}" class="mt-1 h-8"></audio>
                    @endif
                </div>
            @endif
        @endforeach

        <div class="flex justify-end gap-2 md:col-span-2">
            <a href="{{ route($c['route'].'.index') }}" class="btn-soft">Vazgeç</a>
            <button class="btn-primary"><span class="material-symbols-outlined text-[18px]">save</span>Kaydet</button>
        </div>
    </form>
</x-admin-layout>
