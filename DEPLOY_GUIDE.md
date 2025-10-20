# 🚀 Deploy no GitHub Pages - Guia Completo

## 📋 Pré-requisitos
- [x] Projeto configurado e funcionando localmente
- [x] Conta no GitHub
- [x] Git instalado no computador

## 🔧 Configurações Realizadas

### ✅ Package.json
```json
{
  "homepage": "https://SEU_USERNAME.github.io/dedicatory",
  "scripts": {
    "predeploy": "npm run build",
    "deploy": "gh-pages -d dist"
  }
}
```

### ✅ Vite.config.ts
```typescript
export default defineConfig({
  base: process.env.NODE_ENV === 'production' ? '/dedicatory/' : '/',
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
})
```

## 🚀 Passos para Deploy

### 1. Inicializar repositório Git (se necessário)
```bash
cd \\192.168.10.19\Projects\dedicatory
git init
```

### 2. Adicionar arquivos ao Git
```bash
git add .
git commit -m "🎵 Primeira versão do projeto romântico com Spotify player"
```

### 3. Criar repositório no GitHub
1. Vá para https://github.com
2. Clique em **"New repository"**
3. Nome do repositório: `dedicatory`
4. Deixe **público** (para GitHub Pages gratuito)
5. **NÃO** inicialize com README (você já tem o projeto)
6. Clique em **"Create repository"**

### 4. Conectar repositório local ao GitHub
```bash
# Substitua SEU_USERNAME pelo seu nome de usuário do GitHub
git remote add origin https://github.com/SEU_USERNAME/dedicatory.git
git branch -M main
git push -u origin main
```

### 5. Atualizar homepage no package.json
Substitua `SEU_USERNAME` pelo seu nome de usuário real do GitHub:
```json
"homepage": "https://SEU_USERNAME.github.io/dedicatory"
```

### 6. Fazer deploy
```bash
npm run deploy
```

### 7. Configurar GitHub Pages
1. Vá para o seu repositório no GitHub
2. Clique em **"Settings"**
3. Role até **"Pages"** no menu lateral
4. Em **"Source"**, selecione **"Deploy from a branch"**
5. Em **"Branch"**, selecione **"gh-pages"**
6. Clique em **"Save"**

### 8. Aguardar deploy
- O GitHub levará alguns minutos para processar
- Você receberá a URL: `https://SEU_USERNAME.github.io/dedicatory`

## 🔄 Para atualizações futuras

Sempre que fizer mudanças no projeto:

```bash
# 1. Adicionar mudanças
git add .
git commit -m "🎵 Atualização: descrição das mudanças"

# 2. Enviar para GitHub
git push origin main

# 3. Fazer novo deploy
npm run deploy
```

## ⚠️ Importantes Considerações do Spotify

### 🔐 Segurança do Access Token
Para produção, você precisa considerar:

1. **Access Token expira**: Tokens duram apenas 1 hora
2. **Client Secret exposto**: Não coloque em repositório público
3. **Refresh Token**: Implemente renovação automática

### 🛠️ Soluções para Produção

#### Opção 1: Variáveis de Ambiente (Recomendado)
```typescript
// No código
const SPOTIFY_ACCESS_TOKEN = import.meta.env.VITE_SPOTIFY_TOKEN
const SPOTIFY_CLIENT_ID = import.meta.env.VITE_SPOTIFY_CLIENT_ID
```

Crie arquivo `.env.local`:
```env
VITE_SPOTIFY_TOKEN=seu_token_aqui
VITE_SPOTIFY_CLIENT_ID=seu_client_id_aqui
```

**Importante**: Adicione `.env.local` ao .gitignore

#### Opção 2: Backend Simples
Para um projeto mais robusto, crie um backend (Vercel/Netlify Functions) que:
- Gerencie tokens
- Faça refresh automático
- Esconda credenciais

#### Opção 3: GitHub Secrets (Para GitHub Pages)
1. Vá em **Settings** > **Secrets and variables** > **Actions**
2. Adicione seus tokens como secrets
3. Use GitHub Actions para deploy

### 🎵 Redirect URI para Produção
No Spotify Developer Dashboard, adicione:
```
https://SEU_USERNAME.github.io/dedicatory
```

## 📱 URL Final
Após o deploy, seu projeto estará disponível em:
**https://SEU_USERNAME.github.io/dedicatory**

## 🐛 Troubleshooting

### "gh-pages não encontrado"
```bash
npm install --save-dev gh-pages
```

### "Permission denied"
Configure autenticação do Git:
```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"
```

### "Spotify não funciona em produção"
- Verifique se adicionou a URL de produção no Spotify Dashboard
- Confirme se o Access Token está válido
- Teste se o redirect URI está correto

### "404 Page Not Found"
- Aguarde alguns minutos após o deploy
- Verifique se selecionou a branch "gh-pages" nas configurações
- Confirme se o `base` no vite.config.ts está correto

---

💕 **Seu projeto romântico estará disponível 24/7 na internet para vocês dois!** 🌟