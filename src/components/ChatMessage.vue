<template>
  <div :class="['msg', role]">
    <div class="bubble">{{ text }}</div>
  </div>
</template>

<script>
export default {
  props: { role: String, text: String }
}
</script>

<style>
.msg { margin:8px 0; display:flex; }
.msg.user { justify-content:flex-end; }
.bubble { padding:8px 12px; border-radius:8px; background:#eef; max-width:70%; }
.msg.assistant .bubble { background:#f1f1f1; }
</style>
