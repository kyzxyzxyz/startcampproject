<template>
  <BaseModal v-if="visible" @close="close">
    <div class="community-modal">
      <header class="cm-header">
        <div class="cm-title">
          <h3>{{ title }}</h3>
          <p v-if="subtitle" class="cm-sub">{{ subtitle }}</p>
        </div>
        <BaseButton variant="ghost" size="sm" @click="close" :aria-label="$t('app.close')">✕</BaseButton>
      </header>

      <div class="cm-body">
        <section class="form-card">
          <h4 class="section-title">{{ $t('app.createPostTitle') }}</h4>

          <form class="form" @submit.prevent="onCreate">
            <div class="form-row">
              <label class="form-label">{{ $t('app.selectPlace') }}</label>
              <div class="form-control">
                <div v-if="initialTitle" class="poi-name">{{ initialTitle }}</div>
                <div v-else class="poi-name muted">{{ $t('app.noPlaceSelected') }}</div>
              </div>
            </div>

            <div class="form-row">
              <label class="form-label">{{ $t('app.categoryLabel') }}</label>
              <div class="form-control">
                <select v-model="category">
                  <option value="">{{ $t('app.allSelectOption') }}</option>
                  <option v-for="c in categories" :key="c.key" :value="c.key">{{ $t(c.labelKey) }}</option>
                </select>
              </div>
            </div>

            <div class="form-row">
              <label class="form-label">{{ $t('app.titleLabel') }}</label>
              <div class="form-control">
                <input type="text" v-model="postTitle" required />
              </div>
            </div>

            <div class="form-row">
              <label class="form-label">{{ $t('app.contentLabel') }}</label>
              <div class="form-control">
                <textarea v-model="content" rows="8" required></textarea>
              </div>
            </div>

            <div class="form-row">
              <label class="form-label">{{ $t('app.passwordLabel') }}</label>
              <div class="form-control">
                <input v-model="password" type="password" required />
              </div>
            </div>

            <div class="form-actions">
              <BaseButton variant="primary" type="submit">{{ $t('app.postButton') }}</BaseButton>
            </div>
          </form>
        </section>

        <section class="list-card">
          <BoardList :category="initialCategoryForList" :poiId="initialPoiId" :navigateOnClick="false" @open-post="openPost" />
        </section>
      </div>
    </div>
  </BaseModal>
</template>

<script>
import { ref, onMounted, nextTick } from 'vue'
import { useI18n } from 'vue-i18n'
import BaseModal from './BaseModal.vue'
import BaseButton from './BaseButton.vue'
import BoardList from './BoardList.vue'
import { addPost } from '../utils/storage'

export default {
  name: 'CommunityModal',
  components: { BaseModal, BaseButton, BoardList },
  setup(_, { expose }) {
    const { t } = useI18n()

    const visible = ref(false)
    const initialPoiId = ref(null)
    const initialTitle = ref('')
    const initialCategory = ref(null) // raw incoming (may be localized or key)
    const initialCategoryForList = ref(null) // normalized key or null for BoardList prop
    const title = ref(t('app.createPostTitle'))
    const subtitle = ref('')
    const category = ref('')
    const categories = [
      { key: 'tourist', labelKey: 'categories.tourist' },
      { key: 'sports', labelKey: 'categories.sports' },
      { key: 'culture', labelKey: 'categories.culture' },
      { key: 'shopping', labelKey: 'categories.shopping' },
      { key: 'lodging', labelKey: 'categories.lodging' },
      { key: 'course', labelKey: 'categories.course' },
      { key: 'food', labelKey: 'categories.food' },
      { key: 'festival', labelKey: 'categories.festival' }
    ]

    const postTitle = ref('')
    const content = ref('')
    const password = ref('')

    function findCategoryByLabelOrKey(val) {
      if (!val) return null
      const byKey = categories.find(c => c.key === val)
      if (byKey) return byKey
      const byLabel = categories.find(c => t(c.labelKey) === val)
      if (byLabel) return byLabel
      return null
    }

    function open(detail = {}) {
      initialPoiId.value = detail?.poiId || null
      initialTitle.value = detail?.poiTitle || ''
      initialCategory.value = detail?.poiCategory || detail?.category || null

      const matched = findCategoryByLabelOrKey(initialCategory.value)
      initialCategoryForList.value = matched ? matched.key : (initialCategory.value || null)

      title.value = initialTitle.value ? `「${initialTitle.value}」 ${t('app.postForSuffix')}` : t('app.createPostTitle')
      subtitle.value = matched ? t(matched.labelKey) : (initialCategory.value || '')
      visible.value = true

      postTitle.value = initialTitle.value ? `[${initialTitle.value}] ${t('app.defaultPostTitleSuffix')}` : ''
      content.value = ''
      password.value = ''
      category.value = matched ? matched.key : (initialCategory.value || '')
      nextTick(() => {})
    }

    function close() {
      visible.value = false
    }

    function onCreate() {
      const post = {
        id: Date.now().toString(36) + Math.random().toString(36).slice(2,8),
        category: category.value || initialCategoryForList.value || 'etc',
        title: postTitle.value || '',
        content: content.value || '',
        password: password.value || '',
        poiId: initialPoiId.value || null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }
      addPost(post)
      visible.value = false
      try { window.dispatchEvent(new Event('ggb-posts-changed')) } catch(e){}
    }

    function openPost(post) {
      try { window.dispatchEvent(new CustomEvent('open-post', { detail: post })) } catch(e){}
    }

    onMounted(() => {
      window.addEventListener('open-community', (e) => {
        open(e.detail || {})
      })
    })

    expose({ open, close })

    return {
      visible,
      initialPoiId,
      initialTitle,
      initialCategory,
      initialCategoryForList,
      title,
      subtitle,
      postTitle,
      content,
      password,
      onCreate,
      categories,
      category,
      open,
      close,
      openPost
    }
  }
}
</script>

<style scoped>
/* (스타일은 이전과 동일) */
.community-modal { width:100%; box-sizing:border-box; padding:0; }
.cm-header{
  display:flex; align-items:center; justify-content:space-between;
  padding:16px 20px; border-bottom:1px solid rgba(11,17,34,0.06);
}
.cm-title h3{ margin:0; font-size:18px; color:var(--text); }
.cm-sub{ margin:6px 0 0 0; font-size:13px; color:var(--muted); }
.cm-body{ padding:18px 20px 28px 20px; display:flex; flex-direction:column; gap:18px; }
.form-card,.list-card{ background:var(--card); border-radius:10px; padding:18px; border:1px solid rgba(11,17,34,0.04); box-shadow:var(--shadow); }
.form{ display:flex; flex-direction:column; gap:14px; }
.section-title{ margin:0 0 8px 0; font-size:16px; }
.form-row{ display:flex; gap:12px; align-items:flex-start; }
.form-label{ width:120px; font-weight:600; color:var(--muted); margin-top:6px; }
.form-control{ flex:1; }
.form-control input,.form-control select,.form-control textarea{ width:100%; padding:12px 14px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); box-sizing:border-box; background:white; font-size:14px; }
.form-control textarea{ min-height:160px; resize:vertical; }
.form-actions{ display:flex; justify-content:flex-end; margin-top:6px; }
.muted{ color:var(--muted); }
@media (max-width:720px){ .form-row{ flex-direction:column } .form-label{ width:auto; margin-bottom:6px } .form-control textarea{ min-height:140px } }
</style>