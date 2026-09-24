<?php

namespace App\Services;

use Anthropic\Client;
use Anthropic\Core\Exceptions\APIException;
use App\Models\ConversationScenario;
use App\Models\Phrase;
use App\Models\Setting;
use App\Models\Word;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * AI sohbet ve çeviri. Sağlayıcı, API anahtarı ve model admin panelden (Yapay Zekâ Ayarları) yönetilir;
 * panelde değer yoksa .env'deki ANTHROPIC_* değerlerine düşer. Hiç anahtar yoksa uygulama çalışmaya devam eder:
 * çeviri kelime/kalıp veritabanından, sohbet senaryo tabanlı hazır yanıtlardan beslenir.
 */
class AiService
{
    public const PROVIDERS = [
        'openrouter' => 'OpenRouter',
        'anthropic' => 'Anthropic (Claude)',
        'off' => 'Kapalı (çevrimdışı mod)',
    ];

    public const OPENROUTER_URL = 'https://openrouter.ai/api/v1';

    private string $provider;

    private ?string $apiKey;

    private ?string $model;

    public function __construct()
    {
        $this->provider = Setting::get('ai.provider', config('services.anthropic.key') ? 'anthropic' : 'off');
        [$this->apiKey, $this->model] = match ($this->provider) {
            'openrouter' => [Setting::get('ai.openrouter_key'), Setting::get('ai.openrouter_model')],
            'anthropic' => [
                Setting::get('ai.anthropic_key', config('services.anthropic.key')),
                Setting::get('ai.anthropic_model', config('services.anthropic.model')),
            ],
            default => [null, null],
        };
    }

    public function enabled(): bool
    {
        return $this->provider !== 'off' && filled($this->apiKey) && filled($this->model);
    }

    public function provider(): string
    {
        return $this->provider;
    }

    public function providerLabel(): string
    {
        return self::PROVIDERS[$this->provider] ?? $this->provider;
    }

    public function model(): ?string
    {
        return $this->model;
    }

    /**
     * Admin paneldeki "Bağlantıyı test et" için kısa bir çeviri ister; hatayı mesajıyla fırlatır.
     *
     * @throws RuntimeException
     */
    public function test(): string
    {
        if (! $this->enabled()) {
            throw new RuntimeException('Sağlayıcı, API anahtarı ve model seçilmeli.');
        }

        $data = $this->jsonRequest(
            'Translate the user text from English to Turkish.',
            [['role' => 'user', 'content' => 'Good morning, how are you?']],
            [
                'type' => 'object',
                'properties' => ['translation' => ['type' => 'string']],
                'required' => ['translation'],
                'additionalProperties' => false,
            ],
            300,
            throwErrors: true,
        );

        return (string) ($data['translation'] ?? json_encode($data, JSON_UNESCAPED_UNICODE));
    }

    /**
     * @param  array<int, array{role:string, content:string}>  $history
     * @return array{reply:string, translation:?string, feedback:?array{accuracy:int, fluency:string}}
     */
    public function chat(string $userName, string $targetLanguage, ?ConversationScenario $scenario, array $history): array
    {
        if (! $this->enabled()) {
            return $this->offlineChat($scenario, $history);
        }

        $system = "You are Lina, a warm and encouraging {$targetLanguage} speaking partner inside the LinguaAI language app. "
            ."The learner's name is {$userName}; their native language is Turkish. "
            .'Reply mostly in '.$targetLanguage.' using short, natural sentences (1-3 sentences) at the learner\'s level, '
            .'and end with a question that keeps the conversation going. If the learner makes a mistake, gently show the corrected sentence first. '
            .'If the learner writes in Turkish, help them say it in '.$targetLanguage.'.';
        if ($scenario?->system_prompt) {
            $system .= "\n\nScenario: ".$scenario->system_prompt;
        }

        $schema = [
            'type' => 'object',
            'properties' => [
                'reply' => ['type' => 'string', 'description' => 'Your reply to the learner'],
                'translation' => ['type' => 'string', 'description' => 'Turkish translation of your reply'],
                'accuracy' => ['type' => 'integer', 'description' => 'Grammar/wording accuracy of the learner\'s last message, 0-100'],
                'fluency' => ['type' => 'string', 'enum' => ['Düşük', 'Orta', 'Yüksek']],
            ],
            'required' => ['reply', 'translation', 'accuracy', 'fluency'],
            'additionalProperties' => false,
        ];

        $data = $this->jsonRequest($system, $history, $schema, 2000);
        if (! $data || ! isset($data['reply'])) {
            return $this->offlineChat($scenario, $history);
        }

        return [
            'reply' => $data['reply'],
            'translation' => $data['translation'] ?? null,
            'feedback' => ['accuracy' => (int) ($data['accuracy'] ?? 0), 'fluency' => $data['fluency'] ?? 'Orta'],
        ];
    }

