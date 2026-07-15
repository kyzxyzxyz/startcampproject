<template>
  <div>
    <div class="floating-chat" aria-hidden="false">
      <button class="floating-chat-btn" @click="open" aria-label="챗봇 열기">
        <svg class="chat-icon" width="28" height="28" viewBox="0 0 24 24" fill="none" aria-hidden>
          <path d="M21 15a2 2 0 0 1-2 2H8l-5 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v10z" stroke="#2563eb" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
          <circle cx="8.5" cy="11.5" r="0.9" fill="#2563eb"/>
          <circle cx="11.5" cy="11.5" r="0.9" fill="#2563eb"/>
          <circle cx="14.5" cy="11.5" r="0.9" fill="#2563eb"/>
        </svg>
      </button>
    </div>

    <div v-if="visible" class="chat-modal-overlay" @click.self="close">
      <div class="chat-modal" role="dialog" aria-modal="true">
        <div class="chat-header">
          <strong>지역 챗봇</strong>
          <button class="close-btn" @click="close" aria-label="닫기">✕</button>
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

export default {
  components: { ChatBot },
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
  display: flex;
  flex-direction: column;
  align-items: center;
  pointer-events: auto;
}
.floating-chat-btn {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: white;
  border: 4px solid rgba(37,99,235,0.12);
  display:flex;
  align-items:center;
  justify-content:center;
  cursor: pointer;
  padding:0;
  box-shadow: 0 6px 18px rgba(2,6,23,0.08);
}

/* overlay + modal */
.chat-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(6,8,12,0.45);
  display:flex;
  align-items:center;
  justify-content:center;
  z-index: 99998;
}
.chat-modal {
  width: min(960px, 96%);
  max-height: 95vh;           /* 증가: 화면의 95% 높이 */
  background: white;
  border-radius: 12px;
  overflow: hidden;
  display:flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(2,6,23,0.2);
  z-index: 99999;
}
.chat-header { display:flex; align-items:center; justify-content:space-between; padding:12px 16px; border-bottom:1px solid rgba(15,23,42,0.04); background: linear-gradient(90deg,#f8fafc,#ffffff); }
.close-btn { border:none; background:transparent; font-size:16px; cursor:pointer; }

/* body: ChatBot가 full-height을 쓸 수 있게 flex로 확장 */
.chat-body {
  padding:12px;
  overflow:hidden;
  display:flex;
  flex-direction:column;
  min-height: 640px;            /* 충분히 세로 길이 확보 */
  max-height: calc(95vh - 56px); /* 헤더 높이(약 56) 빼기 */
}
</style>