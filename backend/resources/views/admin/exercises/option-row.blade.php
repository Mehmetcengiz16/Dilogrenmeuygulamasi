<div class="grid items-center gap-2 rounded-2xl bg-surface-low p-2 md:grid-cols-[1fr_1fr_110px_auto_auto]" data-option-row>
    <input name="options[{{ $i }}][text]" value="{{ $o['text'] ?? '' }}" placeholder="Seçenek metni" class="input">
    <input name="options[{{ $i }}][translation]" value="{{ $o['translation'] ?? '' }}" placeholder="Çeviri (isteğe bağlı)" class="input">
    <input name="options[{{ $i }}][pair_key]" value="{{ $o['pair_key'] ?? '' }}" placeholder="Çift (p1)" class="input">
    <label class="flex items-center gap-1.5 whitespace-nowrap px-2 text-xs font-semibold">
        <input type="checkbox" name="options[{{ $i }}][is_correct]" value="1" class="h-4 w-4 accent-[#6c5ce7]" @checked(! empty($o['is_correct']))> Doğru
    </label>
    <button type="button" class="btn-danger btn-sm" data-remove-option><span class="material-symbols-outlined text-[16px]">close</span></button>
</div>
