<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useSpotifyAuth } from './composables/useSpotifyAuth'

// Verificar se está em desenvolvimento (computed para uso no template)
const isDev = computed(() => import.meta.env.DEV)

// Data de referência (19/11/2021 às 23:23)
const referenceDate = new Date('2021-11-19T23:23:00')

// Estados reativos para cada unidade de tempo
const years = ref(0)
const months = ref(0)
const days = ref(0)
const hours = ref(0)
const minutes = ref(0)
const seconds = ref(0)

let intervalId: number | null = null

// Estados do slideshow
const currentSlide = ref(0)
const isAutoPlaying = ref(true)
let slideInterval: number | null = null

// Array de fotos (você pode substituir por suas próprias imagens)
const photos = ref([
  {
    id: 1,
    src: './src/assets/foto1.jpg',
    alt: 'Foto 1',
  },
  {
    id: 2,
    src: './src/assets/foto2.jpeg',
    alt: 'Foto 2',
  },
  {
    id: 3,
    src: './src/assets/foto3.jpg',
    alt: 'Foto 3',
  },
])

// Funções do slideshow
const nextSlide = () => {
  currentSlide.value = (currentSlide.value + 1) % photos.value.length
}

const prevSlide = () => {
  currentSlide.value = currentSlide.value === 0 ? photos.value.length - 1 : currentSlide.value - 1
}

const goToSlide = (index: number) => {
  currentSlide.value = index
}

const toggleAutoPlay = () => {
  isAutoPlaying.value = !isAutoPlaying.value
  if (isAutoPlaying.value) {
    startAutoPlay()
  } else {
    stopAutoPlay()
  }
}

const startAutoPlay = () => {
  slideInterval = setInterval(nextSlide, 4000) // Muda a cada 4 segundos
}

const stopAutoPlay = () => {
  if (slideInterval) {
    clearInterval(slideInterval)
    slideInterval = null
  }
}

// ========== SPOTIFY WEB PLAYBACK API ==========

// INSTRUÇÕES PARA CONFIGURAÇÃO:
// 1. Vá para https://developer.spotify.com/dashboard
// 2. Crie um novo app
// 3. Configure o Redirect URI: http://localhost:5173
// 4. Copie o Client ID e cole abaixo
// 5. Para obter Access Token:
//    - Use uma ferramenta como Postman ou curl
//    - Endpoint: https://accounts.spotify.com/api/token
//    - Método: POST
//    - Headers: Authorization: Basic btoa(client_id:client_secret)
//    - Body: grant_type=client_credentials&scope=streaming user-read-email user-read-private
// 6. Cole o Access Token abaixo

// ========== SISTEMA DE AUTENTICAÇÃO COM RENOVAÇÃO AUTOMÁTICA ==========
const {
  isAuthenticated,
  minutesUntilExpiry,
  isRefreshing,
  lastRefreshError,
  initializeTokens,
  getValidToken,
  startAutoRefresh,
  spotifyApiRequest
} = useSpotifyAuth()

// Inicializar tokens ao carregar
initializeTokens()

// Estados do Spotify Player
const spotifyPlayer = ref<any>(null)
const isSpotifyReady = ref(false)
const isSpotifyConnected = ref(false)
const currentTrack = ref<any>(null)
const isPlaying = ref(false)
const isPaused = ref(false)
const deviceId = ref('')
const position = ref(0)
const duration = ref(0)
const volume = ref(0.7)

// Track URI da música que você quer tocar (configurável via .env.local)
const trackUri = import.meta.env.VITE_SPOTIFY_TRACK_URI || 'spotify:track:4uLU6hMCjMI75M1A2tKUQC' // Fallback para Perfect - Ed Sheeran

// Declarar tipos globais
declare global {
  interface Window {
    onSpotifyWebPlaybackSDKReady: () => void
    Spotify: any
  }
}

