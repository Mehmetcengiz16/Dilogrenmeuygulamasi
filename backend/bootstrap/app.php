<?php

use App\Http\Middleware\EnsureSuperAdmin;
use App\Http\Middleware\EnsureUserIsActive;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Session\TokenMismatchException;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias(['active' => EnsureUserIsActive::class, 'super' => EnsureSuperAdmin::class]);
        $middleware->redirectGuestsTo(fn (Request $request) => $request->is('admin*') ? route('admin.login') : null);
        $middleware->redirectUsersTo(fn () => route('admin.dashboard'));
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Admin panelde süresi dolmuş form (419): hata sayfası yerine girişe geri dön.
        $exceptions->render(function (Throwable $e, Request $request) {
            $expired = $e instanceof TokenMismatchException
                || ($e instanceof HttpExceptionInterface && $e->getStatusCode() === 419);
            if ($expired && $request->is('admin*')) {
                return redirect()->route('admin.login')
                    ->withInput($request->except('password', '_token'))
                    ->withErrors(['email' => 'Oturum süresi doldu, lütfen tekrar giriş yapın.']);
            }
        });

        // API hatalarını dokümandaki standart formatta döndür.
        $exceptions->render(function (Throwable $e, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            return match (true) {
                $e instanceof ValidationException => response()->json([
                    'success' => false, 'message' => 'Girilen bilgiler geçersiz', 'errors' => $e->errors(),
                ], 422),
                $e instanceof AuthenticationException => response()->json(['success' => false, 'message' => 'Oturum açmanız gerekiyor'], 401),
                $e instanceof NotFoundHttpException => response()->json(['success' => false, 'message' => 'Kayıt bulunamadı'], 404),
                $e instanceof HttpExceptionInterface => response()->json(['success' => false, 'message' => $e->getMessage() ?: 'İstek işlenemedi'], $e->getStatusCode()),
                default => config('app.debug') ? null : response()->json(['success' => false, 'message' => 'Sunucu hatası'], 500),
            };
        });
    })->create();
