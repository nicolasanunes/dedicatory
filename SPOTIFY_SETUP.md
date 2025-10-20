# 🎵 Configuração do Spotify Web Playback API

## Pré-requisitos
- Conta Spotify Premium
- Aplicação registrada no Spotify Developer Dashboard

## Passo 1: Criar App no Spotify

1. Acesse: https://developer.spotify.com/dashboard
2. Faça login com sua conta Spotify
3. Clique em **"Create app"**
4. Preencha os dados:
   - **App name**: `Nossa Música Player`
   - **App description**: `Player romântico para nossa música especial`
   - **Website**: `http://localhost:5173`
   - **Redirect URIs**: `http://localhost:5173`
5. Marque **"Web Playback SDK"** nas APIs utilizadas
6. Aceite os termos e clique em **"Save"**
7. **Copie o Client ID** (você precisará dele)

## Passo 2: Obter Access Token

### Método 1: Usando cURL (Terminal)

```bash
# Substitua CLIENT_ID e CLIENT_SECRET pelos seus valores
curl -X POST "https://accounts.spotify.com/api/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=client_credentials&client_id=b6beeb75f1dd4140b60383ed33d9a688&client_secret=4b363ec16e6b464ba9abcaa7400514ea"
```

### Método 2: Usando Postman

1. **URL**: `POST https://accounts.spotify.com/api/token`
2. **Headers**:
   - `Content-Type: application/x-www-form-urlencoded`
3. **Body** (x-www-form-urlencoded):
   - `grant_type`: `client_credentials`
   - `client_id`: `SEU_CLIENT_ID`
   - `client_secret`: `SEU_CLIENT_SECRET`

### Método 3: Para uso com usuário (Recomendado)

Para controlar o player do usuário, você precisa de um token de usuário:

```bash
# URL de autorização (abra no navegador)
https://accounts.spotify.com/authorize?client_id=b6beeb75f1dd4140b60383ed33d9a688&response_type=code&redirect_uri=http://localhost:5173&scope=streaming%20user-read-email%20user-read-private%20user-read-playback-state%20user-modify-playback-state%20user-read-currently-playing

# Depois de autorizar, você receberá um 'code' na URL de callback
# Use esse code para obter o access_token:

curl -X POST "https://accounts.spotify.com/api/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=authorization_code&code=SEU_CODE&redirect_uri=http://localhost:5173&client_id=SEU_CLIENT_ID&client_secret=SEU_CLIENT_SECRET"
```

## Passo 3: Configurar variáveis de ambiente (SEGURO!)

🔒 **Importante**: Agora o projeto usa variáveis de ambiente para manter suas credenciais seguras!

### Método 1: Usando .env.local (Recomendado)

1. **Copie o template**:
   ```bash
   cp .env.example .env.local
   ```

2. **Edite o arquivo `.env.local`** com seus valores reais:
   ```env
   VITE_SPOTIFY_CLIENT_ID=seu_client_id_aqui
   VITE_SPOTIFY_ACCESS_TOKEN=seu_access_token_aqui
   VITE_SPOTIFY_TRACK_URI=spotify:track:ID_DA_SUA_MUSICA
   ```

3. **Substitua os valores**:
   - `seu_client_id_aqui` → Seu Client ID do Spotify
   - `seu_access_token_aqui` → Seu Access Token 
   - `ID_DA_SUA_MUSICA` → ID da música que você quer tocar

### ✅ Vantagens das variáveis de ambiente:
- 🔐 **Segurança**: Credenciais não aparecem no código
- 🚫 **Não commitadas**: Arquivo `.env.local` é ignorado pelo Git
- 🔄 **Flexibilidade**: Fácil de alterar sem mexer no código
- 🌐 **Deploy seguro**: Para produção, configure no hosting

## Passo 4: Configurar URI da música

