@echo off
echo 🚀 Script de Deploy para GitHub Pages
echo =====================================
echo.

:: Verificar se estamos no diretório correto
if not exist "package.json" (
    echo ❌ Erro: package.json não encontrado!
    echo Execute este script no diretório do projeto.
    pause
    exit /b 1
)

echo 📝 Verificando configurações...

:: Verificar se git está inicializado
git status >nul 2>&1
if errorlevel 1 (
    echo 🔧 Inicializando repositório Git...
    git init
) else (
    echo ✅ Repositório Git já inicializado
)

echo.
echo 📋 PRÓXIMOS PASSOS:
echo.
echo 1. Crie um repositório no GitHub:
echo    - Vá para https://github.com/new
echo    - Nome: dedicatory
echo    - Deixe público
echo    - NÃO inicialize com README
echo.
echo 2. Substitua SEU_USERNAME no package.json pelo seu usuário GitHub
echo.
echo 3. Execute os comandos:
echo    git add .
echo    git commit -m "🎵 Primeira versão do projeto romântico"
echo    git remote add origin https://github.com/SEU_USERNAME/dedicatory.git
echo    git branch -M main
echo    git push -u origin main
echo    npm run deploy
echo.
echo 4. Configure GitHub Pages:
echo    - Settings → Pages → Source: Deploy from branch
echo    - Branch: gh-pages
echo.
echo 💕 Seu projeto estará em: https://SEU_USERNAME.github.io/dedicatory
echo.

pause