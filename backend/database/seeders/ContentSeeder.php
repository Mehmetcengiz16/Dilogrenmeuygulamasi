<?php

namespace Database\Seeders;

use App\Models\Admin;
use App\Models\Badge;
use App\Models\ConversationScenario;
use App\Models\Course;
use App\Models\Language;
use App\Models\Phrase;
use App\Models\Tip;
use App\Models\Word;
use Illuminate\Database\Seeder;

/** Tasarımlardaki içeriklerle uyumlu demo içerik: Türkçe → İngilizce B1 kursu. */
class ContentSeeder extends Seeder
{
    private const MASCOT = 'https://lh3.googleusercontent.com/aida-public/AB6AXuCawQLtse42lmDk-FHY0cngyxsoevL9KjjmP-ZPz_5SSKpr9__ifUHxQqS1bw6Rc2gTOzRx9a8GV_1oqTbDpH9sriPRXV5tO_c58D7DMRo1PZz8SnGjY-okdKCebr6S5Unum2U7Xoe_p0dNO_whHedvXpDt8kpU1X4bz5Xf3GZoadcCh3fj6b14ermtwiIhRczR8fH6OONeZK_wUkGggboLrTAiH3FGSmCL1IbcOjefaykX4rXqPUgWtQ';

    public function run(): void
    {
        Admin::updateOrCreate(['email' => 'admin@linguaai.test'], [
            'name' => 'Süper Admin', 'password' => 'password', 'role' => Admin::ROLE_SUPER,
        ]);

        $tr = Language::updateOrCreate(['code' => 'tr'], ['name' => 'Türkçe', 'flag' => '🇹🇷']);
        $en = Language::updateOrCreate(['code' => 'en'], ['name' => 'İngilizce', 'flag' => '🇬🇧']);
        Language::updateOrCreate(['code' => 'de'], ['name' => 'Almanca', 'flag' => '🇩🇪']);

        $words = $this->words($en);

        $course = Course::create([
            'source_language_id' => $tr->id,
            'target_language_id' => $en->id,
            'title' => 'İngilizce B1',
            'description' => 'Günlük hayatta akıcı konuşmak için orta seviye İngilizce.',
            'level' => 'B1',
            'is_published' => true,
        ]);

        foreach ($this->curriculum() as $u => $unitData) {
            $unit = $course->units()->create([
                'title' => $unitData['title'], 'description' => $unitData['description'],
                'order' => $u + 1, 'is_published' => true,
            ]);
            foreach ($unitData['lessons'] as $l => $lessonData) {
                $lesson = $unit->lessons()->create([
                    'title' => $lessonData['title'],
                    'description' => $lessonData['description'],
                    'skill' => $lessonData['skill'],
                    'estimated_minutes' => $lessonData['minutes'],
                    'time_limit_seconds' => 600,
                    'xp_reward' => 20,
                    'order' => $l + 1,
                    'is_published' => true,
                ]);
                foreach ($this->exercisesFor($lessonData['topic']) as $e => $ex) {
                    $options = $ex['options'] ?? [];
                    unset($ex['options']);
                    $exercise = $lesson->exercises()->create($ex + ['order' => $e + 1, 'xp' => 10]);
                    foreach ($options as $o => $opt) {
                        $exercise->options()->create($opt + ['order' => $o + 1]);
                    }
                }
                $lesson->words()->sync($words->whereIn('word', $lessonData['words'])->pluck('id'));
            }
        }

        $this->phrases($en);
        $this->scenarios($en);
        $this->tips();
        $this->badges();
    }

