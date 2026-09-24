<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Services\AiService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Validation\Rule;
use Illuminate\View\View;
use RuntimeException;

/** Yapay zekâ sağlayıcısı, API anahtarları ve model seçimi (yalnızca Süper Admin). */
class AiSettingsController extends Controller
{
    public function edit(AiService $ai): View
    {
        return view('admin.settings.ai', [
            'providers' => AiService::PROVIDERS,
            'provider' => Setting::get('ai.provider', $ai->provider()),
            'openrouterModel' => Setting::get('ai.openrouter_model'),
            'anthropicModel' => Setting::get('ai.anthropic_model', config('services.anthropic.model')),
            'openrouterKeyHint' => self::mask(Setting::get('ai.openrouter_key')),
            'anthropicKeyHint' => self::mask(Setting::get('ai.anthropic_key', config('services.anthropic.key'))),
            'models' => AiService::openRouterModels(),
            'active' => $ai->enabled() ? $ai->providerLabel().' · '.$ai->model() : null,
        ]);
    }

    public function update(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'provider' => ['required', Rule::in(array_keys(AiService::PROVIDERS))],
            'openrouter_key' => ['nullable', 'string', 'max:300'],
            'openrouter_model' => ['nullable', 'string', 'max:150', 'required_if:provider,openrouter'],
            'anthropic_key' => ['nullable', 'string', 'max:300'],
            'anthropic_model' => ['nullable', 'string', 'max:100', 'required_if:provider,anthropic'],
            'clear_openrouter_key' => ['boolean'],
            'clear_anthropic_key' => ['boolean'],
        ], [], [
            'openrouter_model' => 'OpenRouter modeli',
            'anthropic_model' => 'Anthropic modeli',
        ]);

        Setting::set('ai.provider', $data['provider']);
        Setting::set('ai.openrouter_model', $data['openrouter_model'] ?? null);
        Setting::set('ai.anthropic_model', $data['anthropic_model'] ?? null);

        // Boş bırakılan anahtar alanı mevcut anahtarı korur; "Anahtarı sil" işaretliyse temizlenir.
        foreach (['openrouter', 'anthropic'] as $p) {
            if ($request->boolean("clear_{$p}_key")) {
                Setting::set("ai.{$p}_key", null, encrypted: true);
            } elseif (filled($data["{$p}_key"] ?? null)) {
                Setting::set("ai.{$p}_key", trim($data["{$p}_key"]), encrypted: true);
            }
        }

        $ai = new AiService;
        if ($data['provider'] !== 'off' && ! $ai->enabled()) {
            return back()->with('status', 'Ayarlar kaydedildi, ancak seçili sağlayıcı için API anahtarı eksik; uygulama çevrimdışı modda çalışacak.');
        }

        return back()->with('status', 'Yapay zekâ ayarları kaydedildi');
    }

    public function test(): RedirectResponse
    {
        try {
            $reply = (new AiService)->test();
        } catch (RuntimeException $e) {
            return back()->withErrors(['ai' => 'Bağlantı testi başarısız: '.$e->getMessage()]);
        }

        return back()->with('status', 'Bağlantı başarılı. Örnek çeviri: "'.$reply.'"');
    }

    public function refreshModels(): RedirectResponse
    {
        Cache::forget('openrouter_models');
        $count = count(AiService::openRouterModels());

        return back()->with('status', "OpenRouter model listesi yenilendi ({$count} model)");
    }

    private static function mask(?string $key): ?string
    {
        if (blank($key)) {
            return null;
        }

        return mb_substr($key, 0, 6).'…'.mb_substr($key, -4);
    }
}
