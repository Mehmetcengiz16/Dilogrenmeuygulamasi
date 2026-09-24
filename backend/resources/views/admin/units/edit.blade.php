<x-admin-layout title="Ünite Düzenle" :breadcrumbs="['Kurslar' => route('admin.courses.index'), $unit->course->title => route('admin.courses.show', $unit->course), 'Ünite Düzenle' => null]">
    <h1 class="mb-6 text-[28px] font-bold leading-9 tracking-tight">Ünite Düzenle</h1>
    <form method="POST" action="{{ route('admin.units.update', $unit) }}" class="card grid gap-5">
        @csrf @method('PUT')
        <x-field name="title" label="Ünite adı" :value="$unit->title" required />
        <x-field name="description" label="Açıklama" type="textarea" :value="$unit->description" />
        <x-field name="is_published" label="Yayında" type="checkbox" :value="$unit->is_published" />
        <div class="flex justify-end gap-2">
            <a href="{{ route('admin.courses.show', $unit->course) }}" class="btn-soft">Vazgeç</a>
            <button class="btn-primary"><span class="material-symbols-outlined text-[18px]">save</span>Kaydet</button>
        </div>
    </form>
</x-admin-layout>