    /** @return array{text:string, pronunciation:?string, confidence:int, source:string} */
    public function translate(string $text, string $from, string $to): array
    {
        $local = $this->localTranslate($text, $from, $to);
        if ($local || ! $this->enabled()) {
            return $local ?? ['text' => $text, 'pronunciation' => null, 'confidence' => 0, 'source' => 'none'];
        }

        $schema = [
            'type' => 'object',
            'properties' => [
                'translation' => ['type' => 'string'],
                'pronunciation' => ['type' => 'string', 'description' => 'Syllable-split pronunciation guide of the translation, e.g. /en ya-kın kah-ve/'],
                'confidence' => ['type' => 'integer', 'description' => '0-100'],
            ],
            'required' => ['translation', 'pronunciation', 'confidence'],
            'additionalProperties' => false,
        ];
        $system = "Translate the user's text from language code '{$from}' to language code '{$to}'. Keep the tone natural and everyday.";

        $data = $this->jsonRequest($system, [['role' => 'user', 'content' => $text]], $schema, 1500);
        if (! $data || ! isset($data['translation'])) {
            return ['text' => $text, 'pronunciation' => null, 'confidence' => 0, 'source' => 'none'];
        }

        return [
            'text' => $data['translation'],
            'pronunciation' => ($data['pronunciation'] ?? null) ?: null,
            'confidence' => (int) ($data['confidence'] ?? 0),
            'source' => 'ai',
        ];
    }

    /** OpenRouter model listesi (admin paneldeki model seçimi için, 1 saat önbellekte). */
    public static function openRouterModels(): array
    {
        return Cache::remember('openrouter_models', 3600, function () {
            try {
                $res = Http::timeout(15)->get(self::OPENROUTER_URL.'/models');
            } catch (ConnectionException) {
                return [];
            }

            return collect($res->json('data') ?? [])
                ->map(fn ($m) => ['id' => $m['id'], 'name' => $m['name'] ?? $m['id']])
                ->sortBy('id')->values()->all();
        });
    }

    /** Seçili sağlayıcıya JSON şemasına uyan yanıt isteği gönderir; hata olursa null (test modunda istisna). */
    private function jsonRequest(string $system, array $messages, array $schema, int $maxTokens, bool $throwErrors = false): ?array
    {
        try {
            $text = $this->provider === 'openrouter'
                ? $this->openRouterRequest($system, $messages, $schema, $maxTokens)
                : $this->anthropicRequest($system, $messages, $schema, $maxTokens);
        } catch (RuntimeException|APIException|ConnectionException $e) {
            Log::warning("AI isteği başarısız ({$this->provider}): ".$e->getMessage());
            if ($throwErrors) {
                throw new RuntimeException($e->getMessage(), 0, $e);
            }

            return null;
        }

        $data = $text === null ? null : self::decodeJson($text);
        if ($throwErrors && $data === null) {
            throw new RuntimeException('Model geçerli bir JSON yanıtı döndürmedi: '.mb_substr((string) $text, 0, 200));
        }

        return $data;
    }

    private function anthropicRequest(string $system, array $messages, array $schema, int $maxTokens): ?string
    {
        $client = new Client(apiKey: $this->apiKey);
        // Güvenlik sınıflandırıcısı reddederse sunucu tarafı yedek model devreye girer.
        $message = $client->beta->messages->create(
            maxTokens: $maxTokens,
            messages: $messages,
            model: $this->model,
            system: $system,
            outputConfig: ['effort' => 'low', 'format' => ['type' => 'json_schema', 'schema' => $schema]],
            fallbacks: 'default',
            betas: ['server-side-fallback-2026-07-01'],
        );

        if ($message->stopReason === 'refusal') {
            throw new RuntimeException('Model isteği reddetti.');
        }
        foreach ($message->content as $block) {
            if ($block->type === 'text') {
                return $block->text;
            }
        }

        return null;
    }

