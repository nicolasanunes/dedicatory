# 🔒 Configuração SSL para Desenvolvimento Local

## Por que preciso de HTTPS em desenvolvimento?

O **Spotify Web Playback API** requer HTTPS obrigatoriamente, mesmo em desenvolvimento. Isso é uma medida de segurança do Spotify.

## ✅ Solução: mkcert (Certificados SSL Confiáveis)

O `mkcert` é a melhor ferramenta para criar certificados SSL locais que são automaticamente confiáveis pelo navegador.

## 📦 Instalação do mkcert

### Windows (Chocolatey - Recomendado)
```powershell
# Instalar Chocolatey se não tiver (executar como Administrador)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Instalar mkcert
choco install mkcert
```

### Windows (Scoop - Alternativa)
```powershell
# Instalar Scoop se não tiver
iwr -useb get.scoop.sh | iex

# Instalar mkcert
scoop bucket add extras
scoop install mkcert
```

### Windows (Download Direto)
1. Baixar o executável: https://github.com/FiloSottile/mkcert/releases
2. Renomear para `mkcert.exe`
3. Adicionar ao PATH do sistema

## 🔧 Configuração Passo a Passo

### 1. Instalar a CA raiz local
```powershell
mkcert -install
```

### 2. Criar certificados para desenvolvimento

#### Para desenvolvimento local (localhost):
```powershell
# Navegar para o diretório do projeto
cd "\\192.168.10.19\Projects\dedicatory"

# Criar pasta para certificados
mkdir certs

# Gerar certificados para localhost
mkcert -key-file certs/localhost-key.pem -cert-file certs/localhost.pem localhost 127.0.0.1 ::1
```

#### Para desenvolvimento em rede (192.168.10.19):
```powershell
# Gerar certificados para o IP da rede
mkcert -key-file certs/192.168.10.19-key.pem -cert-file certs/192.168.10.19.pem 192.168.10.19 localhost 127.0.0.1 ::1
```

### 3. Configurar o Vite para HTTPS

Editar `vite.config.ts`:
```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  base: process.env.NODE_ENV === 'production' ? '/dedicatory/' : '/',
  server: {
    https: {
      key: fs.readFileSync(path.resolve(__dirname, 'certs/localhost-key.pem')),
      cert: fs.readFileSync(path.resolve(__dirname, 'certs/localhost.pem'))
    },
    host: 'localhost',
    port: 5173
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
})
```

### 4. Adicionar scripts ao package.json
```json
{
  "scripts": {
    "dev": "vite",
    "dev:https": "vite --host 192.168.10.19 --port 5173",
    "build": "vue-tsc -b && vite build",
    "preview": "vite preview"
  }
}
```

## 🌐 Desenvolvimento em Rede

O projeto está configurado para rodar em rede no endereço `192.168.10.19:5173`.

### Comandos para executar:
```powershell
# HTTP (sem SSL)
npm run dev

# HTTPS (com SSL)
npm run dev:https
```

### URLs de acesso:
- **HTTP**: http://192.168.10.19:5173
- **HTTPS**: https://192.168.10.19:5173

⚠️ **Para o Spotify funcionar, use sempre HTTPS**: https://192.168.10.19:5173

## 🎵 Configuração do Spotify

### Atualizar App no Spotify Developer Dashboard

1. Acesse: https://developer.spotify.com/dashboard
2. Selecione seu app "Nossa Música Player"
3. Clique em **"Edit Settings"**
4. **Redirect URIs**:
   - Adicionar: `https://192.168.10.19:5173` ⚠️ **Principal para rede**
   - Adicionar: `https://localhost:5173` (backup local)
   - Manter: `http://localhost:5173` (fallback)
5. **Website**: `https://192.168.10.19:5173`
6. Salvar alterações

### Atualizar variáveis de ambiente

Criar/editar `.env.local`:
```env
VITE_SPOTIFY_CLIENT_ID=seu_client_id_aqui
VITE_SPOTIFY_CLIENT_SECRET=seu_client_secret_aqui
VITE_APP_URL=https://192.168.10.19:5173
VITE_APP_URL=https://localhost:5173
```

## 🚀 Executar em HTTPS

### Método 1: Script atualizado
```powershell
npm run dev
```

### Método 2: Comando direto
```powershell
npm run dev:https
```

## ✅ Verificar se funcionou

1. Abrir: https://localhost:5173
2. **Não deve aparecer aviso de certificado**
3. No DevTools (F12), aba Network, verificar se as requisições são HTTPS
4. Testar o Spotify Web Playback API

## 🔍 Solução de Problemas

### Erro: "Cannot find module 'fs'"
```bash
npm install --save-dev @types/node
```

### Certificado não confiável
```powershell
# Reinstalar CA raiz
mkcert -uninstall
mkcert -install
```

### Porta em uso
```powershell
# Verificar processos usando a porta
netstat -ano | findstr :5173

# Matar processo (substitua PID)
taskkill /PID <numero_do_pid> /F
```

### CORS Spotify
Certifique-se de que o Redirect URI no Spotify Dashboard é exatamente:
- `https://localhost:5173` (com HTTPS)

## 📁 Estrutura Final

```
dedicatory/
├── certs/
│   ├── localhost.pem
│   └── localhost-key.pem
├── src/
├── vite.config.ts (atualizado)
├── package.json (atualizado)
└── .env.local
```

## ⚠️ Importante

- **Não commitar** a pasta `certs/` no Git
- Adicionar `certs/` ao `.gitignore`
- Os certificados são válidos por 2 anos e 3 meses
- Certificados são específicos para este computador

## 🎯 Próximos Passos

Após configurar HTTPS:
1. Testar login do Spotify
2. Testar Web Playback API
3. Verificar se o player funciona corretamente