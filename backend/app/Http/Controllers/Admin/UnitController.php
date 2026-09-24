<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Models\Unit;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class UnitController extends Controller
{
    private const RULES = [
        'title' => 'required|string|max:120',
        'description' => 'nullable|string|max:500',
        'is_published' => 'boolean',
    ];

    public function store(Request $request, Course $course): RedirectResponse
    {
        $data = $request->validate(self::RULES);
        $course->units()->create($data + ['order' => ($course->units()->max('order') ?? 0) + 1]);

        return back()->with('status', 'Ünite eklendi');
    }

    public function edit(Unit $unit): View
    {
        return view('admin.units.edit', compact('unit'));
    }

    public function update(Request $request, Unit $unit): RedirectResponse
    {
        $unit->update($request->validate(self::RULES));

        return redirect()->route('admin.courses.show', $unit->course_id)->with('status', 'Ünite güncellendi');
    }

    public function destroy(Unit $unit): RedirectResponse
    {
        $unit->delete();

        return back()->with('status', 'Ünite silindi');
    }

    public function reorder(Request $request, Course $course)
    {
        $ids = $request->validate(['ids' => 'required|array', 'ids.*' => 'integer'])['ids'];
        foreach ($ids as $i => $id) {
            $course->units()->whereKey($id)->update(['order' => $i + 1]);
        }

        return response()->json(['success' => true]);
    }
}