    private function words(Language $en)
    {
        $list = [
            ['silk', 'ipek', 'The spider makes its web from silk.', 'Örümcek ağını ipekten yapar.'],
            ['web', 'ağ', 'Look at that beautiful spider web.', 'Şu güzel örümcek ağına bak.'],
            ['coffee shop', 'kahve dükkanı', 'Where is the nearest coffee shop?', 'En yakın kahve dükkanı nerede?'],
            ['menu', 'menü', 'Could I see the menu, please?', 'Menüyü görebilir miyim lütfen?'],
            ['order', 'sipariş vermek', 'I would like to order a salad.', 'Bir salata sipariş etmek istiyorum.'],
            ['bill', 'hesap', 'Can we have the bill, please?', 'Hesabı alabilir miyiz lütfen?'],
            ['ticket', 'bilet', 'I need a ticket to London.', 'Londra\'ya bir bilete ihtiyacım var.'],
            ['luggage', 'bagaj', 'My luggage is too heavy.', 'Bagajım çok ağır.'],
            ['departure', 'kalkış', 'The departure time is 9 a.m.', 'Kalkış saati sabah 9.'],
            ['appointment', 'randevu', 'I have an appointment at noon.', 'Öğlen bir randevum var.'],
            ['ephemeral', 'geçici, kısa ömürlü', 'Fame is often ephemeral.', 'Şöhret çoğu zaman geçicidir.'],
            ['pronunciation', 'telaffuz', 'Your pronunciation is getting better.', 'Telaffuzun gittikçe gelişiyor.'],
            ['experience', 'deneyim', 'I have five years of experience.', 'Beş yıllık deneyimim var.'],
            ['weather', 'hava durumu', 'The weather is lovely today.', 'Bugün hava çok güzel.'],
            ['neighbour', 'komşu', 'My neighbour is very friendly.', 'Komşum çok arkadaş canlısı.'],
        ];

        foreach ($list as [$w, $t, $ex, $exT]) {
            Word::create([
                'language_id' => $en->id, 'word' => $w, 'translation' => $t,
                'example_sentence' => $ex, 'example_translation' => $exT, 'level' => 'B1',
            ]);
        }

        return Word::where('language_id', $en->id)->get();
    }

    private function curriculum(): array
    {
        return [
            [
                'title' => 'Doğa ve Hayvanlar', 'description' => 'Canlılar ve doğa hakkında konuşma.',
                'lessons' => [
                    ['title' => 'Örümcekler ve Böcekler', 'description' => 'Doğadaki küçük canlıları tanı.', 'skill' => 'vocabulary', 'minutes' => 8, 'topic' => 'nature', 'words' => ['silk', 'web']],
                    ['title' => 'Hava Durumu', 'description' => 'Havadan bahsetmeyi öğren.', 'skill' => 'vocabulary', 'minutes' => 10, 'topic' => 'weather', 'words' => ['weather']],
                    ['title' => 'Komşularla Sohbet', 'description' => 'Günlük selamlaşma ve küçük sohbetler.', 'skill' => 'speaking', 'minutes' => 12, 'topic' => 'daily', 'words' => ['neighbour']],
                    ['title' => 'Doğa Tekrarı', 'description' => 'Ünitede öğrendiklerini pekiştir.', 'skill' => 'grammar', 'minutes' => 10, 'topic' => 'nature', 'words' => []],
                ],
            ],
            [
                'title' => 'Restoran ve Kafe', 'description' => 'Sipariş verme ve ödeme yapma.',
                'lessons' => [
                    ['title' => 'Kafede Sipariş', 'description' => 'Kahve dükkanında sipariş vermeyi öğren.', 'skill' => 'speaking', 'minutes' => 12, 'topic' => 'cafe', 'words' => ['coffee shop', 'order']],
                    ['title' => 'Menüyü Okumak', 'description' => 'Menüdeki yemekleri anla.', 'skill' => 'vocabulary', 'minutes' => 10, 'topic' => 'restaurant', 'words' => ['menu']],
                    ['title' => 'Hesabı İstemek', 'description' => 'Kibarca hesap iste ve öde.', 'skill' => 'speaking', 'minutes' => 8, 'topic' => 'restaurant', 'words' => ['bill']],
                    ['title' => 'Restoran Diyaloğu', 'description' => 'Tam bir restoran diyaloğunu dinle.', 'skill' => 'listening', 'minutes' => 15, 'topic' => 'cafe', 'words' => []],
                ],
            ],
            [
                'title' => 'Seyahat', 'description' => 'Havalimanı, bilet ve yol tarifi.',
                'lessons' => [
                    ['title' => 'Havalimanında', 'description' => 'Check-in ve bagaj işlemleri.', 'skill' => 'vocabulary', 'minutes' => 10, 'topic' => 'travel', 'words' => ['ticket', 'luggage', 'departure']],
                    ['title' => 'Yol Tarifi', 'description' => 'Yol sormayı ve tarif etmeyi öğren.', 'skill' => 'listening', 'minutes' => 12, 'topic' => 'cafe', 'words' => []],
                    ['title' => 'İş Görüşmesi', 'description' => 'Kendini profesyonelce tanıt.', 'skill' => 'speaking', 'minutes' => 15, 'topic' => 'work', 'words' => ['appointment', 'experience']],
                    ['title' => 'İngilizce Dinleme ve Telaffuz', 'description' => 'Gerçek senaryolarla aksanını doğal ve akıcı hale getir.', 'skill' => 'listening', 'minutes' => 48, 'topic' => 'pronunciation', 'words' => ['pronunciation', 'ephemeral']],
                ],
            ],
        ];
    }

