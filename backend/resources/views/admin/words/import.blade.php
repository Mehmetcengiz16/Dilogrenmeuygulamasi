<x-admin-layout title="CSV İçe Aktar" :breadcrumbs="['Kelime Bankası' => route('admin.words.index'), 'CSV İçe Aktar' => null]">
    <h1 class="mb-6 text-[28px] font-bold leading-9 tracking-tight">Kelimeleri CSV ile İçe Aktar</h1>

    <div class="grid gap-6 md:grid-cols-5">
        <form method="POST" action="{{ route('admin.words.import.store') }}" enctype="multipart/form-data" class="card grid gap-5 md:col-span-3">
            @csrf
            <x-field name="language_id" label="Dil" :options="$languages" required />
            <x-field name="csv" label="CSV dosyası" type="file" accept=".csv,text/csv" required />
            <div class="flex justify-end">
                <button class="btn-primary"><span class="material-symbols-outlined text-[18px]">upload</span>İçe Aktar</button>
            </div>
        </form>
        <div class="card md:col-span-2">
            <h2 class="mb-2 font-semibold">Beklenen biçim</h2>
            <p class="mb-3 text-sm text-on-surface-variant">İlk satır başlık olmalı. Aynı kelime varsa güncellenir.</p>
            <pre class="overflow-x-auto rounded-2xl bg-surface-low p-3 text-xs">word,translation,example_sentence,example_translation,level
apple,elma,I eat an apple.,Bir elma yerim.,A1
journey,yolculuk,,,B1</pre>
        </div>
    </div>
</x-admin-layout>
