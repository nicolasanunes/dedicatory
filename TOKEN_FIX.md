# 🔧 Corrigindo Erro 401 - Token Expirado

## 🚨 Problema

Você está vendo o seguinte erro no console:

```
🔄 Recebido 401, tentando renovar token...
❌ Erro ao verificar status da conta: 401
```

Isso acontece porque o **Access Token do Spotify expira em 1 hora**.

---

## ✅ Solução Rápida

### Opção 1: Script Automático (Recomendado)

Execute o script que renova o token automaticamente:

```bash
./renew-token-simple.sh
```

**Ou, se você tiver o `jq` instalado:**

```bash
./renew-token.sh
```

Este script irá:
1. ✅ Ler as credenciais do seu `.env.local`
2. ✅ Renovar o token automaticamente
3. ✅ Atualizar o arquivo `.env.local` com o novo token
4. ✅ Criar um backup do arquivo anterior

Depois de executar, **recarregue a página** da aplicação.

---

### Opção 2: Manual (se o script não funcionar)

1. **Obter novo token via cURL:**

```bash
curl -X POST "https://accounts.spotify.com/api/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "SEU_CLIENT_ID:SEU_CLIENT_SECRET" \
  -d "grant_type=refresh_token&refresh_token=SEU_REFRESH_TOKEN"
```

2. **Copiar o `access_token` da resposta**

3. **Atualizar no `.env.local`:**

```bash
VITE_SPOTIFY_ACCESS_TOKEN=novo_token_aqui
```

4. **Recarregar a aplicação**

---

## 🔄 Renovação Automática

As alterações que fiz implementam **renovação automática de tokens**:

### Como funciona:

1. ✅ **Ao iniciar a aplicação:**
   - Verifica se o token salvo está expirado
   - Se estiver, renova automaticamente antes de fazer qualquer requisição

2. ✅ **Durante o uso:**
   - Monitora a expiração a cada 30 segundos
   - Renova automaticamente 10 minutos antes de expirar
   
3. ✅ **Em caso de erro 401:**
   - Força renovação do token
   - Repete a requisição com o novo token

### Logs no Console:

Agora você verá logs mais informativos:

```
🔑 Tokens carregados do .env.local, verificando validade...
🔄 Renovando access token...
✅ Token renovado com sucesso! Válido até: [data]
✅ Tokens inicializados
📊 Debug: { hasAccessToken: true, isExpired: false, ... }
🔍 Verificando status Premium...
✅ Conta Premium verificada: [seu nome]
```

---

## 🛠️ Verificar Status

Para ver o status atual dos tokens no console do navegador:

```javascript
// No console do navegador
localStorage.getItem('spotify_auth_state')
```

Isso mostra:
- Token atual
- Data de expiração
- Se está autenticado

---

## 📝 Arquivos Modificados

1. **`src/composables/useSpotifyAuth.ts`**
   - ✅ Renovação automática ao inicializar
   - ✅ Melhor tratamento de erro 401
   - ✅ Logs mais informativos

2. **`src/App.vue`**
   - ✅ Aguarda inicialização dos tokens antes de verificar Premium
   - ✅ Melhor tratamento de erros
   - ✅ Mensagens mais claras

3. **`renew-token.sh`** (novo)
   - ✅ Script para renovar token automaticamente

---

## ⚠️ Importante

- Tokens expiram em **1 hora**
- O **Refresh Token** é permanente (não expira)
- Você só precisa do **Client ID**, **Client Secret** e **Refresh Token** no `.env.local`
- O **Access Token** é renovado automaticamente

---

## 🆘 Se ainda não funcionar

1. Verifique se você tem **Spotify Premium**
2. Verifique se as credenciais no `.env.local` estão corretas
3. Execute `./renew-token.sh` manualmente
4. Veja os logs no console do navegador para mais detalhes
5. Consulte `SPOTIFY_TROUBLESHOOTING.md` para problemas mais específicos
