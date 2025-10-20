# 🔒 Guia de Segurança - Variáveis de Ambiente

## ✅ O que foi implementado

### 🔐 Proteção de Credenciais
- ✅ **Variáveis de ambiente**: Client ID e Access Token agora são seguros
- ✅ **Arquivo .env.local**: Credenciais ficam apenas no seu computador
- ✅ **.gitignore atualizado**: Impede commit acidental de dados sensíveis
- ✅ **Template .env.example**: Facilita configuração para outros usuários

### 🚫 O que NÃO vai mais para o Git
- ❌ Client ID do Spotify
- ❌ Access Token do Spotify  
- ❌ Qualquer credencial sensível

## 📋 Como usar

### 1. Configuração Local
```bash
# Copie o template
cp .env.example .env.local

# Edite com seus valores reais
nano .env.local
```

### 2. Arquivo .env.local
```env
VITE_SPOTIFY_CLIENT_ID=seu_client_id_real
VITE_SPOTIFY_ACCESS_TOKEN=seu_access_token_real
VITE_SPOTIFY_TRACK_URI=spotify:track:ID_DA_SUA_MUSICA
```

### 3. Verificação
O código agora mostra avisos úteis:
```
❌ Variáveis de ambiente do Spotify não configuradas!
📋 Crie o arquivo .env.local com:
VITE_SPOTIFY_CLIENT_ID=seu_client_id
VITE_SPOTIFY_ACCESS_TOKEN=seu_access_token
```

## 🚀 Deploy Seguro

### GitHub Pages (Automático)
1. **Configure GitHub Secrets**:
   - Repositório → Settings → Secrets and variables → Actions
   - Adicione: `VITE_SPOTIFY_CLIENT_ID`, `VITE_SPOTIFY_ACCESS_TOKEN`, `VITE_SPOTIFY_TRACK_URI`

2. **Use GitHub Actions**:
   - Arquivo `.github/workflows/deploy.yml` já configurado
   - Deploy automático a cada push na branch `main`

### Deploy Manual
```bash
# Certifique-se de que .env.local está configurado
npm run build
npm run deploy
```

## ⚠️ Importantes

### 🔄 Token Expira
- Access Token dura apenas **1 hora**
- Para produção: implemente refresh automático
- Para desenvolvimento: renove manualmente

### 🌐 URL de Produção
Adicione no Spotify Developer Dashboard:
```
https://SEU_USERNAME.github.io/dedicatory
```

### 📱 Diferenças entre ambientes
- **Desenvolvimento**: Usa `.env.local`
- **Produção**: Usa GitHub Secrets ou variáveis do hosting

## 🛡️ Vantagens da Segurança

1. **Não exposição**: Credenciais nunca aparecem no código público
2. **Flexibilidade**: Cada ambiente pode ter valores diferentes  
3. **Renovação fácil**: Troque tokens sem alterar código
4. **Colaboração segura**: Outros podem configurar sem ver suas credenciais
5. **Deploy automático**: GitHub Actions cuida do build seguro

## 🔧 Troubleshooting

### "Variáveis não carregam"
- Arquivo deve ser exatamente `.env.local`
- Variáveis devem começar com `VITE_`
- Reinicie o servidor: `npm run dev`

### "Deploy falha"
- Verifique se GitHub Secrets estão configurados
- Confirme que workflow está habilitado
- Veja logs em Actions

---

🔒 **Agora suas credenciais do Spotify estão 100% seguras!** 🎵