    /** OpenRouter: OpenAI uyumlu chat/completions uç noktası. */
    private function openRouterRequest(string $system, array $messages, array $schema, int $maxTokens): ?string
    {
        $response = Http::withToken($this->apiKey)
            ->withHeaders(['HTTP-Referer' => config('app.url'), 'X-Title' => config('app.name')])
            ->timeout(60)
            ->post(self::OPENROUTER_URL.'/chat/completions', [
                'model' => $this->model,
                'max_tokens' => $maxTokens,
                'messages' => [
                    // Yapılandırılmış çıktıyı desteklemeyen modeller için şema talimatı da eklenir.
                    ['role' => 'system', 'content' => $system."\n\nRespond ONLY with a JSON object matching this schema: ".json_encode($schema)],
                    ...$messages,
                ],
                'response_format' => [
                    'type' => 'json_schema',
                    'json_schema' => ['name' => 'response', 'strict' => true, 'schema' => $schema],
                ],
            ]);

        if ($response->failed()) {
            throw new RuntimeException($response->json('error.message') ?? ('HTTP '.$response->status()));
        }

        return $response->json('choices.0.message.content');
    }

    /** Model yanıtındaki JSON nesnesini çıkarır (kod bloğu içinde ya da metinle çevrili gelse bile). */
    private static function decodeJson(string $text): ?array
    {
        $data = json_decode($text, true);
        if (is_array($data)) {
            return $data;
        }
        if (preg_match('/\{.*\}/s', $text, $m)) {
            $data = json_decode($m[0], true);
        }

        return is_array($data) ? $data : null;
    }

    private function localTranslate(string $text, string $from, string $to): ?array
    {
        $needle = trim(mb_strtolower($text), " \t\n\r?!.");

        foreach (Phrase::where('is_active', true)->get() as $phrase) {
            if (trim(mb_strtolower($phrase->text), '?!.') === $needle) {
                return ['text' => $phrase->translation, 'pronunciation' => $phrase->pronunciation, 'confidence' => 99, 'source' => 'dictionary'];
            }
            if (trim(mb_strtolower($phrase->translation), '?!.') === $needle) {
                return ['text' => $phrase->text, 'pronunciation' => null, 'confidence' => 99, 'source' => 'dictionary'];
            }
        }

        $word = Word::whereRaw('LOWER(word) = ?', [$needle])->first();
        if ($word) {
            return ['text' => $word->translation, 'pronunciation' => null, 'confidence' => 95, 'source' => 'dictionary'];
        }
        $word = Word::whereRaw('LOWER(translation) = ?', [$needle])->first();
        if ($word) {
            return ['text' => $word->word, 'pronunciation' => $word->pronunciation, 'confidence' => 95, 'source' => 'dictionary'];
        }

        return null;
    }

    private function offlineChat(?ConversationScenario $scenario, array $history): array
    {
        $turn = count(array_filter($history, fn ($m) => $m['role'] === 'user'));
        $replies = [
            ['Great! Could you tell me a little more?', 'Harika! Biraz daha anlatır mısın?'],
            ['Nice sentence! What would you like to order?', 'Güzel cümle! Ne sipariş etmek istersin?'],
            ['Perfect. How would you ask for the bill?', 'Mükemmel. Hesabı nasıl istersin?'],
            ['Well done! Let\'s try another question: where are you from?', 'Aferin! Başka bir soru deneyelim: nerelisin?'],
        ];
        [$reply, $translation] = $replies[$turn % count($replies)];
        if ($scenario && $turn === 0) {
            $reply = $scenario->opening_message;
            $translation = null;
        }

        return [
            'reply' => $reply,
            'translation' => $translation,
            'feedback' => ['accuracy' => 90, 'fluency' => 'Orta'],
        ];
    }
}
