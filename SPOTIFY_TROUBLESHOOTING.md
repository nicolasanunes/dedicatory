# 🎵 Guia de Solução de Problemas do Spotify

## ❌ Erro: "Firefox can't establish a connection to wss://gue1-dealer.g2.spotify.com"

### Causas principais:

1. **Token expirado** (mais comum)
2. **Conta sem Spotify Premium ativo**
3. **Credenciais incorretas**
4. **Problemas de rede/firewall**

---

## ✅ Soluções (em ordem de prioridade)

### 1️⃣ Renovar o Access Token (SOLUÇÃO MAIS COMUM)

O token expira em **1 hora**. Para gerar um novo:

```bash
curl -X POST "https://accounts.spotify.com/api/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "SEU_CLIENT_ID:SEU_CLIENT_SECRET" \
  -d "grant_type=refresh_token&refresh_token=SEU_REFRESH_TOKEN"
```

**Resposta esperada:**
```json
{
  "access_token": "BQA...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "AQD...",
  "scope": "streaming user-read-email user-read-private"
}
```

**Atualizar no projeto:**

Local:
```bash
# Editar .env.local
VITE_SPOTIFY_ACCESS_TOKEN=novo_token_aqui
VITE_SPOTIFY_REFRESH_TOKEN=novo_refresh_token_aqui  # Se veio um novo
```

GitHub Actions:
1. Ir em **Settings** → **Secrets and variables** → **Actions**
2. Editar `VITE_SPOTIFY_ACCESS_TOKEN` com o novo token
3. Se veio novo refresh token, atualizar `VITE_SPOTIFY_REFRESH_TOKEN`

---

### 2️⃣ Verificar Spotify Premium

O **Web Playback SDK requer Spotify Premium ativo**.

**Como verificar:**
```bash
curl -X GET "https://api.spotify.com/v1/me" \
  -H "Authorization: Bearer SEU_ACCESS_TOKEN"
```

**Resultado esperado:**
```json
{
  "product": "premium",  // ← Deve ser "premium", não "free"
  ...
}
```

Se não tiver Premium:
- O player **não funcionará**
- Você precisa assinar o Spotify Premium
- Alternativa: usar o Spotify Embed Player (limitado a preview de 30s)

---

### 3️⃣ Verificar Scopes Corretos

Os tokens devem ter os scopes corretos:

**Scopes necessários:**
- `streaming` (reproduzir música)
- `user-read-email` (ler email do usuário)
- `user-read-private` (ler informações da conta)

**Como gerar token com scopes corretos:**

```bash
# 1. Obter Authorization Code
https://accounts.spotify.com/authorize?client_id=SEU_CLIENT_ID&response_type=code&redirect_uri=http://localhost:5173&scope=streaming%20user-read-email%20user-read-private

# 2. Trocar code por tokens
curl -X POST "https://accounts.spotify.com/api/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "SEU_CLIENT_ID:SEU_CLIENT_SECRET" \
  -d "grant_type=authorization_code&code=CODIGO_OBTIDO&redirect_uri=http://localhost:5173"
```

---

### 4️⃣ Verificar Configuração do App no Spotify Dashboard

1. Ir para: https://developer.spotify.com/dashboard
2. Abrir seu app
3. Verificar **Redirect URIs**:
   - Local: `http://localhost:5173`
   - Produção: `https://SEU_USERNAME.github.io/dedicatory`
4. Salvar mudanças

---

### 5️⃣ Limpar Cache do Navegador

O player pode ter cached um token inválido:

```javascript
// No console do navegador (F12)
localStorage.removeItem('spotify_auth_state')
location.reload()
```

---

### 6️⃣ Verificar Firewall/Antivírus

O WebSocket (`wss://`) pode estar bloqueado:

- Desabilitar temporariamente firewall/antivírus
- Verificar se sua rede permite conexões WebSocket
- Tentar em outra rede (ex: 4G do celular)

---

## 🔍 Como Diagnosticar o Problema

### Abrir Console do Navegador (F12)

Procurar por mensagens:

```
✅ Token renovado com sucesso!
✅ Conta Premium verificada
✅ Conectado ao Spotify Web Playback SDK!
```

**Ou erros:**

```
❌ Erro de autenticação: ...
❌ Erro de conta: ...
❌ Spotify Premium necessário
```

### Verificar Status de Renovação Automática

O sistema já renova automaticamente quando:
- Token vai expirar em **10 minutos**
- Recebe erro 401 (não autorizado)
- Erro de autenticação no player

**Logs esperados:**
```
🔄 Renovando access token...
✅ Token renovado com sucesso! Válido até: [data]
```

---

## 🆘 Checklist Rápido

- [ ] Token foi gerado há menos de 1 hora?
- [ ] Conta tem Spotify Premium ativo?
- [ ] Tokens têm os scopes corretos?
- [ ] Redirect URIs configurados no Dashboard?
- [ ] Client ID e Client Secret corretos?
- [ ] Refresh Token configurado?
- [ ] Cache do navegador limpo?
- [ ] Firewall não está bloqueando WebSocket?

---

## 📝 Comandos Úteis

### Testar token atual:
```bash
curl -X GET "https://api.spotify.com/v1/me" \
  -H "Authorization: Bearer SEU_ACCESS_TOKEN"
```

### Renovar token:
```bash
curl -X POST "https://accounts.spotify.com/api/token" \
  -u "CLIENT_ID:CLIENT_SECRET" \
  -d "grant_type=refresh_token&refresh_token=REFRESH_TOKEN"
```

### Ver informações da música:
```bash
curl -X GET "https://api.spotify.com/v1/tracks/2o2xhyri4aJUtgMGkf5P0J" \
  -H "Authorization: Bearer SEU_ACCESS_TOKEN"
```

---

## 💡 Dica Final

O erro de WebSocket geralmente indica **token expirado** ou **falta de Premium**.

**Solução mais rápida:**
1. Gerar novo token usando refresh token (comando acima)
2. Atualizar no `.env.local` ou GitHub Secrets
3. Recarregar a página
4. Verificar console se conectou com sucesso

---

💕 **Depois de resolver, sua música romântica tocará perfeitamente!** 🎵
