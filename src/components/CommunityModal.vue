<template>
  <div>
    <div v-if="visible" class="cm-overlay" @click.self="close">
      <div class="cm-modal">
        <div class="cm-header">
          <h3>{{ title }}</h3>
          <button @click="close">✕</button>
        </div>

        <div class="cm-body">
          <!-- 선택된 게시글이 있으면 '상세 전용 모드'로 전환 -->
          <div v-if="selectedPost" class="post-detail-only">
            <div class="post-detail card" ref="detailEl">
              <div v-if="!editing">
                <h4>{{ selectedPost.title }}</h4>
                <div class="meta">작성: {{ formatDate(selectedPost.createdAt) }} · 카테고리: {{ selectedPost.category }}</div>
                <p class="content">{{ selectedPost.content }}</p>
                <div class="post-actions">
                  <button @click="startEdit">수정</button>
                  <button @click="beginDeleteFlow">삭제</button>
                  <button @click="closeDetail"> 이전으로 </button>
                </div>

                <div v-if="deleteFlowVisible" class="delete-inline">
                  <input v-model="deletePassword" type="password" placeholder="삭제 비밀번호" ref="deletePwdRef" />
                  <div class="error" v-if="deleteError">{{ deleteError }}</div>
                  <div style="margin-top:8px">
                    <button @click="doDelete">삭제 확인</button>
                    <button @click="cancelDeleteFlow">취소</button>
                  </div>
                </div>
                <div v-if="deleteSuccess" class="success">{{ deleteSuccess }}</div>
              </div>

              <div v-else class="edit-form">
                <label>제목</label>
                <input v-model="editTitle" />
                <label>본문</label>
                <textarea v-model="editContent"></textarea>
                <label>비밀번호</label>
                <input type="password" v-model="editPassword" placeholder="작성 시 입력한 비밀번호" ref="editPwdRef" />
                <div class="error" v-if="editError">{{ editError }}</div>
                <div style="margin-top:8px">
                  <button @click="doUpdate">저장</button>
                  <button @click="cancelEdit">취소</button>
                </div>
                <div v-if="editSuccess" class="success">{{ editSuccess }}</div>
              </div>

              <CommentSection v-if="selectedPost" :postId="selectedPost.id" />
            </div>
          </div>

          <!-- 선택된 게시글 없을 때: 작성폼 + 목록 (기본 모드) -->
          <div v-else>
            <BoardEditor :initialTitle="initialTitle" :initialPoiId="initialPoiId" :initialCategory="initialCategory" @created="onCreated" />
            <hr/>
            <BoardList :category="initialCategory || null" :poiId="initialPoiId" :navigateOnClick="false" @open-post="openPost" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import BoardList from './BoardList.vue'
import BoardEditor from './BoardEditor.vue'
import CommentSection from './CommentSection.vue'
import { loadPosts, updatePost, deletePost } from '../utils/storage'

