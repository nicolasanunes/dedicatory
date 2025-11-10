<template>
  <Transition name="unlock">
    <div v-if="!isUnlocked" class="password-overlay" :class="{ 'success': isUnlocking }">
      <div class="password-container" :class="{ 'success-animation': isUnlocking }">
        <div v-if="!isUnlocking" class="lock-icon">
          🔒
        </div>
        <div v-else class="success-content">
          <div class="unlock-icon">💕</div>
        </div>
        <div v-if="!isUnlocking" class="password-input-container">
          <input
            type="password"
            v-model="passwordInput"
            placeholder="Digite a senha..."
            class="password-input"
            maxlength="8"
            @input="validatePassword"
          />
          <div v-if="showError" class="error-message">
            {{ errorMessage }}
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import '../assets/css/password-protection.css'

// Definir emits
const emit = defineEmits<{
  unlocked: []
}>()

const isUnlocked = ref(false)
const isUnlocking = ref(false)
const passwordInput = ref('')
const showError = ref(false)
const passwordSchedule = [
  {
    date: new Date('2025-11-19T23:22:00'), // Data e hora específica
    password: '19112021' // Nova senha a partir dessa data
  },
  {
    date: new Date('2021-11-19T00:00:00'), // Data inicial
    password: '24445555' // Senha padrão
  }
]

// Sistema de mensagens de erro com datas programadas
const errorMessageSchedule = [
  {
    date: new Date('2025-11-19T22:22:00'), // A partir de 19/11/2025
    message: 'Ei, quem você pensa que é para acessar isto?'
  },
  {
    date: new Date('2021-11-19T00:00:00'), // Até 19/11/2025
    message: 'Calma lá, ansiosa!'
  }
]

// Computed property para determinar a senha correta baseada na data atual
const correctPassword = computed(() => {
  const now = new Date()
  
  // Ordenar por data decrescente e encontrar a primeira data que já passou
  const sortedSchedule = [...passwordSchedule].sort((a, b) => b.date.getTime() - a.date.getTime())
  
  for (const schedule of sortedSchedule) {
    if (now >= schedule.date) {
      console.log(`🔑 Senha ativa: ${schedule.password} (desde ${schedule.date.toLocaleString()})`)
      return schedule.password
    }
  }
  
  // Fallback para a senha mais antiga
  return passwordSchedule[passwordSchedule.length - 1].password
})

// Computed property para determinar a mensagem de erro baseada na data atual
const errorMessage = computed(() => {
  const now = new Date()
  
  // Ordenar por data decrescente e encontrar a primeira data que já passou
  const sortedSchedule = [...errorMessageSchedule].sort((a, b) => b.date.getTime() - a.date.getTime())
  
  for (const schedule of sortedSchedule) {
    if (now >= schedule.date) {
      return schedule.message
    }
  }
  
  // Fallback para a mensagem mais antiga
  return errorMessageSchedule[errorMessageSchedule.length - 1].message
})

const validatePassword = () => {
  showError.value = false
  
  if (passwordInput.value.length === 8) {
    if (passwordInput.value === correctPassword.value) {
      // Inicia animação de sucesso
      isUnlocking.value = true
      
      // Após 2 segundos, remove o componente completamente
      setTimeout(() => {
        isUnlocked.value = true
        emit('unlocked')
      }, 2000)
    } else {
      showError.value = true
      // Limpa o campo após 2 segundos
      setTimeout(() => {
        passwordInput.value = ''
        showError.value = false
      }, 3000)
    }
  }
}

// Limpa erro quando usuário digita novamente
watch(passwordInput, () => {
  if (showError.value && passwordInput.value.length < 8) {
    showError.value = false
  }
})
</script>

