import Sortable from 'sortablejs';

// Sürükle-bırak sıralama: data-sortable="<reorder url>" olan listeler, çocuklarında data-id taşır.
document.querySelectorAll('[data-sortable]').forEach((list) => {
    Sortable.create(list, {
        handle: '[data-handle]',
        animation: 150,
        onEnd: () => {
            const ids = [...list.querySelectorAll(':scope > [data-id]')].map((el) => el.dataset.id);
            fetch(list.dataset.sortable, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
                    Accept: 'application/json',
                },
                body: JSON.stringify({ ids }),
            });
        },
    });
});

// Silme onayı
document.addEventListener('submit', (e) => {
    const msg = e.target.dataset.confirm;
    if (msg && !confirm(msg)) e.preventDefault();
});

// Alıştırma formu: türe göre alanları göster/gizle, seçenek satırı ekle/sil
const typeSelect = document.querySelector('[data-exercise-type]');
if (typeSelect) {
    const sync = () => {
        document.querySelectorAll('[data-show-for]').forEach((el) => {
            el.hidden = !el.dataset.showFor.split(',').includes(typeSelect.value);
        });
    };
    typeSelect.addEventListener('change', sync);
    sync();
}

const optionList = document.querySelector('[data-option-list]');
document.querySelector('[data-add-option]')?.addEventListener('click', () => {
    const tpl = document.getElementById('option-template');
    const index = optionList.children.length + Date.now();
    optionList.insertAdjacentHTML('beforeend', tpl.innerHTML.replaceAll('__i__', index));
});
optionList?.addEventListener('click', (e) => {
    if (e.target.closest('[data-remove-option]')) e.target.closest('[data-option-row]').remove();
});
