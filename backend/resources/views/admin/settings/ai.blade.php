<x-admin-layout title="Yapay Zekâ Ayarları" :breadcrumbs="['Yapay Zekâ Ayarları' => null]">
    <x-slot:actions>
        <form method="POST" action="{{ route('admin.settings.ai.test') }}">
            @csrf
            <button class="btn-soft"><span class="material-symbols-outlined text-[18px]">network_check</span>Bağlantıyı Test Et</button>
        </form>
    </x-slot:actions>

    <div class="mb-6 flex flex-wrap items-end justify-between gap-4">
        <div>
            <h1 class="text-[28px] font-bold leading-9 tracking-tight">Yapay Zekâ Ayarları</h1>
            <p class="text-sm text-on-surface-variant">Mobil uygulamadaki AI Konuşma Asistanı ve serbest çeviri bu ayarlarla çalışır.</p>
        </div>
        @if ($active)
            <span class="chip-ok px-3 py-1"><span class="h-2 w-2 rounded-full bg-tertiary"></span>Aktif: {{ $active }}</span>
        @else
            <span class="chip-muted px-3 py-1">Çevrimdışı mod (sözlük + hazır yanıtlar)</span>
        @endif
    </div>

    @error('ai')
        <div class="mb-4 flex items-start gap-2 rounded-2xl bg-error-container px-4 py-3 text-sm text-error">
            <span class="material-symbols-outlined text-[20px]">error</span>{{ $message }}
        </div>
    @enderror

    <form method="POST" action="{{ route('admin.settings.ai.update') }}" class="grid gap-6">
        @csrf
        @method('PUT')

        {{-- Sağlayıcı seçimi --}}
        <div class="card">
            <h2 class="mb-4 font-semibold">Sağlayıcı</h2>
            <div class="grid gap-3 md:grid-cols-3">
                @foreach ($providers as $value => $label)
                    <label class="cursor-pointer">
                        <input type="radio" name="provider" value="{{ $value }}" class="peer hidden" @checked(old('provider', $provider) === $value)>
                        <div class="flex items-center gap-3 rounded-2xl border-2 border-transparent bg-surface-low p-4 transition peer-checked:border-primary-container peer-checked:bg-primary-fixed/40">
                            <span class="flex h-10 w-10 items-center justify-center rounded-full bg-white text-primary shadow-sm">
                                <span class="material-symbols-outlined">{{ ['openrouter' => 'hub', 'anthropic' => 'smart_toy', 'off' => 'cloud_off'][$value] }}</span>
                            </span>
                            <div>
                                <div class="text-sm font-semibold">{{ $label }}</div>
                                <div class="text-xs text-on-surface-variant">
                                    {{ ['openrouter' => 'Tek anahtarla yüzlerce model', 'anthropic' => 'Doğrudan Claude API', 'off' => 'API çağrısı yapılmaz'][$value] }}
                                </div>
                            </div>
                        </div>
                    </label>
                @endforeach
            </div>
        </div>

        {{-- OpenRouter --}}
        <div class="card grid gap-5 md:grid-cols-2">
            <div class="md:col-span-2 flex items-center justify-between">
                <h2 class="flex items-center gap-2 font-semibold"><span class="material-symbols-outlined text-primary">hub</span>OpenRouter</h2>
                <a href="https://openrouter.ai/keys" target="_blank" rel="noopener" class="text-xs font-semibold text-primary hover:underline">API anahtarı al ↗</a>
            </div>
            <div>
                <label for="f-openrouter_key" class="label">API anahtarı</label>
                <input id="f-openrouter_key" type="password" name="openrouter_key" autocomplete="off" class="input"
                       placeholder="{{ $openrouterKeyHint ? 'Kayıtlı: '.$openrouterKeyHint.' (değiştirmek için yazın)' : 'sk-or-v1-...' }}">
                <p class="mt-1 text-xs text-on-surface-variant">Anahtar şifreli saklanır. Boş bırakırsanız mevcut anahtar korunur.</p>
                @if ($openrouterKeyHint)
                    <label class="mt-2 flex items-center gap-2 text-xs font-semibold text-error">
                        <input type="checkbox" name="clear_openrouter_key" value="1" class="h-4 w-4 accent-[#ba1a1a]"> Kayıtlı anahtarı sil
                    </label>
                @endif
            </div>
            <div>
                <div class="mb-1.5 flex items-center justify-between">
                    <label for="f-openrouter_model" class="text-xs font-semibold text-on-surface-variant">Model</label>
                    <button form="refresh-models" class="text-xs font-semibold text-primary hover:underline">Listeyi yenile</button>
                </div>
                <input id="f-openrouter_model" name="openrouter_model" list="openrouter-models" class="input"
                       value="{{ old('openrouter_model', $openrouterModel) }}" placeholder="ör. anthropic/claude-sonnet-4.5">
                <datalist id="openrouter-models">
                    @foreach ($models as $m)
                        <option value="{{ $m['id'] }}">{{ $m['name'] }}</option>
                    @endforeach
                </datalist>
                <p class="mt-1 text-xs text-on-surface-variant">
                    {{ count($models) ? count($models).' model listelendi; yazmaya başlayınca öneriler çıkar.' : 'Model listesi alınamadı; model kimliğini elle yazabilirsiniz.' }}
                    JSON çıktı destekleyen bir model seçin.
                </p>
                @error('openrouter_model')<p class="mt-1 text-xs text-error">{{ $message }}</p>@enderror
            </div>
        </div>

        {{-- Anthropic --}}
        <div class="card grid gap-5 md:grid-cols-2">
            <h2 class="flex items-center gap-2 font-semibold md:col-span-2"><span class="material-symbols-outlined text-primary">smart_toy</span>Anthropic (Claude)</h2>
            <div>
                <label for="f-anthropic_key" class="label">API anahtarı</label>
                <input id="f-anthropic_key" type="password" name="anthropic_key" autocomplete="off" class="input"
                       placeholder="{{ $anthropicKeyHint ? 'Kayıtlı: '.$anthropicKeyHint.' (değiştirmek için yazın)' : 'sk-ant-...' }}">
                @if ($anthropicKeyHint)
                    <label class="mt-2 flex items-center gap-2 text-xs font-semibold text-error">
                        <input type="checkbox" name="clear_anthropic_key" value="1" class="h-4 w-4 accent-[#ba1a1a]"> Kayıtlı anahtarı sil
                    </label>
                @endif
            </div>
            <x-field name="anthropic_model" label="Model" :value="$anthropicModel" help="Varsayılan: claude-opus-5" />
        </div>

        <div class="flex justify-end">
            <button class="btn-primary"><span class="material-symbols-outlined text-[18px]">save</span>Kaydet</button>
        </div>
    </form>

    <form id="refresh-models" method="POST" action="{{ route('admin.settings.ai.models') }}" class="hidden">@csrf</form>
</x-admin-layout>
