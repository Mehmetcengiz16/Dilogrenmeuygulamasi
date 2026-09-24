<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Admin Girişi · LinguaAI</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet">
    @vite(['resources/css/app.css'])
</head>
<body class="relative flex min-h-screen items-center justify-center overflow-hidden bg-surface p-4 font-sans text-on-surface">
    <div class="pointer-events-none absolute -left-24 -top-24 h-96 w-96 rounded-full bg-primary-container/20 blur-3xl"></div>
    <div class="pointer-events-none absolute -bottom-24 -right-24 h-96 w-96 rounded-full bg-[#a19afd]/30 blur-3xl"></div>

    <div class="relative w-full max-w-md">
        <div class="mb-6 flex flex-col items-center gap-3 text-center">
            <span class="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-primary-container to-[#8072f6] text-white shadow-[0_12px_28px_rgba(108,92,231,0.35)]">
                <span class="material-symbols-outlined text-[30px]">translate</span>
            </span>
            <div>
                <h1 class="text-[28px] font-bold leading-9 tracking-tight">LinguaAI Admin</h1>
                <p class="text-sm text-on-surface-variant">İçerik yönetim paneline giriş yapın</p>
            </div>
        </div>

        <form method="POST" action="{{ route('admin.login.store') }}" class="card grid gap-4 rounded-[28px] p-8">
            @csrf
            <x-field name="email" label="E-posta" type="email" required autofocus />
            <x-field name="password" label="Şifre" type="password" required />
            <label class="flex items-center gap-2 text-sm text-on-surface-variant">
                <input type="checkbox" name="remember" value="1" class="h-4 w-4 accent-[#6c5ce7]"> Beni hatırla
            </label>
            <button class="btn-primary h-12 w-full text-base">Giriş Yap <span class="material-symbols-outlined text-[20px]">arrow_forward</span></button>
        </form>
    </div>
</body>
</html>
