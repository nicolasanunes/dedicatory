#!/bin/bash

# 🎵 Script de Renovação de Token do Spotify
# Este script renova automaticamente o access token usando o refresh token

echo "🎵 Renovando token do Spotify..."
echo ""

# Ler variáveis do .env.local
if [ -f .env.local ]; then
  export $(cat .env.local | grep -v '^#' | xargs)
else
  echo "❌ Arquivo .env.local não encontrado!"
  echo "💡 Crie o arquivo .env.local com suas credenciais"
  exit 1
fi

# Verificar se as variáveis necessárias existem
if [ -z "$VITE_SPOTIFY_CLIENT_ID" ] || [ -z "$VITE_SPOTIFY_CLIENT_SECRET" ] || [ -z "$VITE_SPOTIFY_REFRESH_TOKEN" ]; then
  echo "❌ Credenciais faltando no .env.local!"
  echo "💡 Certifique-se de que CLIENT_ID, CLIENT_SECRET e REFRESH_TOKEN estão configurados"
  exit 1
fi

# Fazer requisição para renovar token
echo "🔄 Fazendo requisição ao Spotify..."
RESPONSE=$(curl -s -X POST "https://accounts.spotify.com/api/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "$VITE_SPOTIFY_CLIENT_ID:$VITE_SPOTIFY_CLIENT_SECRET" \
  -d "grant_type=refresh_token&refresh_token=$VITE_SPOTIFY_REFRESH_TOKEN")

# Verificar se houve erro
if echo "$RESPONSE" | grep -q "error"; then
  echo "❌ Erro ao renovar token:"
  echo "$RESPONSE" | grep -oP '"error_description":"\K[^"]*'
  exit 1
fi

# Extrair novo access token
NEW_ACCESS_TOKEN=$(echo "$RESPONSE" | grep -oP '"access_token":"\K[^"]*')
NEW_REFRESH_TOKEN=$(echo "$RESPONSE" | grep -oP '"refresh_token":"\K[^"]*')
EXPIRES_IN=$(echo "$RESPONSE" | grep -oP '"expires_in":\K[0-9]*')

if [ -z "$NEW_ACCESS_TOKEN" ]; then
  echo "❌ Não foi possível extrair o novo token"
  echo "Resposta completa:"
  echo "$RESPONSE"
  exit 1
fi

echo "✅ Token renovado com sucesso!"
echo ""
echo "📋 Novo Access Token:"
echo "$NEW_ACCESS_TOKEN"
echo ""

if [ -n "$NEW_REFRESH_TOKEN" ]; then
  echo "📋 Novo Refresh Token:"
  echo "$NEW_REFRESH_TOKEN"
  echo ""
fi

echo "⏰ Expira em: $((EXPIRES_IN / 60)) minutos"
echo ""

# Perguntar se deseja atualizar o .env.local
read -p "🔄 Deseja atualizar automaticamente o .env.local? (s/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[SsYy]$ ]]; then
  # Fazer backup
  cp .env.local .env.local.backup
  echo "💾 Backup criado: .env.local.backup"
  
  # Atualizar access token
  sed -i "s|VITE_SPOTIFY_ACCESS_TOKEN=.*|VITE_SPOTIFY_ACCESS_TOKEN=$NEW_ACCESS_TOKEN|g" .env.local
  
  # Atualizar refresh token se veio um novo
  if [ -n "$NEW_REFRESH_TOKEN" ]; then
    sed -i "s|VITE_SPOTIFY_REFRESH_TOKEN=.*|VITE_SPOTIFY_REFRESH_TOKEN=$NEW_REFRESH_TOKEN|g" .env.local
  fi
  
  echo "✅ Arquivo .env.local atualizado!"
  echo ""
  echo "🚀 Próximos passos:"
  echo "1. Reinicie o servidor de desenvolvimento (npm run dev)"
  echo "2. Ou faça o build novamente (npm run build)"
else
  echo ""
  echo "📝 Atualize manualmente o .env.local:"
  echo "VITE_SPOTIFY_ACCESS_TOKEN=$NEW_ACCESS_TOKEN"
  if [ -n "$NEW_REFRESH_TOKEN" ]; then
    echo "VITE_SPOTIFY_REFRESH_TOKEN=$NEW_REFRESH_TOKEN"
  fi
fi

echo ""
echo "💕 Token renovado! Sua música romântica vai funcionar novamente! 🎵"
