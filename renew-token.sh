#!/bin/bash

# Script para renovar o Access Token do Spotify
# Usa as credenciais do arquivo .env.local

echo "🔄 Renovando Access Token do Spotify..."
echo ""

# Verificar se o arquivo .env.local existe
if [ ! -f ".env.local" ]; then
    echo "❌ Erro: Arquivo .env.local não encontrado!"
    echo "Crie o arquivo .env.local com suas credenciais primeiro."
    exit 1
fi

# Carregar variáveis do .env.local
export $(grep -v '^#' .env.local | xargs)

# Verificar se as variáveis necessárias existem
if [ -z "$VITE_SPOTIFY_CLIENT_ID" ] || [ -z "$VITE_SPOTIFY_CLIENT_SECRET" ] || [ -z "$VITE_SPOTIFY_REFRESH_TOKEN" ]; then
    echo "❌ Erro: Credenciais não encontradas no .env.local"
    echo "Certifique-se de que as seguintes variáveis estão definidas:"
    echo "  - VITE_SPOTIFY_CLIENT_ID"
    echo "  - VITE_SPOTIFY_CLIENT_SECRET"
    echo "  - VITE_SPOTIFY_REFRESH_TOKEN"
    exit 1
fi

echo "📋 Client ID: ${VITE_SPOTIFY_CLIENT_ID:0:20}..."
echo "📋 Refresh Token: ${VITE_SPOTIFY_REFRESH_TOKEN:0:20}..."
echo ""

# Fazer requisição para renovar token
response=$(curl -s -X POST "https://accounts.spotify.com/api/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "$VITE_SPOTIFY_CLIENT_ID:$VITE_SPOTIFY_CLIENT_SECRET" \
  -d "grant_type=refresh_token&refresh_token=$VITE_SPOTIFY_REFRESH_TOKEN")

# Verificar se houve erro
if echo "$response" | grep -q "error"; then
    echo "❌ Erro ao renovar token:"
    echo "$response" | jq '.'
    exit 1
fi

# Extrair novo access token
new_access_token=$(echo "$response" | jq -r '.access_token')
new_refresh_token=$(echo "$response" | jq -r '.refresh_token // empty')
expires_in=$(echo "$response" | jq -r '.expires_in')

if [ -z "$new_access_token" ] || [ "$new_access_token" = "null" ]; then
    echo "❌ Erro: Não foi possível extrair o novo token"
    echo "$response"
    exit 1
fi

echo "✅ Token renovado com sucesso!"
echo ""
echo "📊 Informações:"
echo "   Expira em: $expires_in segundos ($(($expires_in / 60)) minutos)"
echo ""
echo "🔑 Novo Access Token:"
echo "$new_access_token"
echo ""

# Atualizar .env.local
echo "📝 Atualizando .env.local..."

# Backup do arquivo original
cp .env.local .env.local.backup

# Atualizar access token
sed -i "s|VITE_SPOTIFY_ACCESS_TOKEN=.*|VITE_SPOTIFY_ACCESS_TOKEN=$new_access_token|" .env.local

# Se veio um novo refresh token, atualizar também
if [ ! -z "$new_refresh_token" ] && [ "$new_refresh_token" != "null" ]; then
    echo "🔄 Novo Refresh Token recebido, atualizando..."
    sed -i "s|VITE_SPOTIFY_REFRESH_TOKEN=.*|VITE_SPOTIFY_REFRESH_TOKEN=$new_refresh_token|" .env.local
    echo ""
    echo "🔑 Novo Refresh Token:"
    echo "$new_refresh_token"
fi

echo ""
echo "✅ Arquivo .env.local atualizado!"
echo "📦 Backup salvo em .env.local.backup"
echo ""
echo "🎵 Agora você pode recarregar a aplicação."
echo "   O novo token é válido por $((expires_in / 60)) minutos."