    private function exercisesFor(string $topic): array
    {
        $mc = fn (string $prompt, array $opts, int $correct, string $explanation, string $category = 'Kelime & Kavram', ?string $image = null) => [
            'type' => 'multiple_choice',
            'category' => $category,
            'instruction' => 'Doğru cevabı seçin',
            'prompt' => $prompt,
            'explanation' => $explanation,
            'image_path' => $image,
            'options' => collect($opts)->map(fn ($o, $i) => ['text' => $o[0], 'translation' => $o[1], 'is_correct' => $i === $correct])->all(),
        ];

        $order = fn (string $sentence, string $translation) => [
            'type' => 'sentence_order',
            'category' => 'Cümle Kurma',
            'instruction' => 'Kelimeleri doğru sıraya dizin',
            'prompt' => $translation,
            'prompt_translation' => $sentence,
            'correct_answer' => ['text' => $sentence],
            'explanation' => 'Doğru cümle: '.$sentence,
            'options' => collect(explode(' ', $sentence))->shuffle()->map(fn ($w) => ['text' => $w, 'is_correct' => true])->all(),
        ];

        $fill = fn (string $prompt, string $answer, string $translation) => [
            'type' => 'fill_blank',
            'category' => 'Dil Bilgisi',
            'instruction' => 'Boşluğu doldurun',
            'prompt' => $prompt,
            'prompt_translation' => $translation,
            'correct_answer' => ['text' => $answer],
            'explanation' => 'Doğru cevap: '.$answer,
        ];

        $listen = fn (string $sentence, string $translation) => [
            'type' => 'listen_write',
            'category' => 'Dinleme',
            'instruction' => 'Dinlediğinizi yazın',
            'prompt' => $sentence,
            'prompt_translation' => $translation,
            'correct_answer' => ['text' => $sentence],
            'explanation' => 'Cümlenin anlamı: '.$translation,
        ];

        $match = fn (array $pairs) => [
            'type' => 'match_pairs',
            'category' => 'Eşleştirme',
            'instruction' => 'Kelimeleri eşleştirin',
            'prompt' => 'Kelimeleri anlamlarıyla eşleştirin',
            'explanation' => 'Tüm eşleşmeler doğru!',
            'options' => collect($pairs)->flatMap(fn ($p, $i) => [
                ['text' => $p[0], 'pair_key' => "p$i", 'is_correct' => true],
                ['text' => $p[1], 'pair_key' => "p$i", 'is_correct' => true],
            ])->all(),
        ];

        return match ($topic) {
            'nature' => [
                $mc('“Örümcek ağını örmek için ne kullanır?”', [['Dişlerini', 'Teeth'], ['İpek', 'Silk'], ['Bacaklarını', 'Legs'], ['Kanatlarını', 'Wings']], 1, 'İpek protein bazlı liflerden üretilir.', 'Kelime & Kavram', self::MASCOT),
                $mc('“Web” kelimesinin Türkçe karşılığı nedir?', [['Ağ', 'Web'], ['Yuva', 'Nest'], ['Ağaç', 'Tree'], ['Yaprak', 'Leaf']], 0, 'Spider web = örümcek ağı.'),
                $match([['silk', 'ipek'], ['web', 'ağ'], ['leg', 'bacak'], ['wing', 'kanat']]),
                $fill('The spider makes its web from ___.', 'silk', 'Örümcek ağını ipekten yapar.'),
                $order('Spiders have eight legs', 'Örümceklerin sekiz bacağı vardır'),
            ],
            'weather' => [
                $mc('“It is raining cats and dogs” ne anlama gelir?', [['Bardaktan boşanırcasına yağıyor', 'Heavy rain'], ['Kedi köpek yağıyor', 'Literal'], ['Hava güneşli', 'Sunny'], ['Kar yağıyor', 'Snowing']], 0, 'Bu bir deyimdir ve çok şiddetli yağmuru anlatır.', 'Deyimler'),
                $fill('The weather ___ lovely today.', 'is', 'Bugün hava çok güzel.'),
                $match([['sunny', 'güneşli'], ['cloudy', 'bulutlu'], ['windy', 'rüzgârlı'], ['cold', 'soğuk']]),
                $listen('It is very cold today', 'Bugün hava çok soğuk'),
            ],
            'daily' => [
                $mc('Komşunuza sabah nasıl selam verirsiniz?', [['Good morning!', 'Günaydın!'], ['Good night!', 'İyi geceler!'], ['Goodbye!', 'Hoşça kal!'], ['Welcome!', 'Hoş geldin!']], 0, 'Sabahları “Good morning” kullanılır.', 'Günlük Konuşma'),
                $order('How are you today', 'Bugün nasılsın'),
                $fill('Nice to ___ you.', 'meet', 'Tanıştığıma memnun oldum.'),
                $listen('My neighbour is very friendly', 'Komşum çok arkadaş canlısı'),
            ],
            'cafe' => [
                $mc('Kafede kahve sipariş ederken hangisi en kibardır?', [['I would like a coffee, please.', 'Bir kahve rica ediyorum.'], ['Give me coffee.', 'Bana kahve ver.'], ['Coffee now.', 'Hemen kahve.'], ['I want coffee!', 'Kahve istiyorum!']], 0, '“I would like…” kibar bir istek kalıbıdır.', 'Günlük Konuşma'),
                $fill('Where is the nearest coffee ___?', 'shop', 'En yakın kahve dükkanı nerede?'),
                $order('Can I have a latte please', 'Bir latte alabilir miyim lütfen'),
                $listen('Where is the nearest coffee shop', 'En yakın kahve dükkanı nerede'),
                $match([['coffee', 'kahve'], ['tea', 'çay'], ['sugar', 'şeker'], ['milk', 'süt']]),
            ],
            'restaurant' => [
                $mc('“The check, please” ne demektir?', [['Hesap lütfen', 'The check, please'], ['Menü lütfen', 'The menu, please'], ['Su lütfen', 'Water, please'], ['Masa lütfen', 'A table, please']], 0, 'Amerikan İngilizcesinde hesap “check”, İngiliz İngilizcesinde “bill” denir.', 'Günlük Konuşma'),
                $match([['starter', 'başlangıç'], ['main course', 'ana yemek'], ['dessert', 'tatlı'], ['drink', 'içecek']]),
                $fill('Could I see the ___, please?', 'menu', 'Menüyü görebilir miyim lütfen?'),
                $order('Can we have the bill please', 'Hesabı alabilir miyiz lütfen'),
            ],
            'travel' => [
                $mc('“Luggage” kelimesinin anlamı nedir?', [['Bagaj', 'Luggage'], ['Bilet', 'Ticket'], ['Pasaport', 'Passport'], ['Uçak', 'Plane']], 0, 'Luggage = bagaj; sayılamayan bir isimdir.'),
                $fill('The ___ time is 9 a.m.', 'departure', 'Kalkış saati sabah 9.'),
                $match([['ticket', 'bilet'], ['gate', 'kapı'], ['flight', 'uçuş'], ['passport', 'pasaport']]),
                $listen('I need a ticket to London', 'Londra\'ya bir bilete ihtiyacım var'),
            ],
            'work' => [
                $mc('Görüşmede kendinizi tanıtırken hangisi uygundur?', [['I have five years of experience.', 'Beş yıllık deneyimim var.'], ['I am very tired.', 'Çok yorgunum.'], ['I don\'t know.', 'Bilmiyorum.'], ['See you later.', 'Sonra görüşürüz.']], 0, 'Deneyiminizden bahsetmek iyi bir başlangıçtır.', 'İş İngilizcesi'),
                $order('I have an appointment at noon', 'Öğlen bir randevum var'),
                $fill('I have five years of ___.', 'experience', 'Beş yıllık deneyimim var.'),
            ],
            default => [
                $mc('“Ephemeral” kelimesinin anlamı nedir?', [['Geçici', 'Ephemeral'], ['Kalıcı', 'Permanent'], ['Büyük', 'Huge'], ['Hızlı', 'Fast']], 0, 'Ephemeral = kısa ömürlü, geçici.'),
                $listen('Your pronunciation is getting better', 'Telaffuzun gittikçe gelişiyor'),
                $order('Practice makes perfect', 'Pratik mükemmelleştirir'),
                $fill('Fame is often ___.', 'ephemeral', 'Şöhret çoğu zaman geçicidir.'),
            ],
        };
    }

