<x-admin-layout title="Kullanıcılar" :breadcrumbs="['Kullanıcılar' => null]">
    <div class="mb-6 flex flex-wrap items-end justify-between gap-4">
        <div>
            <h1 class="text-[28px] font-bold leading-9 tracking-tight">Kullanıcılar</h1>
            <p class="text-sm text-on-surface-variant">{{ $users->total() }} kayıt</p>
        </div>
        <form class="flex items-center gap-2 rounded-full bg-white p-1.5 pl-4 shadow-[0_8px_24px_rgba(108,92,231,0.09)]">
            <span class="material-symbols-outlined text-[20px] text-on-surface-variant">search</span>
            <input name="q" value="{{ request('q') }}" placeholder="Ad veya e-posta..." class="w-48 bg-transparent text-sm outline-none">
            <select name="status" class="rounded-full bg-surface-low px-3 py-1.5 text-xs font-semibold outline-none">
                <option value="">Tümü</option>
                <option value="active" @selected(request('status') === 'active')>Aktif</option>
                <option value="suspended" @selected(request('status') === 'suspended')>Dondurulmuş</option>
            </select>
            <button class="btn-primary btn-sm">Ara</button>
        </form>
    </div>

    <div class="card overflow-hidden p-0">
        @if ($users->isEmpty())
            <x-empty icon="group" />
        @else
            <table class="data-table">
                <thead><tr><th>Kullanıcı</th><th>XP</th><th>Seri</th><th>Tamamlanan</th><th>Kayıt</th><th>Durum</th><th></th></tr></thead>
                <tbody>
                @foreach ($users as $u)
                    <tr>
                        <td>
                            <div class="flex items-center gap-3">
                                <span class="flex h-9 w-9 items-center justify-center rounded-full bg-secondary-fixed text-sm font-bold text-secondary">{{ mb_substr($u->name, 0, 1) }}</span>
                                <div><div class="font-semibold">{{ $u->name }}</div><div class="text-xs text-on-surface-variant">{{ $u->email }}</div></div>
                            </div>
                        </td>
                        <td><span class="chip-primary">{{ $u->total_xp }}</span></td>
                        <td>🔥 {{ $u->current_streak }}</td>
                        <td>{{ $u->completed_count }} ders</td>
                        <td class="text-xs text-on-surface-variant">{{ $u->created_at->format('d.m.Y') }}</td>
                        <td>{!! $u->status === 'active' ? '<span class="chip-ok">Aktif</span>' : '<span class="chip bg-error-container text-error">Dondurulmuş</span>' !!}</td>
                        <td class="text-right"><a href="{{ route('admin.users.show', $u) }}" class="btn-soft btn-sm">Detay</a></td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        @endif
    </div>
    <div class="mt-4">{{ $users->links() }}</div>
</x-admin-layout>