// Inicializar Spotify Web Playback SDK
const initSpotifyPlayer = () => {
  if (!window.Spotify) {
    console.error('Spotify SDK não carregado')
    return
  }

  const player = new window.Spotify.Player({
    name: 'Nossa Música Player ❤️',
    getOAuthToken: async (cb: (token: string) => void) => {
      const token = await getValidToken()
      if (token) {
        cb(token)
      } else {
        console.error('❌ Não foi possível obter token válido')
      }
    },
    volume: volume.value
  })

  // Event Listeners
  player.addListener('ready', ({ device_id }: { device_id: string }) => {
    console.log('Player pronto! Device ID:', device_id)
    deviceId.value = device_id
    isSpotifyReady.value = true
    isSpotifyConnected.value = true
  })

  player.addListener('not_ready', ({ device_id }: { device_id: string }) => {
    console.log('Player não disponível:', device_id)
    isSpotifyReady.value = false
  })

  player.addListener('player_state_changed', (state: any) => {
    if (!state) {
      currentTrack.value = null
      isPlaying.value = false
      isPaused.value = false
      position.value = 0
      duration.value = 0
      return
    }

    currentTrack.value = state.track_window.current_track
    isPlaying.value = !state.paused
    isPaused.value = state.paused
    position.value = state.position
    duration.value = state.duration

    console.log('Estado mudou:', {
      track: currentTrack.value?.name,
      artist: currentTrack.value?.artists[0]?.name,
      playing: isPlaying.value
    })
  })

  // Error handling
  player.addListener('initialization_error', ({ message }: { message: string }) => {
    console.error('Erro de inicialização:', message)
  })

  player.addListener('authentication_error', ({ message }: { message: string }) => {
    console.error('Erro de autenticação:', message)
  })

  player.addListener('account_error', ({ message }: { message: string }) => {
    console.error('Erro de conta:', message)
  })

  player.addListener('playback_error', ({ message }: { message: string }) => {
    console.error('Erro de reprodução:', message)
  })

  // Conectar o player
  player.connect().then((success: boolean) => {
    if (success) {
      console.log('Conectado ao Spotify Web Playback SDK!')
      spotifyPlayer.value = player
    } else {
      console.error('Falha ao conectar com o Spotify')
    }
  })
}

// Funções de controle do player (com renovação automática)
const playMusic = async () => {
  if (!deviceId.value) {
    console.warn('⚠️ Device ID não disponível')
    return
  }

  try {
    const response = await spotifyApiRequest(`https://api.spotify.com/v1/me/player/play?device_id=${deviceId.value}`, {
      method: 'PUT',
      body: JSON.stringify({
        uris: [trackUri],
        position_ms: 0
      }),
      headers: {
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      throw new Error(`Erro HTTP: ${response.status}`)
    }

    console.log('Música iniciada!')
  } catch (error) {
    console.error('Erro ao iniciar música:', error)
  }
}

const pauseMusic = async () => {
  if (!deviceId.value) {
    console.warn('⚠️ Device ID não disponível')
    return
  }

  try {
    await spotifyApiRequest(`https://api.spotify.com/v1/me/player/pause?device_id=${deviceId.value}`, {
      method: 'PUT'
    })
    console.log('Música pausada!')
  } catch (error) {
    console.error('Erro ao pausar música:', error)
  }
}

const togglePlayback = () => {
  if (isPlaying.value) {
    pauseMusic()
  } else {
    playMusic()
  }
}

const setVolume = async (newVolume: number) => {
  volume.value = newVolume
  
  if (spotifyPlayer.value) {
    await spotifyPlayer.value.setVolume(newVolume)
  }
}

const seekToPosition = async (positionMs: number) => {
  if (!deviceId.value) {
    console.warn('⚠️ Device ID não disponível')
    return
  }

  try {
    await spotifyApiRequest(`https://api.spotify.com/v1/me/player/seek?position_ms=${positionMs}&device_id=${deviceId.value}`, {
      method: 'PUT'
    })
  } catch (error) {
    console.error('Erro ao navegar na música:', error)
  }
}

// Formatar tempo em mm:ss
const formatTime = (ms: number) => {
  const minutes = Math.floor(ms / 60000)
  const seconds = Math.floor((ms % 60000) / 1000)
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}



// Lidar com clique na barra de progresso
const handleProgressClick = (event: MouseEvent) => {
  if (!duration.value) return
  
  const progressBar = event.currentTarget as HTMLElement
  const rect = progressBar.getBoundingClientRect()
  const clickPosition = (event.clientX - rect.left) / rect.width
  const newPosition = Math.floor(clickPosition * duration.value)
  
  seekToPosition(newPosition)
}

// Callback para quando o SDK estiver pronto
window.onSpotifyWebPlaybackSDKReady = () => {
  initSpotifyPlayer()
}

// ========== FIM SPOTIFY ==========

// Função para debug (apenas em desenvolvimento)
const showDebugInfo = () => {
  if (isDev.value) {
    const { getDebugInfo } = useSpotifyAuth()
    console.group('🐛 Debug Info - Sistema de Renovação Spotify')
    console.log(getDebugInfo())
    console.groupEnd()
  }
}

// Função para calcular a diferença de tempo
const calculateTimeDifference = () => {
  const now = new Date()
  
  // Cálculo dos anos
  let yearDiff = now.getFullYear() - referenceDate.getFullYear()
  
  // Ajuste para meses
  let monthDiff = now.getMonth() - referenceDate.getMonth()
  if (monthDiff < 0) {
    yearDiff--
    monthDiff += 12
  }
  
  // Ajuste para dias
  let dayDiff = now.getDate() - referenceDate.getDate()
  if (dayDiff < 0) {
    monthDiff--
    if (monthDiff < 0) {
      yearDiff--
      monthDiff += 12
    }
    
    // Pega o último dia do mês anterior
    const lastMonth = new Date(now.getFullYear(), now.getMonth(), 0)
    dayDiff += lastMonth.getDate()
  }
  
  // Diferença total em milissegundos para calcular horas, minutos e segundos
  const tempDate = new Date(referenceDate.getFullYear() + yearDiff, referenceDate.getMonth() + monthDiff, referenceDate.getDate() + dayDiff)
  const timeDiff = now.getTime() - tempDate.getTime()
  
  const hourDiff = Math.floor(timeDiff / (1000 * 60 * 60))
  const minuteDiff = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60))
  const secondDiff = Math.floor((timeDiff % (1000 * 60)) / 1000)
  
  // Atualiza os valores reativos
  years.value = yearDiff
  months.value = monthDiff
  days.value = dayDiff
  hours.value = hourDiff
  minutes.value = minuteDiff
  seconds.value = secondDiff
}

