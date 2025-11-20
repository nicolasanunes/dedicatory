<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useSpotifyAuth } from './composables/useSpotifyAuth'
import PasswordProtection from './components/PasswordProtection.vue'
import './assets/css/index.css'

// Estado de proteção por senha
const isContentUnlocked = ref(false)

// Data de referência (19/11/2021 às 23:23)
const referenceDate = new Date('2021-11-19T23:23:00')

// Função para liberar o conteúdo
const handleUnlocked = () => {
  isContentUnlocked.value = true
}

// Estados reativos para cada unidade de tempo
const years = ref(0)
const months = ref(0)
const days = ref(0)
const hours = ref(0)
const minutes = ref(0)
const seconds = ref(0)

let intervalId: NodeJS.Timeout | null = null

// Estados do slideshow
const currentSlide = ref(0)
const isAutoPlaying = ref(true)
let slideInterval: NodeJS.Timeout | null = null

// Array de fotos (você pode substituir por suas próprias imagens)
const photos = ref([
  {
    id: 1,
    src: 'https://i.ibb.co/d4G629jy/031-E9-BDE-6-F7-A-4648-9-AA9-F64884-A968-A1.jpg',
    alt: 'Foto 1',
  },
  {
    id: 2,
    src: 'https://i.ibb.co/kVxxpm9p/CFAB8-E37-47-AB-4894-9856-85462-FA265-D2.jpg',
    alt: 'Foto 2',
  },
  {
    id: 3,
    src: 'https://i.ibb.co/KxvD8wx1/CFCF608-F-E40-B-4205-AB2-A-7-A4-BF17-B4407.jpg',
    alt: 'Foto 3',
  },
  {
    id: 4,
    src: 'https://i.ibb.co/ZRKm25zH/D582-DCC4-91-C5-44-C5-92-B1-9251658-EBC37.jpg',
    alt: 'Foto 4',
  },
  {
    id: 5,
    src: 'https://i.ibb.co/fdvNwB7z/IMG-0261.jpg',
    alt: 'Foto 5',
  },
  {
    id: 6,
    src: 'https://i.ibb.co/21SM1YTm/IMG-0808.jpg',
    alt: 'Foto 6',
  },
  {
    id: 7,
    src: 'https://i.ibb.co/NdQG873k/IMG-3964.jpg',
    alt: 'Foto 7',
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
  initializeTokens,
  getValidToken,
  startAutoRefresh,
  spotifyApiRequest,
  isAuthenticated,
  getDebugInfo
} = useSpotifyAuth()

// Variável para rastrear se tokens foram inicializados
const tokensInitialized = ref(false)

// Inicializar tokens ao carregar (async)
const initTokens = async () => {
  await initializeTokens()
  tokensInitialized.value = true
  console.log('✅ Tokens inicializados')
  console.log('📊 Debug:', getDebugInfo())
}

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
const volume = ref(0.3)
const isSafariMobile = ref(false)
const hasUserInteracted = ref(false)
const spotifyError = ref<string | null>(null)
const isPremium = ref(true)
let positionUpdateInterval: NodeJS.Timeout | null = null

// Track URI da música que você quer tocar (configurável via .env.local)
const trackUri = import.meta.env.VITE_SPOTIFY_TRACK_URI || 'spotify:track:2o2xhyri4aJUtgMGkf5P0J' // Fallback para Lisboa - Anavitoria, Lenine





// Declarar tipos globais
declare global {
  interface Window {
    onSpotifyWebPlaybackSDKReady: () => void
    Spotify: any
  }
}

// Função para atualizar a posição da música em tempo real
const startPositionUpdate = () => {
  if (positionUpdateInterval) {
    clearInterval(positionUpdateInterval)
  }
  
  positionUpdateInterval = setInterval(async () => {
    if (spotifyPlayer.value && isPlaying.value) {
      try {
        const state = await spotifyPlayer.value.getCurrentState()
        if (state) {
          position.value = state.position
        }
      } catch (error) {
        // Silently handle errors to avoid spam
      }
    }
  }, 1000) // Atualiza a cada segundo
}

const stopPositionUpdate = () => {
  if (positionUpdateInterval) {
    clearInterval(positionUpdateInterval)
    positionUpdateInterval = null
  }
}

// Detectar Safari mobile
const detectSafariMobile = () => {
  const ua = navigator.userAgent
  const isSafari = /Safari/.test(ua) && !/Chrome/.test(ua)
  const isMobile = /Mobile|Android|iPhone|iPad/.test(ua)
  return isSafari && isMobile
}

// Verificar se a conta tem Spotify Premium
const checkPremiumStatus = async () => {
  try {
    // Aguardar tokens estarem prontos
    if (!tokensInitialized.value) {
      console.log('⏳ Aguardando inicialização dos tokens...')
      await initTokens()
    }
    
    // Verificar se está autenticado
    if (!isAuthenticated.value) {
      console.error('❌ Não autenticado. Verifique suas credenciais no .env.local')
      spotifyError.value = 'Credenciais do Spotify não configuradas'
      return false
    }

    console.log('🔍 Verificando status Premium...')
    const response = await spotifyApiRequest('https://api.spotify.com/v1/me')
    
    if (!response.ok) {
      const errorText = await response.text()
      console.error('❌ Erro ao verificar status da conta:', {
        status: response.status,
        statusText: response.statusText,
        error: errorText
      })
      
      if (response.status === 401) {
        spotifyError.value = 'Token inválido. Verifique o refresh token no .env.local'
      }
      return false
    }
    
    const data = await response.json()
    const premium = data.product === 'premium'
    
    if (!premium) {
      console.error('❌ Spotify Premium necessário para usar o Web Playback SDK')
      spotifyError.value = 'Spotify Premium é necessário para reproduzir músicas'
      isPremium.value = false
    } else {
      console.log('✅ Conta Premium verificada:', data.display_name)
      isPremium.value = true
    }
    
    return premium
  } catch (error) {
    console.error('❌ Erro ao verificar Premium:', error)
    spotifyError.value = 'Erro ao conectar com Spotify'
    return false
  }
}

// Inicializar Spotify Web Playback SDK
const initSpotifyPlayer = async () => {
  console.log('🎵 Iniciando Spotify Player...')
  
  // Verificar se tem Premium primeiro
  const hasPremium = await checkPremiumStatus()
  if (!hasPremium) {
    return
  }
  
  // Detectar Safari mobile
  isSafariMobile.value = detectSafariMobile()
  console.log('🍎 Safari mobile detectado:', isSafariMobile.value)
  
  if (!window.Spotify) {
    console.error('❌ Spotify SDK não carregado')
    return
  }



  // Verificar se o navegador suporta Web Playback SDK
  if (!window.Spotify.Player) {
    console.error('❌ Web Playback SDK não suportado neste navegador')
    return
  }

  console.log('✅ Criando player Spotify...')
  
  try {
    const player = new window.Spotify.Player({
      name: 'Nossa Música Player ❤️',
      getOAuthToken: async (cb: (token: string) => void) => {
        try {
          const token = await getValidToken()
          if (token) {
            console.log('✅ Token obtido para player')
            cb(token)
          } else {
            console.error('❌ Não foi possível obter token válido')
          }
        } catch (error) {
          console.error('❌ Erro ao obter token:', error)
        }
      },
      volume: volume.value
    })
    
    console.log('✅ Player Spotify criado com sucesso')

  // Event Listeners
  player.addListener('ready', ({ device_id }: { device_id: string }) => {
    console.log('Player pronto! Device ID:', device_id)
    deviceId.value = device_id
    isSpotifyReady.value = true
    isSpotifyConnected.value = true
    
    // Carregar música automaticamente mas pausada
    setTimeout(() => {
      loadMusicPaused()
    }, 1)
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
      stopPositionUpdate()
      return
    }

    currentTrack.value = state.track_window.current_track
    isPlaying.value = !state.paused
    isPaused.value = state.paused
    position.value = state.position
    duration.value = state.duration

    // Iniciar ou parar atualização da posição baseado no estado
    if (isPlaying.value) {
      startPositionUpdate()
    } else {
      stopPositionUpdate()
    }

    console.log('Estado mudou:', {
      track: currentTrack.value?.name,
      artist: currentTrack.value?.artists[0]?.name,
      playing: isPlaying.value
    })
  })

  // Error handling
  player.addListener('initialization_error', ({ message }: { message: string }) => {
    console.error('❌ Erro de inicialização:', message)
    spotifyError.value = `Erro de inicialização: ${message}`
  })

  player.addListener('authentication_error', async ({ message }: { message: string }) => {
    console.error('❌ Erro de autenticação:', message)
    spotifyError.value = `Erro de autenticação: ${message}`
    
    // Tentar renovar token automaticamente
    console.log('🔄 Tentando renovar token após erro de autenticação...')
    const newToken = await getValidToken()
    
    if (newToken) {
      console.log('✅ Token renovado, reconectando player...')
      // Reconectar player com novo token
      player.disconnect()
      setTimeout(() => {
        initSpotifyPlayer()
      }, 1000)
    } else {
      console.error('❌ Não foi possível renovar token')
    }
  })

  player.addListener('account_error', ({ message }: { message: string }) => {
    console.error('❌ Erro de conta:', message)
    spotifyError.value = `Erro de conta: ${message}. Verifique se sua conta tem Spotify Premium.`
  })

  player.addListener('playback_error', ({ message }: { message: string }) => {
    console.error('❌ Erro de reprodução:', message)
    spotifyError.value = `Erro de reprodução: ${message}`
  })

  // Conectar o player
  console.log('🔌 Tentando conectar ao Spotify...')
  player.connect().then((success: boolean) => {
    console.log('🔌 Resultado da conexão:', success)
    if (success) {
      console.log('✅ Conectado ao Spotify Web Playback SDK!')
      spotifyPlayer.value = player
    } else {
      console.error('❌ Falha ao conectar com o Spotify')
      console.error(' User Agent:', navigator.userAgent)
    }
  }).catch((error: any) => {
    console.error('❌ Erro na conexão do Spotify:', error)
  })
  
  } catch (error) {
    console.error('❌ Erro ao criar player Spotify:', error)
  }
}

// Função para carregar música pausada
const loadMusicPaused = async () => {
  if (!deviceId.value) {
    console.warn('⚠️ Device ID não disponível para carregar música')
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

    console.log('🎵 Música carregada!')
    
    // Pausar imediatamente após carregar
    setTimeout(() => {
      pauseMusic()
    }, 500)
  } catch (error) {
    console.error('❌ Erro ao carregar música:', error)
  }
}

// Funções de controle do player (com renovação automática)
const playMusic = async () => {
  if (!deviceId.value) {
    console.warn('⚠️ Device ID não disponível')
    return
  }

  // Marcar que o usuário interagiu (importante para Safari)
  hasUserInteracted.value = true

  try {
    // Para Safari mobile, aguardar um pouco antes de executar
    if (isSafariMobile.value) {
      await new Promise(resolve => setTimeout(resolve, 100))
    }

    // Se já há uma música carregada e pausada, usar resume
    if (currentTrack.value && isPaused.value) {
      const response = await spotifyApiRequest(`https://api.spotify.com/v1/me/player/play?device_id=${deviceId.value}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        }
      })

      if (!response.ok) {
        throw new Error(`Erro HTTP: ${response.status}`)
      }

      console.log('🎵 Música retomada!')
    } else {
      // Iniciar música do começo se não há música carregada
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

      console.log('🎵 Música iniciada!')
    }

    // Para Safari mobile, forçar o estado de playing
    if (isSafariMobile.value && spotifyPlayer.value) {
      setTimeout(() => {
        spotifyPlayer.value.resume().catch((error: any) => {
          console.log('Resume não necessário:', error)
        })
      }, 200)
    }
  } catch (error) {
    console.error('❌ Erro ao iniciar música:', error)
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
  // Garantir que houve interação do usuário para Safari
  if (isSafariMobile.value && !hasUserInteracted.value) {
    hasUserInteracted.value = true
  }

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



// Formatar tempo em mm:ss
const formatTime = (ms: number) => {
  const minutes = Math.floor(ms / 60000)
  const seconds = Math.floor((ms % 60000) / 1000)
  return `${minutes}:${seconds.toString().padStart(2, '0')}`
}





// Callback para quando o SDK estiver pronto
window.onSpotifyWebPlaybackSDKReady = () => {
  initSpotifyPlayer()
}

// ========== FIM SPOTIFY ==========



// Função para calcular a diferença de tempo
const calculateTimeDifference = () => {
  const now = new Date()
  let tempDate = new Date(referenceDate)
  
  // Anos
  let yearsDiff = 0
  while (tempDate.getFullYear() < now.getFullYear() || 
         (tempDate.getFullYear() === now.getFullYear() && 
          (tempDate.getMonth() < now.getMonth() || 
           (tempDate.getMonth() === now.getMonth() && 
            tempDate.getDate() <= now.getDate() &&
            tempDate.getTime() <= now.getTime())))) {
    const nextYear = new Date(tempDate)
    nextYear.setFullYear(nextYear.getFullYear() + 1)
    if (nextYear.getTime() <= now.getTime()) {
      yearsDiff++
      tempDate = nextYear
    } else {
      break
    }
  }
  
  // Meses
  let monthsDiff = 0
  while (tempDate.getMonth() < now.getMonth() || 
         (tempDate.getMonth() === now.getMonth() && tempDate.getDate() <= now.getDate() && tempDate.getTime() <= now.getTime()) ||
         (tempDate.getMonth() > now.getMonth() && tempDate.getFullYear() < now.getFullYear())) {
    const nextMonth = new Date(tempDate)
    nextMonth.setMonth(nextMonth.getMonth() + 1)
    if (nextMonth.getTime() <= now.getTime()) {
      monthsDiff++
      tempDate = nextMonth
    } else {
      break
    }
  }
  
  // Dias, horas, minutos, segundos
  const remainingMs = now.getTime() - tempDate.getTime()
  const daysDiff = Math.floor(remainingMs / (1000 * 60 * 60 * 24))
  const hoursDiff = Math.floor((remainingMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
  const minutesDiff = Math.floor((remainingMs % (1000 * 60 * 60)) / (1000 * 60))
  const secondsDiff = Math.floor((remainingMs % (1000 * 60)) / 1000)
  
  // Atualiza os valores reativos
  years.value = yearsDiff
  months.value = monthsDiff
  days.value = daysDiff
  hours.value = hoursDiff
  minutes.value = minutesDiff
  seconds.value = secondsDiff
}

// Inicia o contador quando o componente é montado
onMounted(async () => {
  calculateTimeDifference() // Calcula imediatamente
  intervalId = setInterval(calculateTimeDifference, 1000) // Atualiza a cada segundo
  
  // Inicia o slideshow automático
  if (isAutoPlaying.value) {
    startAutoPlay()
  }

  // ========== SISTEMA DE RENOVAÇÃO AUTOMÁTICA ==========
  // Inicializar tokens ANTES de tudo
  await initTokens()
  
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
  stopPositionUpdate()
  
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
  <!-- Componente de proteção por senha -->
  <PasswordProtection @unlocked="handleUnlocked" />
  
  <!-- Conteúdo principal - só aparece quando desbloqueado -->
  <div v-if="isContentUnlocked" class="container">
    <!-- ========== SPOTIFY PLAYER ========== -->
    <div class="spotify-player-section">
      <!-- Mensagem de erro -->
      <div v-if="spotifyError" class="spotify-error">
        <p>⚠️ {{ spotifyError }}</p>
      </div>

      <!-- Status de conexão -->
      <div v-if="!isSpotifyConnected && !spotifyError" class="spotify-status">
        <div class="connecting">
          <p>Conectando ao Spotify...</p>
        </div>
      </div>

      <div v-if="isSpotifyConnected && !currentTrack && !spotifyError" class="spotify-status">
        <div class="connecting">
          <p>Carregando a música...</p>
        </div>
      </div>

      <!-- Player ativo ou interface padrão -->
      <div v-if="isSpotifyConnected && currentTrack">
        <!-- Informações da música -->
        <div class="track-info">
          <div class="track-image">
            <img 
              v-if="currentTrack?.album?.images[0]" 
              :src="currentTrack.album.images[0].url" 
              :alt="currentTrack.name"
            />
          </div>
          <div class="track-infos">
            <div>
              <div class="track-name">
                <span v-if="currentTrack">{{ currentTrack.name }} - {{ currentTrack.artists[0]?.name }}</span>
              </div>
            </div>

            <div class="playback-info">
              <span class="time">
                {{ currentTrack ? `${formatTime(position)} / ${formatTime(duration)}` : '0:00 / 0:00' }}
              </span>
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
            </div>
          </div>
          <!-- Controles de reprodução -->
          <div class="player-controls">
            <a 
              @click="togglePlayback" 
              class="play-pause-btn"
              :disabled="!isSpotifyReady"
              :title="isPlaying ? 'Pausar' : 'Tocar'"
            >
              <svg v-if="isPlaying" width="36" height="36" viewBox="0 0 24 24" fill="none">
                <rect x="6" y="4" width="4" height="16" fill="currentColor" rx="1"/>
                <rect x="14" y="4" width="4" height="16" fill="currentColor" rx="1"/>
              </svg>
              <svg v-else width="36" height="36" viewBox="0 0 24 24" fill="none">
                <polygon points="8,5 19,12 8,19" fill="currentColor"/>
              </svg>
            </a>
          </div>
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
    <h1>Eu te amo há:</h1>
    <div class="time-contador">
      <h2>{{ years }} anos, {{ months }} meses, {{ days }} dias, {{ hours }} horas, {{ minutes }} minutos e {{ seconds }} segundos</h2>
    </div>
    <div class="romantic-text">
      <p>A cada dia que passa, meu coração se enche mais de carinho e admiração por você.</p>
      <p>Cada sorriso seu ilumina o meu mundo, e cada abraço me faz sentir que estou exatamente onde deveria estar.</p>
      <p>Você é a razão dos meus melhores pensamentos, e tudo ao seu lado se torna mais bonito e significativo.</p>
      <p class="love-you-text">Eu te amo ❤️</p>
    </div>
  </div>
</template>