    private function phrases(Language $en): void
    {
        $quick = [
            ['Hello', 'Merhaba', '👋', '/me-ra-ba/'],
            ['Thank you very much', 'Teşekkürler', '🙏', '/te-şek-kür-ler/'],
            ['The check, please', 'Hesap lütfen', '🧾', '/he-sap lüt-fen/'],
            ['Excuse me', 'Pardon', '✨', '/par-don/'],
            ['How much is this?', 'Ne kadar?', '🏷️', '/ne ka-dar/'],
            ['Where is the nearest coffee shop?', 'En yakın kahve dükkanı nerede?', '☕', '/en ya-kın kah-ve dük-ka-nı ne-re-de/'],
        ];
        foreach ($quick as $i => [$text, $tr, $emoji, $pron]) {
            Phrase::create(['language_id' => $en->id, 'type' => 'quick', 'text' => $text, 'translation' => $tr, 'emoji' => $emoji, 'pronunciation' => $pron, 'order' => $i + 1]);
        }

        $idioms = [
            ['Piece of cake', 'Çocuk oyuncağı'],
            ['Break the ice', 'Buzları eritmek'],
            ['Hit the books', 'Kitaplara gömülmek'],
            ['Under the weather', 'Keyifsiz, hasta'],
        ];
        foreach ($idioms as [$text, $tr]) {
            Phrase::create(['language_id' => $en->id, 'type' => 'idiom', 'text' => $text, 'translation' => $tr]);
        }
    }