// Inicia o contador quando o componente é montado
onMounted(() => {
  calculateTimeDifference() // Calcula imediatamente
  intervalId = setInterval(calculateTimeDifference, 1000) // Atualiza a cada segundo
  
  // Inicia o slideshow automático
  if (isAutoPlaying.value) {
    startAutoPlay()
  }

  // ========== SISTEMA DE RENOVAÇÃO AUTOMÁTICA ==========
  // Iniciar monitoramento automático de renovação
  const stopAutoRefresh = startAutoRefresh()
  
  // Guardar função de cleanup para usar no onUnmounted
  ;(window as any).__stopAutoRefresh = stopAutoRefresh

  // Carregar Spotify Web Playback SDK
  const script = document.createElement('script')
  script.src = 'https://sdk.scdn.co/spotify-player.js'
  script.async = true
  document.body.appendChild(script)

  script.onload = () => {
    console.log('🎵 Spotify SDK carregado!')
  }

  script.onerror = () => {
    console.error('Erro ao carregar Spotify SDK')
  }
})

// Limpa os intervalos quando o componente é desmontado
onUnmounted(() => {
  if (intervalId) {
    clearInterval(intervalId)
  }
  stopAutoPlay()
  
  // Parar sistema de renovação automática
  if ((window as any).__stopAutoRefresh) {
    ;(window as any).__stopAutoRefresh()
    delete (window as any).__stopAutoRefresh
  }
  
  // Desconectar player do Spotify
  if (spotifyPlayer.value) {
    spotifyPlayer.value.disconnect()
  }
})
</script>

