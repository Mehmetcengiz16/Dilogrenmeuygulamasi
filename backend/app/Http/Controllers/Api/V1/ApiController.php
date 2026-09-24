<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Pagination\LengthAwarePaginator;

/** Dokümandaki standart yanıt formatı: success, message, data, meta. */
abstract class ApiController extends Controller
{
    protected function ok(mixed $data = null, string $message = 'İşlem başarılı', ?array $meta = null, int $status = 200): JsonResponse
    {
        $body = ['success' => true, 'message' => $message, 'data' => $data];
        if ($meta) {
            $body['meta'] = $meta;
        }

        return response()->json($body, $status);
    }

    protected function fail(string $message, int $status = 400, ?array $errors = null): JsonResponse
    {
        $body = ['success' => false, 'message' => $message];
        if ($errors) {
            $body['errors'] = $errors;
        }

        return response()->json($body, $status);
    }

    protected function paginated(LengthAwarePaginator $page, mixed $items): JsonResponse
    {
        return $this->ok($items, meta: [
            'page' => $page->currentPage(),
            'per_page' => $page->perPage(),
            'total' => $page->total(),
        ]);
    }
}