1. Encontre a música no Spotify
2. Clique em "Compartilhar" → "Copiar link da faixa"
3. A URL será algo como: `https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC`
4. Extraia o ID: `4uLU6hMCjMI75M1A2tKUQC`
5. No arquivo `.env.local`, configure:
   ```env
   VITE_SPOTIFY_TRACK_URI=spotify:track:4uLU6hMCjMI75M1A2tKUQC
   ```
   ```

## Passo 5: Testar

1. Execute o projeto: `npm run dev`
2. Abra no navegador: `http://localhost:5173`
3. O player deve aparecer e conectar automaticamente
4. Clique em "Tocar Nossa Música" para iniciar

## Funcionalidades do Player

- ✅ **Play/Pause**: Controle básico de reprodução
- ✅ **Informações da música**: Capa, nome e artista
- ✅ **Barra de progresso**: Navegação na música
- ✅ **Controle de volume**: Ajuste do volume
- ✅ **Status em tempo real**: Acompanha o estado da reprodução

## Troubleshooting

### "Player não conecta"
- Verifique se tem Spotify Premium
- Confirme se o Access Token está correto
- Verifique se o Client ID está correto

### "Variáveis de ambiente não funcionam"
- Certifique-se de que o arquivo se chama exatamente `.env.local`
- Verifique se as variáveis começam com `VITE_`
- Reinicie o servidor de desenvolvimento (`npm run dev`)

### "Erro de autenticação"
- O Access Token pode ter expirado (dura 1 hora)
- Gere um novo token seguindo o Passo 2
- Atualize o valor em `.env.local`

### "Música não toca"
- Verifique se o URI da música está correto no `.env.local`
- Confirme se a música está disponível na sua região
- Certifique-se de que não há outro player Spotify ativo

### "Device não aparece"
- Atualize a página
- Verifique se o navegador permite reprodução automática
- Teste em outro navegador

## 🚀 Deploy Seguro em Produção

### GitHub Pages com GitHub Secrets

1. **Vá para seu repositório** → Settings → Secrets and variables → Actions
2. **Adicione os secrets**:
   - `VITE_SPOTIFY_CLIENT_ID` → Seu Client ID
   - `VITE_SPOTIFY_ACCESS_TOKEN` → Seu Access Token
   - `VITE_SPOTIFY_TRACK_URI` → URI da sua música

3. **Crie `.github/workflows/deploy.yml`**:
   ```yaml
   name: Deploy to GitHub Pages
   
   on:
     push:
       branches: [ main ]
   
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         
         - name: Setup Node.js
           uses: actions/setup-node@v3
           with:
             node-version: '18'
             
         - name: Install dependencies
           run: npm ci
           
         - name: Build
           run: npm run build
           env:
             VITE_SPOTIFY_CLIENT_ID: ${{ secrets.VITE_SPOTIFY_CLIENT_ID }}
             VITE_SPOTIFY_ACCESS_TOKEN: ${{ secrets.VITE_SPOTIFY_ACCESS_TOKEN }}
             VITE_SPOTIFY_TRACK_URI: ${{ secrets.VITE_SPOTIFY_TRACK_URI }}
             
         - name: Deploy
           run: npm run deploy
           env:
             GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```

### Outras plataformas (Vercel, Netlify)

Configure as variáveis de ambiente no painel do seu hosting:
- `VITE_SPOTIFY_CLIENT_ID`
- `VITE_SPOTIFY_ACCESS_TOKEN`
- `VITE_SPOTIFY_TRACK_URI`

## Limitações

- Access Token expira em 1 hora (para produção, implemente refresh token)
- Funciona apenas com Spotify Premium
- Requer conexão com internet
- Um device Spotify ativo por vez

## Para Produção

Para um ambiente de produção, você deve:

1. Implementar refresh token automático
2. Usar variáveis de ambiente para credenciais
3. Configurar um backend para esconder client_secret
4. Implementar tratamento de erros mais robusto

---

💡 **Dica**: Para desenvolvimento rápido, você pode usar o [Spotify Web API Console](https://developer.spotify.com/console/) para gerar tokens de teste rapidamente.