export default {
  components: { BoardList, BoardEditor, CommentSection },
  setup() {
    const router = useRouter()

    const visible = ref(false)
    const initialPoiId = ref(null)
    const initialTitle = ref('')
    const initialCategory = ref(null)
    const title = ref('커뮤니티')

    const selectedPost = ref(null)
    const editing = ref(false)
    const editTitle = ref('')
    const editContent = ref('')
    const editPassword = ref('')

    const detailEl = ref(null)

    // deletion inline flow
    const deleteFlowVisible = ref(false)
    const deletePassword = ref('')
    const deleteError = ref('')
    const deleteSuccess = ref('')

    // edit inline messages
    const editError = ref('')
    const editSuccess = ref('')

    function open(detail) {
      initialPoiId.value = detail?.poiId || null
      initialTitle.value = detail?.poiTitle || ''
      initialCategory.value = detail?.poiCategory || detail?.category || null
      title.value = initialTitle.value ? `「${initialTitle.value}」 의견` : (initialCategory.value ? `${initialCategory.value} 의견` : '커뮤니티')
      visible.value = true
      selectedPost.value = null
      editing.value = false
      deleteFlowVisible.value = false
      deletePassword.value = ''
      deleteError.value = ''
      deleteSuccess.value = ''
      editError.value = ''
      editSuccess.value = ''
    }
    function close(){ visible.value = false; selectedPost.value = null; editing.value = false; deleteFlowVisible.value = false }

    function onCreated(){
      // 새 글 작성 후: 모달 닫고 커뮤니티 목록으로 이동, 목록 갱신 이벤트 발행
      visible.value = false
      try { router.push('/community') } catch(e){}
      try { window.dispatchEvent(new Event('ggb-posts-changed')) } catch(e){}
    }

    onMounted(() => {
      window.addEventListener('open-community', (e) => {
        open(e.detail || {})
      })
      window.addEventListener('open-post', (ev) => {
        try {
          const post = ev?.detail
          if (post) openPost(post)
        } catch(e){}
      })
    })

    function openPost(post) {
      const all = loadPosts()
      const p = all.find(x => x.id === post.id)
      selectedPost.value = p || post
      editing.value = false
      editPassword.value = ''
      deleteFlowVisible.value = false
      deletePassword.value = ''
      deleteError.value = ''
      deleteSuccess.value = ''
      editError.value = ''
      editSuccess.value = ''
      nextTick(() => {
        const el = detailEl.value
        if (el && el.scrollIntoView) {
          el.scrollIntoView({ behavior: 'smooth', block: 'start' })
        } else {
          const modal = document.querySelector('.cm-modal')
          if (modal) modal.scrollTop = 0
        }
      })
    }

    function closeDetail() {
      selectedPost.value = null
      editing.value = false
    }

    function startEdit() {
      if (!selectedPost.value) return
      editTitle.value = selectedPost.value.title
      editContent.value = selectedPost.value.content
      editPassword.value = ''
      editing.value = true
      editError.value = ''
      editSuccess.value = ''
      nextTick(() => {
        const el = document.querySelector('.edit-form input')
        if (el) el.focus()
      })
    }

    async function doUpdate() {
      editError.value = ''
      editSuccess.value = ''
      try {
        await updatePost(selectedPost.value.id, { title: editTitle.value, content: editContent.value }, editPassword.value)
        const all = loadPosts()
        selectedPost.value = all.find(x=>x.id===selectedPost.value.id) || null
        editing.value = false
        editSuccess.value = '수정되었습니다.'
        try { window.dispatchEvent(new Event('ggb-posts-changed')) } catch(e){}
      } catch (e) {
        editError.value = e.message || '수정 실패'
        await nextTick()
        const el = document.querySelector('.edit-form input[type="password"]')
        if (el) el.focus()
      }
    }

    function beginDeleteFlow() {
      deleteFlowVisible.value = true
      deletePassword.value = ''
      deleteError.value = ''
      deleteSuccess.value = ''
      nextTick(() => {
        const el = document.querySelector('.delete-inline input[type="password"]')
        if (el) el.focus()
      })
    }
    function cancelDeleteFlow() {
      deleteFlowVisible.value = false
      deletePassword.value = ''
      deleteError.value = ''
    }

    async function doDelete() {
      deleteError.value = ''
      deleteSuccess.value = ''
      if (!deletePassword.value) {
        deleteError.value = '비밀번호를 입력하세요.'
        await nextTick()
        const el = document.querySelector('.delete-inline input[type="password"]')
        if (el) el.focus()
        return
      }
      try {
        deletePost(selectedPost.value.id, deletePassword.value)
        deleteSuccess.value = '삭제되었습니다.'
        try { window.dispatchEvent(new Event('ggb-posts-changed')) } catch(e){}
        setTimeout(() => {
          selectedPost.value = null
          deleteFlowVisible.value = false
        }, 500)
      } catch (e) {
        deleteError.value = e.message || '삭제 실패'
        await nextTick()
        const el = document.querySelector('.delete-inline input[type="password"]')
        if (el) el.focus()
      }
    }

    function cancelEdit() {
      editing.value = false
    }

    function formatDate(s) {
      return s ? new Date(s).toLocaleString() : ''
    }

    return {
      visible, initialPoiId, initialTitle, initialCategory, title,
      selectedPost, openPost, close, onCreated, startEdit, doUpdate, beginDeleteFlow, doDelete, editing,
      editTitle, editContent, editPassword, cancelEdit, closeDetail, formatDate, detailEl,
      deleteFlowVisible, deletePassword, deleteError, deleteSuccess,
      editError, editSuccess
    }
  }
}
</script>

<style scoped>
.cm-overlay{position:fixed;inset:0;background:rgba(2,6,23,0.5);display:flex;align-items:center;justify-content:center;z-index:99999}
.cm-modal{width:min(900px,96%);background:white;border-radius:10px;overflow:auto;max-height:85vh;padding:12px}
.cm-header{display:flex;justify-content:space-between;align-items:center;padding:4px 8px;border-bottom:1px solid #eee}
.cm-body{padding:12px}
.post-detail-only .post-detail { margin-bottom:12px; }
.post-detail h4 { margin:0 0 6px; }
.post-detail .meta { color:#64748b; font-size:12px; margin-bottom:8px; }
.post-detail .content { white-space:pre-wrap; color:#0b1220; margin-bottom:8px; }
.post-actions { display:flex; gap:8px; }
.edit-form input, .edit-form textarea { width:100%; box-sizing:border-box; margin-bottom:8px; }
.delete-inline { margin-top:8px; display:flex; gap:8px; align-items:center; }
.delete-inline input { padding:8px; border-radius:6px; border:1px solid rgba(11,17,34,0.06); flex:1; }
.error { color:#ef4444; margin-top:6px; }
.success { color:#059669; margin-top:6px; }
</style>