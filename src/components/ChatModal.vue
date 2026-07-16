<template>
  <div>
    <div class="floating-chat" aria-hidden="false">
      <BaseButton class="floating-chat-btn" @click="open" variant="primary" size="lg" aria-label="챗봇 열기">
        <svg class="chat-icon" width="28" height="28" viewBox="0 0 24 24" fill="none" aria-hidden>
          <path d="M21 15a2 2 0 0 1-2 2H8l-5 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v10z" stroke="#fff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </BaseButton>
    </div>

    <div v-if="visible" class="chat-modal-overlay" @click.self="close">
      <div class="chat-modal modal-card" role="dialog" aria-modal="true">
        <div class="chat-header">
          <strong>{{ $t('app.chatTitle') }}</strong>
          <BaseButton variant="ghost" size="sm" @click="close">✕</BaseButton>
        </div>

        <div class="chat-body">
          <ChatBot />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import ChatBot from './ChatBot.vue'
import BaseButton from './BaseButton.vue'

export default {
  components: { ChatBot, BaseButton },
  setup(_, { expose }) {
    const visible = ref(false)
    function open(){ visible.value = true }
    function close(){ visible.value = false }
    expose({ open, close })
    return { visible, open, close }
  }
}
</script>

<style scoped>
.floating-chat {
  position: fixed;
  right: 20px;
  bottom: 20px;
  z-index: 99999;
  display:flex;
  flex-direction:column;
  align-items:center;
  pointer-events:auto;
}
.floating-chat-btn {
  border-radius: 999px;
  width:64px;
  height:64px;
  display:flex;
  align-items:center;
  justify-content:center;
  padding:0;
  box-shadow:0 6px 18px rgba(2,6,23,0.08);
}

/* overlay: 다크/라이트 모두 var(--overlay) 사용 */
.chat-modal-overlay {
  position: fixed;
  inset: 0;
  background: var(--overlay, rgba(6,8,12,0.45));
  display:flex;
  align-items:center;
  justify-content:center;
  z-index: 99998;
  backdrop-filter: blur(4px);
}

/* responsive modal */
.chat-modal {
  width: clamp(320px, 90vw, 1100px);
  max-height: 95vh;
  height: auto;
  background: var(--card);
  color: var(--text);
  border-radius: 12px;
  overflow: hidden;
  display:flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(2,6,23,0.2);
  z-index: 99999;
  border: 1px solid var(--border);
}

/* Header: 배경과 테두리 var 사용, 텍스트 색상 조정 */
.chat-header {
  display:flex;
  align-items:center;
  justify-content:space-between;
  padding:12px 16px;
  border-bottom:1px solid var(--border);
  background: linear-gradient(90deg, color-mix(in srgb, var(--card) 98%, var(--glass) 2%), var(--card));
  color: var(--text);
}

/* body은 내용에 따라 크기가 조절되고, 내부(히스토리)는 필요 시 스크롤 */
.chat-body {
  padding:12px;
  display:flex;
  flex-direction:column;
  flex: 0 1 auto;
  min-height: 0;
  max-height: calc(95vh - 56px);
  overflow: visible;
  background: transparent;
  color: var(--text);
}

/* 버튼 등 내부 .base-btn이 var 색상 따라갈 수 있도록 보정 (optional) */
.base-btn {
  color: inherit;
}

/* 작은 화면용 세부 조정 */
@media (max-width: 480px) {
  .chat-modal { width: 96vw; border-radius: 8px; }
  .chat-body { padding: 8px; }
}
</style>