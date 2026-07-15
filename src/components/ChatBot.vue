<template>
  <div class="chat-wrapper">
    <div class="history" ref="historyRef">
      <ChatMessage v-for="(m, i) in history" :key="i" :role="m.role" :text="m.text" />
    </div>

    <div class="input-row">
      <input v-model="q" @keydown.enter="send" :placeholder="t('chat.placeholder')" />
      <button class="btn primary" @click="send">{{ t('chat.send') }}</button>
    </div>

    <div class="quick">
      <button class="btn primary" @click="presetKey(1)">{{ t('chat.preset1') }}</button>
      <button class="btn primary" @click="presetKey(2)">{{ t('chat.preset2') }}</button>
      <button class="btn primary" @click="presetKey(3)">{{ t('chat.preset3') }}</button>
      <button class="btn reset" @click="clear">{{ t('chat.clear') }}</button>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, nextTick } from 'vue'
import ChatMessage from './ChatMessage.vue'
import { loadAllData, simpleRank } from '../utils/dataSearch'
import { callOpenAI } from '../utils/openai'
import { useI18n } from 'vue-i18n'

export default {
  components: { ChatMessage },
  setup() {
    const { t } = useI18n()
    const q = ref('')
    const history = ref([{ role: 'assistant', text: t('chat.greeting') }])
    const dataCache = ref([])
    const historyRef = ref(null)

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

    async function send() {
      if (!q.value.trim()) return
      const userText = q.value.trim()
      history.value.push({ role: 'user', text: userText })

      const top = simpleRank(userText, dataCache.value, 5)
      const summary = top.map(item =>
        `- ${item.title || ''}${item.addr1 ? ' / ' + item.addr1 : ''}${item.mapx && item.mapy ? ` (lon:${item.mapx},lat:${item.mapy})` : ''}`
      ).join('\n')

      const systemContext = `참고자료(상위 ${top.length}개):\n${summary}\n위 자료를 참고하여 질문에 답변해 주세요. 출처: 한국관광공사 Tour API.`

      const messages = [
        { role: 'system', content: systemContext },
        ...history.value.filter(h => h.role !== 'system').map(h => ({ role: h.role, content: h.text })),
        { role: 'user', content: userText }
      ]

      history.value.push({ role: 'assistant', text: t('chat.generating') })

      await nextTick()
      scrollToBottom(true)

      try {
        const ai = await callOpenAI(messages)
        history.value[history.value.length - 1].text = ai
      } catch (e) {
        history.value[history.value.length - 1].text = `${t('chat.errorPrefix')}: ${e.message}`
      }

      await nextTick()
      scrollToBottom(true)
      q.value = ''
    }

    function clear() {
      history.value = [{ role: 'assistant', text: t('chat.greeting') }]
      nextTick().then(() => scrollToBottom(false))
    }

    function presetKey(n) {
      // preset text keys: chat.preset1_text, chat.preset2_text, chat.preset3_text
      const key = `chat.preset${n}_text`
      const text = t(key)
      q.value = text
      send()
    }

    return { q, history, send, clear, presetKey, historyRef, t }
  }
}
</script>

<style>
.chat-wrapper { border:1px solid rgba(11,17,34,0.06); padding:12px; width:100%; background:#fff; border-radius:10px; box-shadow:var(--shadow); display:flex; flex-direction:column; height:100%; }
.history { overflow:auto; padding:8px; border:1px solid #eee; border-radius:6px; background:#fafafa; flex:1 1 auto; min-height:400px; }
.input-row { margin-top:8px; display:flex; gap:8px; align-items:center; }
.input-row input { flex:1; padding:10px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); }
.input-row .btn { padding:10px 14px; }
.quick { margin-top:8px; display:flex; gap:8px; flex-wrap:wrap; align-items:center; }
.quick .btn { white-space:nowrap; padding:8px 12px; border-radius:8px; font-weight:600; }
.quick .btn.reset { margin-left:auto; }
</style>