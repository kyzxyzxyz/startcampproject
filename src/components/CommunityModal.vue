<template>
  <BaseModal v-if="visible" @close="close">
    <div class="community-modal">
      <header class="cm-header">
        <div class="cm-title">
          <h3>{{ title }}</h3>
          <p v-if="subtitle" class="cm-sub">{{ subtitle }}</p>
        </div>
        <BaseButton variant="ghost" size="sm" @click="close" aria-label="닫기">✕</BaseButton>
      </header>

      <div class="cm-body">
        <section class="form-card">
          <h4 class="section-title">게시글 작성</h4>

          <form class="form" @submit.prevent="onCreate">
            <div class="form-row">
              <label class="form-label">선택 장소</label>
              <div class="form-control">
                <div v-if="initialTitle" class="poi-name">{{ initialTitle }}</div>
                <div v-else class="poi-name muted">선택된 장소 없음</div>
              </div>
            </div>

            <div class="form-row">
              <label class="form-label">카테고리</label>
              <div class="form-control">
                <select v-model="category">
                  <option value="">전체(선택)</option>
                  <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
                </select>
              </div>
            </div>

            <div class="form-row">
              <label class="form-label">제목</label>
              <div class="form-control">
                <input type="text" v-model="postTitle" required />
              </div>
            </div>

            <div class="form-row">
              <label class="form-label">본문</label>
              <div class="form-control">
                <textarea v-model="content" rows="8" required></textarea>
              </div>
            </div>

            <div class="form-row">
              <label class="form-label">비밀번호</label>
              <div class="form-control">
                <input v-model="password" type="password" required />
              </div>
            </div>

            <div class="form-actions">
              <BaseButton variant="primary" type="submit">작성</BaseButton>
            </div>
          </form>
        </section>

        <section class="list-card">
          <BoardList :category="initialCategory || null" :poiId="initialPoiId" :navigateOnClick="false" @open-post="openPost" />
        </section>
      </div>
    </div>
  </BaseModal>
</template>

<script>
import { ref, onMounted, nextTick } from 'vue'
import BaseModal from './BaseModal.vue'
import BaseButton from './BaseButton.vue'
import BoardList from './BoardList.vue'
import { addPost } from '../utils/storage'

export default {
  name: 'CommunityModal',
  components: { BaseModal, BaseButton, BoardList },
  setup(_, { expose }) {
    const visible = ref(false)
    const initialPoiId = ref(null)
    const initialTitle = ref('')
    const initialCategory = ref(null)
    const title = ref('게시글 작성')
    const subtitle = ref('')
    const category = ref('')
    const categories = ['관광지','레포츠','문화시설','쇼핑','숙박','여행코스','음식점','축제공연행사']

    const postTitle = ref('')
    const content = ref('')
    const password = ref('')

    function open(detail = {}) {
      initialPoiId.value = detail?.poiId || null
      initialTitle.value = detail?.poiTitle || ''
      initialCategory.value = detail?.poiCategory || detail?.category || null
      title.value = initialTitle.value ? `「${initialTitle.value}」 의견` : '게시글 작성'
      subtitle.value = initialCategory.value ? `${initialCategory.value}` : ''
      visible.value = true

      postTitle.value = initialTitle.value ? `[${initialTitle.value}] 후기 및 의견` : ''
      content.value = ''
      password.value = ''
      category.value = initialCategory.value || ''
      nextTick(() => {})
    }

    function close() {
      visible.value = false
    }

    function onCreate() {
      const post = {
        id: Date.now().toString(36) + Math.random().toString(36).slice(2,8),
        category: category.value || initialCategory.value || '기타',
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

    // <-- 중요: 템플릿에서 사용하므로 반드시 반환합니다
    return {
      visible,
      initialPoiId,
      initialTitle,
      initialCategory,
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