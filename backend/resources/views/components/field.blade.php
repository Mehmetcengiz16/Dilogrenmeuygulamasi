@props(['name', 'label', 'type' => 'text', 'value' => null, 'options' => null, 'help' => null, 'required' => false])
@php $current = old($name, $value); @endphp
<div {{ $attributes->only('class') }}>
    @if ($type !== 'checkbox')
        <label for="f-{{ $name }}" class="label">{{ $label }}@if ($required)<span class="text-error"> *</span>@endif</label>
    @endif
    @if ($options !== null)
        <select id="f-{{ $name }}" name="{{ $name }}" class="input" {{ $attributes->except('class') }} @required($required)>
            @foreach ($options as $key => $text)
                <option value="{{ $key }}" @selected((string) $current === (string) $key)>{{ $text }}</option>
            @endforeach
        </select>
    @elseif ($type === 'textarea')
        <textarea id="f-{{ $name }}" name="{{ $name }}" rows="3" class="input" {{ $attributes->except('class') }} @required($required)>{{ $current }}</textarea>
    @elseif ($type === 'checkbox')
        <label class="flex cursor-pointer items-center gap-2 text-sm font-semibold">
            <input type="hidden" name="{{ $name }}" value="0">
            <input type="checkbox" name="{{ $name }}" value="1" class="h-4 w-4 accent-[#6c5ce7]" @checked($current)>
            {{ $label }}
        </label>
    @elseif ($type === 'file')
        <input id="f-{{ $name }}" type="file" name="{{ $name }}" class="input file:mr-3 file:rounded-full file:border-0 file:bg-primary-fixed file:px-3 file:py-1 file:text-xs file:font-semibold file:text-on-primary-fixed" {{ $attributes->except('class') }}>
    @else
        <input id="f-{{ $name }}" type="{{ $type }}" name="{{ $name }}" value="{{ $current }}" class="input" {{ $attributes->except('class') }} @required($required)>
    @endif
    @if ($help)<p class="mt-1 text-xs text-on-surface-variant">{{ $help }}</p>@endif
    @error($name)<p class="mt-1 text-xs text-error">{{ $message }}</p>@enderror
</div>
