@echo off
echo 🔒 Configuração SSL para Desenvolvimento Local
echo =============================================
echo.

:: Verificar se estamos no diretório correto
if not exist "package.json" (
    echo ❌ Erro: Execute este script no diretório do projeto!
    pause
    exit /b 1
)

echo 📋 PASSOS PARA CONFIGURAR SSL:
echo.
echo 1. Instalar mkcert (escolha uma opção):
echo.
echo    OPÇÃO A - Chocolatey (Recomendado):
echo    ===================================
echo    # Executar PowerShell como Administrador
echo    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
echo    choco install mkcert
echo.
echo    OPÇÃO B - Scoop:
echo    ================
echo    iwr -useb get.scoop.sh ^| iex
echo    scoop bucket add extras
echo    scoop install mkcert
echo.
echo    OPÇÃO C - Download Manual:
echo    ==========================
echo    Baixar: https://github.com/FiloSottile/mkcert/releases
echo    Renomear para mkcert.exe e adicionar ao PATH
echo.

pause
echo.

echo 2. Após instalar o mkcert, execute:
echo.
echo    mkcert -install
echo    mkdir certs
echo    
echo    PARA DESENVOLVIMENTO EM REDE (192.168.10.19):
echo    mkcert -key-file certs/192.168.10.19-key.pem -cert-file certs/192.168.10.19.pem 192.168.10.19 localhost 127.0.0.1 ::1
echo.
echo    OU PARA DESENVOLVIMENTO LOCAL:
echo    mkcert -key-file certs/localhost-key.pem -cert-file certs/localhost.pem localhost 127.0.0.1 ::1
echo.

pause
echo.

echo 3. Configurar Spotify Developer Dashboard:
echo.
echo    - Acesse: https://developer.spotify.com/dashboard
echo    - Edite seu app
echo    - Website: https://192.168.10.19:5173
echo    - Redirect URIs: https://192.168.10.19:5173
echo.

pause
echo.

echo 4. Executar em modo HTTPS:
echo.
echo    npm run dev:https
echo.
echo 🎯 Depois disso, acesse: https://192.168.10.19:5173
echo.
echo ⚠️  IMPORTANTE:
echo    - NÃO deve aparecer aviso de certificado
echo    - Spotify Web Playback API funcionará apenas com HTTPS
echo    - Certificados são válidos por 2+ anos
echo    - Outros dispositivos na rede podem acessar: https://192.168.10.19:5173
echo.

pause