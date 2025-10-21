# 📁 Estrutura CSS do Projeto

## 🎨 Organização dos Estilos

A estrutura CSS foi modularizada para melhor organização e manutenibilidade:

```
src/assets/css/
├── index.css          # 🎯 Arquivo principal - importa todos os outros
├── global.css         # 🌍 Estilos globais (body, #app, background)
├── layout.css         # 📐 Layout principal (container, logo, títulos)
├── spotify-player.css # 🎵 Componente do Spotify Player
├── slideshow.css      # 📸 Componente do slideshow de fotos
└── app.css           # 📦 [Backup] Import direto de todos os módulos
```

## 🚀 Como Usar

### Importação Principal
O arquivo `index.css` é importado no `App.vue`:
```typescript
import './assets/css/index.css'
```

### Variáveis CSS Personalizadas
Definidas em `index.css`:
```css
:root {
  --primary-color: #FF746C;
  --secondary-color: #1DB954;
  --gradient-romantic: linear-gradient(45deg, #ff6b9d, #c44569);
  --shadow-soft: 0 10px 30px rgba(0, 0, 0, 0.2);
  --shadow-strong: 0 15px 35px rgba(0, 0, 0, 0.3);
  --blur-light: blur(10px);
  --blur-medium: blur(15px);
}
```

## 📂 Detalhes dos Arquivos

### `global.css`
- Background da página com imagem e overlay
- Estilos do elemento `body` e `#app`
- Configurações responsivas para mobile

### `layout.css`
- Container principal da aplicação
- Estilos do logo com efeitos hover
- Títulos principais (h1, h2) com gradientes
- Media queries para responsividade

### `spotify-player.css`
- Todos os estilos do player do Spotify
- Estados de carregamento e conexão
- Controles de reprodução e volume
- Animações e transições
- Estados de auto-play e fallbacks

### `slideshow.css`
- Container do slideshow de fotos
- Navegação (botões prev/next)
- Indicadores de posição
- Controles de autoplay
- Transições suaves entre slides
- Responsividade para diferentes telas

## 🔧 Benefícios da Modularização

✅ **Organização**: Cada componente tem seu próprio arquivo
✅ **Manutenibilidade**: Fácil de encontrar e editar estilos específicos  
✅ **Reutilização**: Módulos podem ser importados individualmente
✅ **Performance**: Melhor cache dos arquivos CSS
✅ **Escalabilidade**: Fácil adicionar novos componentes
✅ **Colaboração**: Diferentes desenvolvedores podem trabalhar em módulos diferentes

## 🎯 Estrutura Responsiva

Todos os arquivos incluem breakpoints para:
- **Desktop**: > 768px
- **Tablet**: ≤ 768px  
- **Mobile**: ≤ 480px

## 🌟 Características Visuais

- **Glassmorphism**: Efeitos de blur e transparência
- **Gradientes**: Cores românticas e suaves
- **Sombras**: Múltiplos níveis de profundidade
- **Animações**: Transições suaves e naturais
- **Background**: Imagem com overlay transparente
- **Tema Romântico**: Paleta de cores rosa e coral