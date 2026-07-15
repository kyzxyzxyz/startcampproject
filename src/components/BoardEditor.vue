<template>
  <div class="editor card">
    <h3>게시글 작성</h3>
    <div v-if="prefillPoiTitle" class="poi-info">선택 장소: <strong>{{ prefillPoiTitle }}</strong></div>
    <form @submit.prevent="submit" class="editor-form">
      <div class="field">
        <label class="label">카테고리</label>
        <select v-model="category">
          <option value="">전체(선택)</option>
          <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
        </select>
      </div>

      <div class="field">
        <label class="label">제목</label>
        <input type="text" v-model="title" required />
      </div>

      <div class="field">
        <label class="label">본문</label>
        <textarea v-model="content" rows="6" required></textarea>
      </div>

      <div class="field password-row">
        <label class="label">비밀번호</label>
        <input v-model="password" type="password" required />
      </div>

      <div class="actions">
        <button type="submit" class="btn primary">작성</button>
      </div>
    </form>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { addPost } from '../utils/storage'
import { v4 as uuidv4 } from 'uuid'
import { useRoute } from 'vue-router'

export default {
  props: {
    initialTitle: { type: String, default: '' },
    initialPoiId: { type: String, default: '' },
    initialCategory: { type: String, default: null }
  },
  emits: ['created'],
  setup(props, { emit }) {
    const route = useRoute()
    const categories = ['관광지','레포츠','문화시설','쇼핑','숙박','여행코스','음식점','축제공연행사']
    const category = ref(props.initialCategory || '')
    const title = ref('')
    const content = ref('')
    const password = ref('')
    const prefillPoiTitle = ref('')
    const prefillPoiId = ref('')

    onMounted(() => {
      if (props.initialTitle) {
        prefillPoiTitle.value = props.initialTitle
        title.value = `[${prefillPoiTitle.value}] 후기 및 의견`
      } else if (route.query.poiTitle) {
        prefillPoiTitle.value = String(route.query.poiTitle)
        title.value = `[${prefillPoiTitle.value}] 후기 및 의견`
      }
      prefillPoiId.value = props.initialPoiId || (route.query.poiId ? String(route.query.poiId) : '')
      if (!category.value && route.query.category) category.value = String(route.query.category)
    })

    function submit() {
      const post = {
        id: uuidv4(),
        category: category.value || '기타',
        title: title.value,
        content: content.value,
        password: password.value,
        poiId: prefillPoiId.value || null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }
      addPost(post)
      title.value = content.value = password.value = ''
      emit('created')
    }

    return { categories, category, title, content, password, prefillPoiTitle, submit }
  }
}
</script>

<style scoped>
.editor { padding:16px; }
.field select { width:100%; padding:10px 12px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); box-sizing:border-box; }
</style>