<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;

/**
 * Basit kaynaklar için ortak liste + form akışı. Alt sınıf config() ile alanları tanımlar:
 * fields: name => [label, type, options?, rules, help?, store? (dosya klasörü)]
 * columns: key => label (key bir closure da dönebilir: columnValues()).
 */
abstract class CrudController extends Controller
{
    abstract protected function config(): array;

    protected function query()
    {
        return ($this->config()['model'])::query();
    }

    /** Liste hücresi için değer; alt sınıf özelleştirebilir. */
    protected function cell(Model $item, string $key): string
    {
        $value = data_get($item, $key);

        return match (true) {
            is_bool($value) => $value ? '<span class="chip-ok">Aktif</span>' : '<span class="chip-muted">Pasif</span>',
            default => e((string) $value),
        };
    }

    public function index(Request $request): View
    {
        $c = $this->config();
        $query = $this->query();
        if ($request->filled('q') && ! empty($c['search'])) {
            $query->where(function ($q) use ($c, $request) {
                foreach ($c['search'] as $col) {
                    $q->orWhere($col, 'like', '%'.$request->q.'%');
                }
            });
        }
        foreach ($c['orderBy'] ?? ['id' => 'desc'] as $col => $dir) {
            $query->orderBy($col, $dir);
        }

        return view('admin.crud.index', [
            'c' => $c,
            'items' => $query->paginate(25)->withQueryString(),
            'cell' => fn ($item, $key) => $this->cell($item, $key),
        ]);
    }

    public function create(): View
    {
        return view('admin.crud.form', ['c' => $this->config(), 'item' => null]);
    }

    public function store(Request $request): RedirectResponse
    {
        $c = $this->config();
        $data = $this->validated($request);
        ($c['model'])::create($data);

        return redirect()->route($c['route'].'.index')->with('status', $c['singular'].' eklendi');
    }

    public function edit(string $id): View
    {
        return view('admin.crud.form', ['c' => $this->config(), 'item' => $this->query()->findOrFail($id)]);
    }

    public function update(Request $request, string $id): RedirectResponse
    {
        $c = $this->config();
        $item = $this->query()->findOrFail($id);
        $item->update($this->validated($request, $item));

        return redirect()->route($c['route'].'.index')->with('status', $c['singular'].' güncellendi');
    }

    public function destroy(string $id): RedirectResponse
    {
        $c = $this->config();
        $this->query()->findOrFail($id)->delete();

        return back()->with('status', $c['singular'].' silindi');
    }

    protected function validated(Request $request, ?Model $item = null): array
    {
        $fields = $this->config()['fields'];
        $rules = [];
        foreach ($fields as $name => $f) {
            $rule = $f['rules'] ?? 'nullable';
            $rules[$name] = is_callable($rule) ? $rule($item) : $rule;
        }
        $data = $request->validate($rules);

        foreach ($fields as $name => $f) {
            if (($f['type'] ?? null) === 'file') {
                unset($data[$name]);
                if ($request->hasFile($name)) {
                    $column = $f['column'];
                    if ($item?->{$column} && ! str_starts_with($item->{$column}, 'http')) {
                        Storage::disk('public')->delete($item->{$column});
                    }
                    $data[$column] = $request->file($name)->store($f['store'], 'public');
                }
            }
            if (($f['type'] ?? null) === 'password' && empty($data[$name])) {
                unset($data[$name]);
            }
        }

        return $data;
    }
}