<template>
  <div class="container">
    <div class="logo-section">
      <a>
        <img src="/heart.svg" class="logo" alt="Heart logo" />
      </a>
    </div>

    <!-- ========== SPOTIFY PLAYER ========== -->
    <div class="spotify-player-section">
      <!-- Status de conexão -->
      <div v-if="!isSpotifyConnected" class="spotify-status">
        <div class="connecting">
          <div class="loading-spinner"></div>
          <p>Conectando ao Spotify...</p>
        </div>
      </div>

      <!-- Player ativo -->
      <div v-if="isSpotifyConnected" class="spotify-player">
        <div class="player-header">
          <h3>🎵 Nossa Música Especial</h3>
          <div class="connection-status">
            <span class="status-indicator" :class="{ connected: isSpotifyReady }"></span>
            <span>{{ isSpotifyReady ? 'Conectado' : 'Conectando...' }}</span>
          </div>
        </div>

        <!-- Status de renovação automática -->
        <div class="token-status">
          <div class="token-info">
            <span v-if="isAuthenticated" class="auth-status">
              🔐 Autenticado
            </span>
            <span v-if="minutesUntilExpiry < 10" class="expiry-warning">
              ⏰ Expira em {{ minutesUntilExpiry }} min
            </span>
            <span v-if="isRefreshing" class="refreshing">
              🔄 Renovando token...
            </span>
            <span v-if="lastRefreshError" class="error-status">
              ❌ Erro: {{ lastRefreshError }}
            </span>
          </div>
          <!-- Debug info (só em desenvolvimento) -->
          <div v-if="isDev" class="debug-info">
            <button @click="showDebugInfo()" class="debug-btn">
              🐛 Debug Info
            </button>
          </div>
        </div>

        <!-- Informações da música -->
        <div v-if="currentTrack" class="track-info">
          <div class="track-image">
            <img 
              v-if="currentTrack.album?.images[0]" 
              :src="currentTrack.album.images[0].url" 
              :alt="currentTrack.name"
            />
            <div v-else class="placeholder-image">🎵</div>
          </div>
          
          <div class="track-details">
            <div class="track-name">{{ currentTrack.name }}</div>
            <div class="track-artist">{{ currentTrack.artists[0]?.name }}</div>
          </div>
        </div>

        <!-- Controles de reprodução -->
        <div class="player-controls">
          <button 
            @click="togglePlayback" 
            class="play-pause-btn"
            :disabled="!isSpotifyReady"
            :title="isPlaying ? 'Pausar' : 'Tocar'"
          >
            <svg v-if="isPlaying" width="24" height="24" viewBox="0 0 24 24" fill="none">
              <rect x="6" y="4" width="4" height="16" fill="currentColor" rx="1"/>
              <rect x="14" y="4" width="4" height="16" fill="currentColor" rx="1"/>
            </svg>
            <svg v-else width="24" height="24" viewBox="0 0 24 24" fill="none">
              <polygon points="8,5 19,12 8,19" fill="currentColor"/>
            </svg>
          </button>

          <div class="playback-info">
            <span v-if="currentTrack" class="time">
              {{ formatTime(position) }} / {{ formatTime(duration) }}
            </span>
            <span v-else class="status">
              {{ isSpotifyReady ? 'Pronto para tocar' : 'Carregando...' }}
            </span>
          </div>
        </div>

        <!-- Barra de progresso -->
        <div v-if="currentTrack && duration > 0" class="progress-section">
          <div class="progress-bar" @click="handleProgressClick">
            <div 
              class="progress-fill" 
              :style="{ width: (position / duration) * 100 + '%' }"
            ></div>
          </div>
        </div>

        <!-- Controle de volume -->
        <div class="volume-section">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="volume-icon">
            <polygon points="11,5 6,9 2,9 2,15 6,15 11,19" stroke="currentColor" stroke-width="2" fill="none"/>
            <path d="M19.07 4.93a10 10 0 0 1 0 14.14" stroke="currentColor" stroke-width="2"/>
            <path d="M15.54 8.46a5 5 0 0 1 0 7.07" stroke="currentColor" stroke-width="2"/>
          </svg>
          <input 
            type="range" 
            min="0" 
            max="1" 
            step="0.1" 
            :value="volume"
            @input="(event: Event) => setVolume(parseFloat((event.target as HTMLInputElement).value))"
            class="volume-slider"
          />
          <span class="volume-text">{{ Math.round(volume * 100) }}%</span>
        </div>

        <!-- Botão para iniciar música -->
        <div v-if="isSpotifyReady && !currentTrack" class="start-music">
          <button @click="playMusic" class="start-btn">
            🎵 Tocar Nossa Música
          </button>
        </div>
      </div>
    </div>
    <!-- ========== FIM SPOTIFY PLAYER ========== -->

    <div class="photo-slideshow">
      <div class="slideshow-container">
        <!-- Slides -->
        <div class="slides-wrapper" :style="{ transform: `translateX(-${currentSlide * 33.333}%)` }">
          <div 
            v-for="(photo, index) in photos" 
            :key="photo.id"
            class="slide"
            :class="{ active: index === currentSlide }"
          >
            <img :src="photo.src" :alt="photo.alt" class="slide-image" />
          </div>
        </div>

        <!-- Controles de navegação -->
        <a @click="prevSlide" class="nav-btn prev-btn" aria-label="Foto anterior">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M15 18L9 12L15 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </a>
        
        <a @click="nextSlide" class="nav-btn next-btn" aria-label="Próxima foto">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M9 18L15 12L9 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </a>

        <!-- Indicadores de posição -->
        <div class="slide-indicators">
          <a 
            v-for="(photo, index) in photos" 
            :key="`indicator-${photo.id}`"
            @click="goToSlide(index)"
            class="indicator"
            :class="{ active: index === currentSlide }"
            :aria-label="`Ir para foto ${index + 1}`"
          ></a>
        </div>

        <!-- Controle de autoplay -->
        <div class="autoplay-controls">
          <a @click="toggleAutoPlay" class="autoplay-btn" :aria-label="isAutoPlaying ? 'Pausar slideshow' : 'Iniciar slideshow'">
            <svg v-if="isAutoPlaying" width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="6" y="4" width="4" height="16" fill="currentColor"/>
              <rect x="14" y="4" width="4" height="16" fill="currentColor"/>
            </svg>
            <svg v-else width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <polygon points="5,3 19,12 5,21" fill="currentColor"/>
            </svg>
          </a>
        </div>
      </div>
    </div>    
    <div>
      <h1>Eu te amo há:</h1>
      <h2>{{ years }} anos, {{ months }} meses, {{ days }} dias, {{ hours }} horas, {{ minutes }} minutos e {{ seconds }} segundos</h2>
    </div>
  </div>
