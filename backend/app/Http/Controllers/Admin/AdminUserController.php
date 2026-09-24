<?php

namespace App\Http\Controllers\Admin;

use App\Models\Admin;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\RedirectResponse;
use Illuminate\Validation\Rule;

/** Yalnızca Süper Admin erişir (route middleware). */
class AdminUserController extends CrudController
{
    protected function config(): array
    {
        return [
            'title' => 'Adminler', 'singular' => 'Admin', 'route' => 'admin.admins', 'icon' => 'admin_panel_settings',
            'model' => Admin::class, 'search' => ['name', 'email'],
            'columns' => ['name' => 'Ad', 'email' => 'E-posta', 'role' => 'Rol'],
            'fields' => [
                'name' => ['label' => 'Ad soyad', 'rules' => 'required|string|max:100'],
                'email' => ['label' => 'E-posta', 'type' => 'email', 'rules' => fn ($item) => ['required', 'email', Rule::unique('admins', 'email')->ignore($item)]],
                'role' => ['label' => 'Rol', 'options' => [Admin::ROLE_EDITOR => 'Editör', Admin::ROLE_SUPER => 'Süper Admin'], 'rules' => 'required|in:editor,super_admin'],
                'password' => ['label' => 'Şifre', 'type' => 'password', 'rules' => fn ($item) => [$item ? 'nullable' : 'required', 'string', 'min:8'], 'help' => 'Düzenlerken boş bırakılırsa değişmez.'],
            ],
        ];
    }

    protected function cell(Model $item, string $key): string
    {
        return $key === 'role'
            ? ($item->isSuper() ? '<span class="chip-primary">Süper Admin</span>' : '<span class="chip-muted">Editör</span>')
            : parent::cell($item, $key);
    }

    public function destroy(string $id): RedirectResponse
    {
        if ((int) $id === auth('admin')->id()) {
            return back()->withErrors(['admin' => 'Kendi hesabınızı silemezsiniz.']);
        }

        return parent::destroy($id);
    }
}