    private function scenarios(Language $en): void
    {
        $list = [
            ['Sipariş Verme', 'Günün konusu: "Restoranda sipariş verme ve spontane sohbet".', 'restaurant', 24, 'Hi! Welcome to our restaurant. Are you ready to order, or would you like a few more minutes?', 'You are a friendly waiter in a London restaurant. Take the learner\'s order and chat naturally.', true],
            ['Seyahat Kalıpları', 'Havalimanı, otel ve yol tarifi diyalogları.', 'flight_takeoff', 15, 'Good morning! Where are you flying to today?', 'You are an airline check-in agent. Help the learner check in and practise travel phrases.', false],
            ['İş Görüşmesi Simülasyonu', 'Kendini profesyonelce tanıtma pratiği.', 'work', 20, 'Thanks for coming in today. Could you start by telling me a little about yourself?', 'You are a friendly hiring manager running a job interview. Ask one question at a time.', false],
            ['Haftalık Özet', 'Haftanı İngilizce anlat, AI geri bildirim versin.', 'summarize', 10, 'Hi! How was your week? Tell me about something interesting that happened.', 'Ask the learner about their week and help them tell it in the past tense.', false],
        ];
        foreach ($list as $i => [$title, $desc, $icon, $min, $opening, $prompt, $featured]) {
            ConversationScenario::create([
                'language_id' => $en->id, 'title' => $title, 'description' => $desc, 'icon' => $icon,
                'estimated_minutes' => $min, 'opening_message' => $opening, 'system_prompt' => $prompt,
                'is_featured' => $featured, 'order' => $i + 1, 'level' => 'B1',
            ]);
        }
    }

    private function tips(): void
    {
        foreach ([
            'Düşüncelerini içinden Türkçe değil, doğrudan basit İngilizce cümlelerle oluşturmayı dene.',
            'Yeni öğrendiğin kelimeyi bugün en az üç farklı cümlede kullan.',
            'Sevdiğin bir diziyi İngilizce altyazıyla izlemek kulağını hızla geliştirir.',
            'Hata yapmaktan korkma; her hata bir sonraki doğru cümlenin provasıdır.',
        ] as $text) {
            Tip::create(['text' => $text]);
        }
    }

    private function badges(): void
    {
        foreach ([
            ['first_lesson', 'İlk Adım', 'İlk dersini tamamla', 'school', 'lessons', 1],
            ['streak_7', 'Haftalık Seri', '7 gün üst üste çalış', 'local_fire_department', 'streak', 7],
            ['xp_500', 'XP Avcısı', '500 XP topla', 'bolt', 'xp', 500],
            ['words_50', 'Kelime Ustası', '50 kelime öğren', 'menu_book', 'words', 50],
            ['lessons_10', 'Azimli Öğrenci', '10 ders tamamla', 'military_tech', 'lessons', 10],
        ] as [$code, $name, $desc, $icon, $rule, $threshold]) {
            Badge::create(compact('code', 'name', 'icon', 'rule', 'threshold') + ['description' => $desc]);
        }
    }
}
