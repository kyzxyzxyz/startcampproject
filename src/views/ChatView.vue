<template>
  <div>
    <h2>지역 챗봇</h2>
    <p>OpenAI API 키는 .env 또는 Netlify 환경변수 VITE_OPENAI_API_KEY 에 설정해야 합니다. (주의: 프론트에 노출됩니다.)</p>
    <ChatBot />
  </div>
</template>

<script>
import ChatBot from '../components/ChatBot.vue'
export default { components: { ChatBot } }
</script>
