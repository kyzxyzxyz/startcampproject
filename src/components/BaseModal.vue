<template>
  <div class="modal-overlay" @click.self="emitClose" tabindex="-1" role="presentation">
    <div class="modal-card" role="dialog" aria-modal="true" @click.stop>
      <slot />
    </div>
  </div>
</template>

<script>
import { onMounted, onBeforeUnmount } from 'vue'

export default {
  name: 'BaseModal',
  emits: ['close'],
  setup(_, { emit }) {
    function emitClose() {
      emit('close')
    }

    function onKeydown(e) {
      if (e.key === 'Escape' || e.key === 'Esc') {
        emit('close')
      }
    }

    onMounted(() => {
      document.addEventListener('keydown', onKeydown)
    })

    onBeforeUnmount(() => {
      document.removeEventListener('keydown', onKeydown)
    })

    return { emitClose }
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(2,6,23,0.48);
  z-index: 99999;
  -webkit-tap-highlight-color: transparent;
}

.modal-card {
  width: min(920px, 96%);
  max-height: 86vh;
  background: var(--card, #fff);
  border-radius: 12px;
  overflow: auto;
  box-shadow: 0 20px 60px rgba(2,6,23,0.12);
  border: 1px solid var(--border);
  box-sizing: border-box;
}
</style>