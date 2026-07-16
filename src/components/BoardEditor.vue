<template>
  <div class="editor card">
    <h3>{{ $t('app.createPostTitle') }}</h3>
    <div v-if="prefillPoiTitle" class="poi-info">{{ $t('app.selectPlace') }}: <strong>{{ prefillPoiTitle }}</strong></div>
    <form @submit.prevent="submit" class="editor-form">
      <div class="field">
        <label class="label">{{ $t('app.categoryLabel') }}</label>
        <select v-model="category">
          <option value="">{{ $t('app.allSelectOption') }}</option>
          <option v-for="c in categories" :key="c.id" :value="c.id">{{ $t(c.labelKey) }}</option>
        </select>
      </div>

      <div class="field">
        <label class="label">{{ $t('app.titleLabel') }}</label>
        <input type="text" v-model="title" required />
      </div>

      <div class="field">
        <label class="label">{{ $t('app.contentLabel') }}</label>
        <textarea v-model="content" rows="6" required></textarea>
      </div>

      <div class="field password-row">
        <label class="label">{{ $t('app.passwordLabel') }}</label>
        <input v-model="password" type="password" required />
      </div>

      <div class="actions">
        <BaseButton type="submit" variant="primary">{{ $t('app.postButton') }}</BaseButton>
      </div>
    </form>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { addPost } from '../utils/storage'
import { v4 as uuidv4 } from 'uuid'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import BaseButton from './BaseButton.vue'

export default {
  components: { BaseButton },
  props: {
    initialTitle: { type: String, default: '' },
    initialPoiId: { type: String, default: '' },
    initialCategory: { type: String, default: null }
  },
  emits: ['created'],
  setup(props, { emit }) {
    const { t } = useI18n()
    const route = useRoute()
    const categories = [
      { id: '관광지', labelKey: 'categories.tourist' },
      { id: '레포츠', labelKey: 'categories.sports' },
      { id: '문화시설', labelKey: 'categories.culture' },
      { id: '쇼핑', labelKey: 'categories.shopping' },
      { id: '숙박', labelKey: 'categories.lodging' },
      { id: '여행코스', labelKey: 'categories.course' },
      { id: '음식점', labelKey: 'categories.food' },
      { id: '축제공연행사', labelKey: 'categories.festival' }
    ]
    const category = ref(props.initialCategory || '')
    const title = ref('')
    const content = ref('')
    const password = ref('')
    const prefillPoiTitle = ref('')
    const prefillPoiId = ref('')

    onMounted(() => {
      if (props.initialTitle) {
        prefillPoiTitle.value = props.initialTitle
        title.value = `[${prefillPoiTitle.value}] ${t('app.defaultPostTitleSuffix')}`
      } else if (route.query.poiTitle) {
        prefillPoiTitle.value = String(route.query.poiTitle)
        title.value = `[${prefillPoiTitle.value}] ${t('app.defaultPostTitleSuffix')}`
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
.editor { padding:16px; box-sizing:border-box; }
.editor h3 { margin:0 0 12px; font-size:18px; color:var(--text); }
.poi-info { margin-bottom:12px; color:var(--muted); }

.editor-form { display:flex; flex-direction:column; gap:12px; }

.field { display:flex; gap:12px; align-items:flex-start; }
.field .label { width:140px; flex:0 0 140px; font-weight:600; color:var(--muted); margin-top:6px; }

.field select,
.field input[type="text"],
.field input[type="password"],
.field textarea {
  flex:1;
  min-width:0;
  width:100%;
  padding:10px 12px;
  border-radius:8px;
  border:1px solid rgba(11,17,34,0.06);
  box-sizing:border-box;
  font-size:14px;
  background:var(--card);
  color:var(--text);
}

.field textarea { min-height:120px; resize:vertical; }
.password-row .label { align-self:flex-start; }
.actions { display:flex; justify-content:flex-end; margin-top:6px; }

@media (max-width:720px) {
  .field { flex-direction:column; align-items:stretch; }
  .field .label { width:auto; flex:0 0 auto; margin-bottom:6px; }
  .actions { justify-content:flex-end; }
}
</style>