</template>

<style scoped>
/* ========== SPOTIFY PLAYER STYLES ========== */
.spotify-player-section {
  width: 100%;
  max-width: 400px;
  margin: 1rem 0;
}

.spotify-status {
  background: linear-gradient(135deg, #1DB954, #1ed760);
  padding: 2rem;
  border-radius: 20px;
  text-align: center;
  color: white;
  box-shadow: 0 10px 30px rgba(29, 185, 84, 0.3);
}

.connecting {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 3px solid rgba(255, 255, 255, 0.3);
  border-top: 3px solid white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.spotify-player {
  background: linear-gradient(135deg, #1DB954, #1ed760);
  padding: 1.5rem;
  border-radius: 20px;
  color: white;
  box-shadow: 0 10px 30px rgba(29, 185, 84, 0.3);
  backdrop-filter: blur(10px);
}

.player-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.player-header h3 {
  margin: 0;
  font-size: 1.3rem;
  font-weight: 600;
}

.connection-status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.8rem;
  opacity: 0.9;
}

.status-indicator {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.5);
  transition: all 0.3s ease;
}

.status-indicator.connected {
  background: #fff;
  box-shadow: 0 0 10px rgba(255, 255, 255, 0.8);
}

/* Status de renovação automática */
.token-status {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  padding: 12px;
  margin-top: 10px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.token-info {
  display: flex;
  align-items: center;
  gap: 15px;
  flex-wrap: wrap;
  font-size: 0.8rem;
}

.auth-status {
  color: #1db954;
  font-weight: 500;
}

.expiry-warning {
  color: #ff9500;
  font-weight: 500;
  animation: pulse 2s infinite;
}

.refreshing {
  color: #1e90ff;
  font-weight: 500;
}

.error-status {
  color: #ff4444;
  font-weight: 500;
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.debug-info {
  margin-top: 8px;
}

.debug-btn {
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 4px;
  padding: 4px 8px;
  font-size: 0.7rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.debug-btn:hover {
  background: rgba(255, 255, 255, 0.2);
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

.track-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
  background: rgba(255, 255, 255, 0.1);
  padding: 1rem;
  border-radius: 15px;
  backdrop-filter: blur(5px);
}

.track-image {
  width: 60px;
  height: 60px;
  border-radius: 10px;
  overflow: hidden;
  flex-shrink: 0;
}

.track-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.placeholder-image {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.2);
  font-size: 1.5rem;
}

.track-details {
  flex: 1;
  min-width: 0;
}

.track-name {
  font-weight: 600;
  font-size: 1rem;
  margin-bottom: 0.25rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.track-artist {
  opacity: 0.8;
  font-size: 0.9rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.player-controls {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.play-pause-btn {
  background: white;
  color: #1DB954;
  border: none;
  width: 50px;
  height: 50px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
}

.play-pause-btn:hover:not(:disabled) {
  transform: scale(1.05);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
}

.play-pause-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

.playback-info {
  flex: 1;
  text-align: center;
}

.time {
  font-family: 'Courier New', monospace;
  font-size: 0.9rem;
  font-weight: 500;
}

.status {
  font-size: 0.8rem;
  opacity: 0.8;
}

.progress-section {
  margin-bottom: 1rem;
}

.progress-bar {
  width: 100%;
  height: 6px;
  background: rgba(255, 255, 255, 0.3);
  border-radius: 3px;
  cursor: pointer;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: white;
  border-radius: 3px;
  transition: width 0.1s ease;
}

.volume-section {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.volume-icon {
  color: white;
  opacity: 0.8;
}

.volume-slider {
  flex: 1;
  height: 4px;
  border-radius: 2px;
  background: rgba(255, 255, 255, 0.3);
  outline: none;
  cursor: pointer;
}

.volume-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: white;
  cursor: pointer;
}

.volume-slider::-moz-range-thumb {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: white;
  cursor: pointer;
  border: none;
}

.volume-text {
  font-size: 0.8rem;
  opacity: 0.8;
  min-width: 35px;
  text-align: right;
}

.start-music {
  text-align: center;
  padding: 1rem 0;
}

.start-btn {
  background: white;
  color: #1DB954;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 25px;
  font-weight: 600;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
}

.start-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
}

/* ========== EXISTING STYLES ========== */
.spotify-player iframe {
  border-radius: 12px;
}

.container {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-height: 100vh;
  padding: 2rem;
}

.logo {
  height: 6em;
  padding: 1.5em;
  will-change: filter;
  transition: filter 300ms;
}

.logo:hover {
  filter: drop-shadow(0 0 2em #646cffaa);
}

.logo.vue:hover {
  filter: drop-shadow(0 0 2em #42b883aa);
}

/* Estilos do slideshow */
.photo-slideshow {
  width: 100%;
  max-width: 400px;
  margin: 2rem 0;
}

.slideshow-container {
  border: solid 8px white;
  border-bottom: solid 50px white;
  position: relative;
  width: 100%;
  height: 500px;
  overflow: hidden;
  background: #FF746C;
}

.slides-wrapper {
  display: flex;
  width: 300%;
  height: 100%;
  transition: transform 0.8s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

.slide {
  width: 33.333%;
  height: 100%;
  position: relative;
  flex-shrink: 0;
}

.slide-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.slide:hover .slide-image {
  transform: scale(1.05);
}

/* Botões de navegação */
.nav-btn {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  border: none;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
  z-index: 10;
  color: white;
}

.nav-btn:hover {
  transform: translateY(-50%) scale(1.1);
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
}

.prev-btn {
  left: 0px;
}

.next-btn {
  right: 0px;
}

/* Indicadores */
.slide-indicators {
  border: solid 2px white;
  padding: 2px 12px;
  border-radius: 12px;
  position: absolute;
  bottom: 10px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 6px;
  z-index: 10;
}

.indicator {
  width: 4px;
  height: 4px;
  background: white;
  cursor: pointer;
  transition: all 0.3s ease;
}

.indicator:hover {
  transform: scale(1.2);
  background: #333;
}

.indicator.active {
  background: #333;
  width: 16px;
}

/* Controles de autoplay */
.autoplay-controls {
  position: absolute;
  top: 0px;
  right: 0px;
  z-index: 10;
}

.autoplay-btn {
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
  color: white;
}

.autoplay-btn:hover {
  transform: scale(1.1);
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
}

/* Estilos do contador */
h1 {
  font-size: 2.5rem;
  font-weight: 700;
  color: #333;
  margin-bottom: 1rem;
  text-align: center;
  background: linear-gradient(45deg, #ff6b9d, #c44569);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

h2 {
  font-size: 1.5rem;
  color: #555;
  text-align: center;
  font-weight: 500;
  line-height: 1.6;
  background: rgba(255, 255, 255, 0.9);
  padding: 1.5rem;
  border-radius: 15px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  backdrop-filter: blur(10px);
}

/* Responsividade */
@media (max-width: 768px) {
  .container {
    padding: 1rem;
  }
  
  .slideshow-container {
    height: 400px;
  }
  
  .nav-btn {
    width: 40px;
    height: 40px;
  }
  
  .prev-btn {
    left: 10px;
  }
  
  .next-btn {
    right: 10px;
  }
  
  h1 {
    font-size: 2rem;
  }
  
  h2 {
    font-size: 1.2rem;
    padding: 1rem;
  }
}

@media (max-width: 480px) {
  .slideshow-container {
    height: 300px;
  }
  
  h1 {
    font-size: 1.8rem;
  }
  
  h2 {
    font-size: 1rem;
  }
}
</style>