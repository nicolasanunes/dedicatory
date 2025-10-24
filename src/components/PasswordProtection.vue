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
            Ei, quem você pensa que é para acessar isto?
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'

// Definir emits
const emit = defineEmits<{
  unlocked: []
}>()

const isUnlocked = ref(false)
const isUnlocking = ref(false)
const passwordInput = ref('')
const showError = ref(false)
const correctPassword = '19112021'

const validatePassword = () => {
  showError.value = false
  
  if (passwordInput.value.length === 8) {
    if (passwordInput.value === correctPassword) {
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

<style scoped>
.password-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
  backdrop-filter: blur(20px);
}

.password-container {
  backdrop-filter: blur(20px);
  padding: 40px;
  text-align: center;
  max-width: 400px;
  width: 90%;
}

.lock-icon {
  font-size: 8rem;
  margin-bottom: 20px;
  animation: pulse 2s ease-in-out infinite alternate;
}

.password-input-container {
  position: relative;
}

.password-input {
  width: 75%;
  padding: 15px 20px;
  border: none;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.9);
  font-size: 1.2rem;
  text-align: center;
  letter-spacing: 2px;
  outline: none;
  transition: all 0.3s ease;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
  box-sizing: border-box;
}

.password-input:focus {
  background: rgba(255, 255, 255, 1);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.3);
  transform: translateY(-2px);
}

.password-input::placeholder {
  color: #666;
  letter-spacing: 1px;
}

.error-message {
  color: red;
  font-family: Arial, sans-serif;
  font-size: 1.1rem;
  margin-top: 15px;
  font-weight: 600;
  text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.3);
  animation: shake 0.5s ease-in-out;
}

@keyframes pulse {
  from {
    transform: scale(1);
    opacity: 0.8;
  }
  to {
    transform: scale(1.1);
    opacity: 1;
  }
}

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-5px); }
  75% { transform: translateX(5px); }
}

/* Animações de sucesso */
.success-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  animation: successPop 1.5s ease-out forwards;
}

.unlock-icon {
  font-size: 6rem;
  animation: sparkle 1s ease-in-out infinite alternate;
  margin-bottom: 20px;
}

.success-message {
  color: #fff;
  font-family: 'Dancing Script', cursive;
  font-size: 2rem;
  font-weight: 700;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
  animation: slideInUp 0.8s ease-out 0.5s both;
}

.success-animation {
  animation: bounceSuccess 1s ease-out forwards;
}

.password-overlay.success {
  background: linear-gradient(135deg, #e74c3c 0%, #c0392b 50%, #a93226 100%);
  animation: fadeToRed 1s ease-out forwards;
}

/* Transições do componente principal */
.unlock-enter-active {
  transition: all 0.3s ease-out;
}

.unlock-leave-active {
  transition: all 0.8s ease-in;
}

.unlock-enter-from {
  opacity: 0;
  transform: scale(0.9);
}

.unlock-leave-to {
  opacity: 0;
  transform: scale(1.1);
  filter: blur(10px);
}

@keyframes successPop {
  0% {
    transform: scale(0.3) rotate(-180deg);
    opacity: 0;
  }
  50% {
    transform: scale(1.1) rotate(0deg);
    opacity: 1;
  }
  100% {
    transform: scale(1) rotate(0deg);
    opacity: 1;
  }
}

@keyframes sparkle {
  from {
    transform: scale(1) rotate(0deg);
    filter: hue-rotate(0deg);
  }
  to {
    transform: scale(1.1) rotate(10deg);
    filter: hue-rotate(60deg);
  }
}

@keyframes slideInUp {
  from {
    transform: translateY(30px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

@keyframes bounceSuccess {
  0%, 20%, 40%, 60%, 80% {
    transform: translateY(0) scale(1);
  }
  10% {
    transform: translateY(-10px) scale(1.05);
  }
  30% {
    transform: translateY(-5px) scale(1.02);
  }
  50% {
    transform: translateY(-3px) scale(1.01);
  }
}

@keyframes fadeToRed {
  from {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  }
  to {
    background: linear-gradient(135deg, #e74c3c 0%, #c0392b 50%, #a93226 100%);
  }
}

/* Responsividade */
@media (max-width: 480px) {
  .password-container {
    padding: 30px 20px;
  }
  
  .lock-icon {
    font-size: 6rem;
  }
  
  .unlock-icon {
    font-size: 4rem;
  }
  
  .success-message {
    font-size: 1.5rem;
  }
  
  .password-input {
    font-size: 1rem;
    padding: 12px 15px;
  }
  
  .error-message {
    font-size: 1rem;
  }
}
</style>