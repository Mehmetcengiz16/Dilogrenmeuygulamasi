<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Admin panelden dondurulan hesapların mevcut token'larını da geçersiz kılar. */
class EnsureUserIsActive
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->user() && $request->user()->status !== 'active') {
            return response()->json(['success' => false, 'message' => 'Hesabınız askıya alınmış'], 403);
        }

        return $next($request);
    }
}
