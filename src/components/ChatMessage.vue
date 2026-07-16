<template>
  <div :class="['msg', role]">
    <div class="bubble" v-html="escapedText"></div>
  </div>
</template>

<script>
export default {
  props: { role: String, text: String },
  computed: {
    escapedText() {
      const s = String(this.text || '')
      const esc = s
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
      return esc.replace(/\n/g, '<br/>')
    }
  }
}
</script>

<style scoped>
.msg { margin:8px 0; display:flex; }
.msg.user { justify-content:flex-end; }
.msg.assistant { justify-content:flex-start; }

/* 말풍선 기본 */
.bubble {
  padding:10px 12px;
  border-radius:12px;
  max-width:72%;
  word-break:break-word;
  line-height:1.4;
  box-shadow: 0 4px 12px rgba(2,6,23,0.06);
}

/* 사용자 메시지: 강조된 색 (primary) */
.msg.user .bubble {
  background: var(--primary);
  color: #ffffff;
  border: 1px solid color-mix(in srgb, var(--primary) 80%, transparent);
  border-bottom-right-radius:4px;
}

/* 어시스턴트(봇) 메시지: 카드 배경 + 테두리 */
.msg.assistant .bubble {
  background: var(--card);
  color: var(--text);
  border: 1px solid var(--border);
  border-bottom-left-radius:4px;
}

/* 작은 화면에서 폭 조절 */
@media (max-width:560px) {
  .bubble { max-width: 86%; padding:10px; }
}
</style>