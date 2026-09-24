@props(['action', 'confirm' => 'Bu kaydı silmek istediğinize emin misiniz?', 'label' => null])
<form method="POST" action="{{ $action }}" data-confirm="{{ $confirm }}" class="inline">
    @csrf
    @method('DELETE')
    <button class="btn-danger btn-sm" title="Sil">
        <span class="material-symbols-outlined text-[16px]">delete</span>{{ $label }}
    </button>
</form>
