<template>
  <div class="chat-wrapper">
    <div class="header"><strong>지역 챗봇</strong></div>

    <div class="history" ref="historyRef">
      <ChatMessage v-for="(m, i) in history" :key="i" :role="m.role" :text="m.text" />
    </div>

    <div class="input-row">
      <input v-model="q" @keydown.enter="send" placeholder="질문을 입력하세요. (예: 금오산 근처 추천 관광지)" />
    </div>

    <div class="quick">
      <button class="btn primary" @click="send">전송</button>
      <button class="btn primary" @click="preset('금오산 근처 추천 관광지 3곳 알려줘')">관광지 추천</button>
      <button class="btn primary" @click="preset('이번 달 구미 축제 일정 알려줘')">축제 일정</button>
      <button class="btn primary" @click="preset('모범음식점 추천해줘')">음식점 위치</button>
      <button class="btn reset" @click="clear">초기화</button>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, nextTick } from 'vue'
import ChatMessage from './ChatMessage.vue'
import { loadAllData, simpleRank } from '../utils/dataSearch'
import { callOpenAI } from '../utils/openai'

export default {
  components: { ChatMessage },
  setup() {
    const q = ref('')
    const history = ref([{ role: 'assistant', text: '안녕하세요 무엇을 도와드릴까요?' }])
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
      const summary = top.map(t =>
        `- ${t.title || ''}${t.addr1 ? ' / ' + t.addr1 : ''}${t.mapx && t.mapy ? ` (lon:${t.mapx},lat:${t.mapy})` : ''}`
      ).join('\n')

      const systemContext = `참고자료(상위 ${top.length}개):\n${summary}\n위 자료를 참고하여 질문에 답변해 주세요. 출처: 한국관광공사 Tour API.`

      const messages = [
        { role: 'system', content: systemContext },
        ...history.value.filter(h => h.role !== 'system').map(h => ({ role: h.role, content: h.text })),
        { role: 'user', content: userText }
      ]

      history.value.push({ role: 'assistant', text: '응답을 생성 중입니다...' })

      await nextTick()
      scrollToBottom(true)

      try {
        const ai = await callOpenAI(messages)
        history.value[history.value.length - 1].text = ai
      } catch (e) {
        history.value[history.value.length - 1].text = `오류: ${e.message}`
      }

      await nextTick()
      scrollToBottom(true)
      q.value = ''
    }

    function clear() {
      history.value = [{ role: 'assistant', text: '안녕하세요 무엇을 도와드릴까요?' }]
      nextTick().then(() => scrollToBottom(false))
    }

    function preset(t) { q.value = t; send() }

    return { q, history, send, clear, preset, historyRef }
  }
}
</script>

<style>
.chat-wrapper { border:1px solid rgba(11,17,34,0.06); padding:12px; width:100%; background:#fff; border-radius:10px; box-shadow:var(--shadow); display:flex; flex-direction:column; height:100%; }
.header { margin-bottom:8px; }
.history { overflow:auto; padding:8px; border:1px solid #eee; border-radius:6px; background:#fafafa; flex:1 1 auto; min-height:400px; }
.input-row { margin-top:8px; display:flex; gap:8px; }
.input-row input { flex:1; padding:10px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); }
.quick { margin-top:8px; display:flex; gap:8px; flex-wrap:wrap; align-items:center; }
.quick .btn { white-space:nowrap; padding:8px 12px; border-radius:8px; font-weight:600; }
.quick .btn.reset { margin-left:auto; }
</style>