<template>
  <div class="chat-wrapper">
    <div class="history" ref="historyRef">
      <ChatMessage v-for="(m, i) in history" :key="i" :role="m.role" :text="m.text" />
    </div>

    <div class="input-row">
      <input v-model="q" @keydown.enter="send" :placeholder="t('chat.placeholder')" />
      <BaseButton variant="primary" @click="send">{{ t('chat.send') }}</BaseButton>
    </div>

    <div class="quick">
      <BaseButton variant="primary" @click="presetKey(1)">{{ t('chat.preset1') }}</BaseButton>
      <BaseButton variant="primary" @click="presetKey(2)">{{ t('chat.preset2') }}</BaseButton>
      <BaseButton variant="primary" @click="presetKey(3)">{{ t('chat.preset3') }}</BaseButton>
      <BaseButton variant="neutral" class="reset-btn" @click="clear">{{ t('chat.clear') }}</BaseButton>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, nextTick } from 'vue'
import ChatMessage from './ChatMessage.vue'
import { loadAllData, simpleRank } from '../utils/dataSearch'
import { callOpenAI } from '../utils/openai'
import { useI18n } from 'vue-i18n'
import BaseButton from './BaseButton.vue'

export default {
  components: { ChatMessage, BaseButton },
  setup() {
    const { t } = useI18n()
    const q = ref('')
    const history = ref([{ role: 'assistant', text: t('chat.greeting') }])
    const dataCache = ref([])
    const historyRef = ref(null)
    const sending = ref(false)

    onMounted(async () => {
      dataCache.value = await loadAllData()
      await nextTick()
      scrollToBottom(false)
    })

    function scrollToBottom(smooth = true) {
      const el = historyRef.value
      if (!el) return
      try {
        const top = el.scrollHeight
        if (smooth) el.scrollTo({ top, behavior: 'smooth' })
        else el.scrollTop = top
      } catch (e) { el.scrollTop = el.scrollHeight }
    }

    async function send(textArg) {
      if (sending.value) return
      const raw = (typeof textArg === 'string') ? textArg : q.value
      if (!raw || !raw.trim()) return
      sending.value = true
      const userText = raw.trim()
      history.value.push({ role: 'user', text: userText })

      const top = simpleRank(userText, dataCache.value, 5)
      const summary = top.map(item =>
        `- ${item.title || ''}${item.addr1 ? ' / ' + item.addr1 : ''}${item.mapx && item.mapy ? ` (lon:${item.mapx},lat:${item.mapy})` : ''}`
      ).join('\n')

      const systemContext = `참고자료(상위 ${top.length}개):\n${summary}\n위 자료를 참고하여 질문에 답변해 주세요. 출처: 한국관광공사 Tour API.`

      const messages = [
        { role: 'system', content: systemContext },
        ...history.value.filter(h => h.role !== 'system').map(h => ({ role: h.role, content: h.text }))
      ]

      history.value.push({ role: 'assistant', text: t('chat.generating') })

      await nextTick()
      scrollToBottom(true)

      try {
        const ai = await callOpenAI(messages)
        history.value[history.value.length - 1].text = ai
      } catch (e) {
        history.value[history.value.length - 1].text = `${t('chat.errorPrefix')}: ${e.message}`
      } finally {
        sending.value = false
        q.value = ''
        await nextTick()
        scrollToBottom(true)
      }
    }

    function clear() {
      history.value = [{ role: 'assistant', text: t('chat.greeting') }]
      nextTick().then(() => scrollToBottom(false))
    }

    function presetKey(n) {
      const key = `chat.preset${n}_text`
      const text = t(key)
      send(text)
    }

    return { q, history, send, clear, presetKey, historyRef, t }
  }
}
</script>

<style scoped>
.chat-wrapper {
  border: 1px solid var(--border);
  padding: 12px;
  width: 100%;
  background: var(--card);
  border-radius: 10px;
  box-shadow: var(--shadow);
  display: flex;
  flex-direction: column;
  height: auto;
}

/* 히스토리 영역 (스크롤) */
.history {
  overflow: auto;
  padding: 10px;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: color-mix(in srgb, var(--card) 94%, transparent);
  flex: 0 1 auto;
  min-height: 100px;
  max-height: calc(60vh);
}

/* 입력 영역 */
.input-row { margin-top: 10px; display:flex; gap:8px; align-items:center; }
.input-row input {
  flex:1;
  padding:10px;
  border-radius:8px;
  border:1px solid var(--border);
  background: var(--card);
  color: var(--text);
  box-shadow: none;
}

/* 빠른 버튼 영역 */
.quick { margin-top:10px; display:flex; gap:8px; flex-wrap:wrap; align-items:center; }
.reset-btn { margin-left:auto; }

/* 포커스 가시성 */
.input-row input:focus { outline: 3px solid rgba(37,99,235,0.12); outline-offset: 2px; }

/* 모바일 대응 */
@media (max-width: 560px) {
  .history { padding: 8px; max-height: 50vh; }
  .input-row { flex-direction: row; }
}
</style>