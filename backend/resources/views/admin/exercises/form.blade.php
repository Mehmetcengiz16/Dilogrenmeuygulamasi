@php
    use App\Enums\ExerciseType;
    $editing = $exercise !== null;
    $type = old('type', $exercise?->type->value ?? 'multiple_choice');
    $options = old('options', $exercise
        ? $exercise->options->map(fn ($o) => $o->only(['text', 'translation', 'pair_key', 'is_correct']))->all()
        : [['text' => '', 'is_correct' => true], ['text' => ''], ['text' => ''], ['text' => '']]);
    $optionTypes = 'multiple_choice,image_select,match_pairs,sentence_order';
    $imageUrl = $exercise && str_starts_with((string) $exercise->image_path, 'http') ? $exercise->image_path : null;
@endphp
<x-admin-layout :title="$editing ? 'Alıştırma Düzenle' : 'Yeni Alıştırma'"
    :breadcrumbs="['Kurslar' => route('admin.courses.index'), $lesson->unit->course->title => route('admin.courses.show', $lesson->unit->course), $lesson->title => route('admin.lessons.show', $lesson), ($editing ? 'Alıştırma Düzenle' : 'Yeni Alıştırma') => null]">
    <h1 class="mb-6 text-[28px] font-bold leading-9 tracking-tight">{{ $editing ? 'Alıştırma Düzenle' : 'Yeni Alıştırma' }}</h1>

    <form method="POST" enctype="multipart/form-data" action="{{ $editing ? route('admin.exercises.update', $exercise) : route('admin.exercises.store', $lesson) }}" class="grid gap-6">
        @csrf
        @if ($editing) @method('PUT') @endif

        <div class="card grid gap-5 md:grid-cols-3">
            <x-field name="type" label="Alıştırma tipi" :options="ExerciseType::options()" :value="$type" data-exercise-type required />
            <x-field name="category" label="Kategori etiketi" :value="$exercise?->category ?? 'Kelime & Kavram'" help="Soru ekranındaki üst etiket" />
            <x-field name="xp" label="Doğru cevap XP'si" type="number" :value="$exercise?->xp ?? 10" required />
            <x-field name="instruction" label="Yönerge" :value="$exercise?->instruction ?? 'Doğru cevabı seçin'" class="md:col-span-3" />
            <x-field name="prompt" label="Soru metni" type="textarea" :value="$exercise?->prompt" required class="md:col-span-3"
                     help="Boşluk doldurma: boşluğu ___ ile gösterin. Dinle-yaz: seslendirilecek cümle. Cümle kurma: Türkçe cümle." />
            <x-field name="prompt_translation" label="Soru çevirisi / ipucu" :value="$exercise?->prompt_translation" class="md:col-span-3" />

            <div data-show-for="fill_blank,listen_write,sentence_order" class="md:col-span-3">
                <x-field name="answer" label="Doğru cevap" :value="$exercise?->correct_answer['text'] ?? null"
                         help="Cümle kurmada seçenek girmezseniz kelimeler bu cevaptan otomatik karıştırılır." />
            </div>
            <x-field name="explanation" label="Geri bildirim açıklaması" :value="$exercise?->explanation" class="md:col-span-3" help="Örn: İpek protein bazlı liflerden üretilir." />
        </div>

        <div class="card grid gap-5 md:grid-cols-2">
            <h2 class="font-semibold md:col-span-2">Medya</h2>
            <div class="grid gap-3">
                <x-field name="image" label="Görsel yükle (en fazla 1 MB)" type="file" accept="image/*" />
                <x-field name="image_url" label="veya görsel URL'si" type="url" :value="$imageUrl" />
                @if ($exercise?->image_path)
                    <div class="flex items-center gap-3">
                        <img src="{{ \App\Http\Resources\ExerciseResource::url($exercise->image_path) }}" class="h-20 w-20 rounded-2xl object-cover" alt="">
                        <x-field name="remove_image" label="Görseli kaldır" type="checkbox" />
                    </div>
                @endif
            </div>
            <div class="grid content-start gap-3">
                <x-field name="audio" label="Ses dosyası (mp3/m4a, en fazla 2 MB)" type="file" accept="audio/*"
                         help="Yüklenmezse uygulama metni cihazın sesiyle (TTS) okur." />
                @if ($exercise?->audio_path)
                    <audio controls src="{{ \App\Http\Resources\ExerciseResource::url($exercise->audio_path) }}" class="h-9 w-full"></audio>
                    <x-field name="remove_audio" label="Sesi kaldır" type="checkbox" />
                @endif
            </div>
        </div>

        <div class="card" data-show-for="{{ $optionTypes }}">
            <div class="mb-3 flex items-center justify-between">
                <div>
                    <h2 class="font-semibold">Seçenekler</h2>
                    <p class="text-xs text-on-surface-variant">Çoktan seçmeli: doğru olanları işaretleyin. Eşleştirme: eşleşen iki seçeneğe aynı çift anahtarını (p1, p2…) verin.</p>
                </div>
                <button type="button" class="btn-soft btn-sm" data-add-option><span class="material-symbols-outlined text-[16px]">add</span>Seçenek</button>
            </div>
            @error('options')<p class="mb-3 rounded-2xl bg-error-container px-3 py-2 text-xs text-error">{{ $message }}</p>@enderror
            <div class="grid gap-2" data-option-list>
                @foreach ($options as $i => $o)
                    @include('admin.exercises.option-row', ['i' => $i, 'o' => $o])
                @endforeach
            </div>
            <template id="option-template">@include('admin.exercises.option-row', ['i' => '__i__', 'o' => []])</template>
        </div>

        <div class="flex justify-end gap-2">
            <a href="{{ route('admin.lessons.show', $lesson) }}" class="btn-soft">Vazgeç</a>
            <button class="btn-primary"><span class="material-symbols-outlined text-[18px]">save</span>Kaydet</button>
        </div>
    </form>
</x-admin-layout>
