<template>
  <div>
    <h2>{{ t('detail.title') }}</h2>
    <div v-if="post">
      <h3>{{ post.title }}</h3>
      <div class="post-content">{{ post.content }}</div>
      <small>{{ t('board.createdAt', { date: format(post.createdAt) }) }}</small>
      <div style="margin-top:8px; display:flex; gap:8px; align-items:center;">
        <button class="btn primary" @click="startEdit">{{ t('app.edit') }}</button>
        <button class="btn primary" @click="askDelete">{{ t('app.delete') }}</button>
        <button class="btn primary" @click="goBack">{{ t('app.backToList') }}</button>
      </div>

      <div v-if="deleteMode" class="delete-inline" style="margin-top:12px;">
        <input v-model="delPassword" type="password" :placeholder="t('app.passwordPlaceholder')" ref="delPwdRef" />
        <div class="actions" style="display:flex; gap:8px; margin-left:8px; align-items:center;">
          <button class="btn primary" @click="doDelete">{{ t('app.delete') }}</button>
          <button class="btn ghost" @click="cancelDelete">{{ t('app.close') }}</button>
        </div>
        <div class="error" v-if="deleteError">{{ deleteError }}</div>
        <div class="success" v-if="deleteSuccess">{{ deleteSuccess }}</div>
      </div>
    </div>
    <div v-else>
      <p>{{ t('board.noPosts') }}</p>
    </div>

    <div v-if="editing" style="margin-top:12px;">
      <h4>{{ t('detail.editTitle') }}</h4>
      <input v-model="editTitle" />
      <textarea v-model="editContent"></textarea>
      <input v-model="editPassword" type="password" :placeholder="t('app.passwordPlaceholder')" ref="editPwdRef" />
      <div class="error" v-if="editError">{{ editError }}</div>
      <div class="success" v-if="editSuccess">{{ editSuccess }}</div>
      <div style="display:flex; gap:8px; margin-top:8px;">
        <button class="btn primary" @click="doUpdate">{{ t('app.saved') }}</button>
        <button class="btn ghost" @click="cancelEdit">{{ t('app.close') }}</button>
      </div>
    </div>

    <CommentSection v-if="post" :postId="post.id" />
  </div>
</template>

<script>
import { ref, onMounted, nextTick } from 'vue'
import { loadPosts, updatePost, deletePost } from '../utils/storage'
import { useRouter, useRoute } from 'vue-router'
import CommentSection from '../components/CommentSection.vue'
import { useI18n } from 'vue-i18n'

export default {
  components: { CommentSection },
  setup() {
    const { t, locale } = useI18n()
    const router = useRouter()
    const route = useRoute()
    const id = route.params.id
    const post = ref(null)
    const editing = ref(false)
    const deleteMode = ref(false)
    const editTitle = ref('')
    const editContent = ref('')
    const editPassword = ref('')
    const delPassword = ref('')

    const editError = ref('')
    const editSuccess = ref('')
    const deleteError = ref('')
    const deleteSuccess = ref('')

    function load() {
      const p = loadPosts().find(x => x.id === id)
      post.value = p || null
    }
    function format(tVal){
      if (!tVal) return ''
      try {
        const d = new Date(tVal)
        // use i18n locale for formatting
        const loc = (locale && locale.value) ? locale.value : undefined
        return d.toLocaleString(loc)
      } catch(e) { return String(tVal) }
    }

    function startEdit(){
      editing.value = true
      editTitle.value = post.value.title
      editContent.value = post.value.content
      editError.value = ''
      editSuccess.value = ''
      editPassword.value = ''
      nextTick(() => { const el = document.querySelector('input[ref="editPwdRef"]'); if(el) el.focus() })
    }
    function cancelEdit(){ editing.value=false; editPassword.value=''; editError.value=''; editSuccess.value='' }

    async function doUpdate() {
      editError.value = ''
      editSuccess.value = ''
      if (!editPassword.value) { editError.value = t('app.confirmDeletePrompt') || '비밀번호를 입력하세요.'; await nextTick(); const el = document.querySelector('input[ref="editPwdRef"]'); if (el) el.focus(); return }
      try {
        updatePost(id, { title: editTitle.value, content: editContent.value }, editPassword.value)
        editSuccess.value = t('app.saved')
        editing.value = false
        load()
        try { window.dispatchEvent(new Event('ggb-posts-changed')) } catch(e){}
      } catch (e) {
        editError.value = e.message || t('app.editFail') || '수정 실패'
        await nextTick()
        const el = document.querySelector('input[ref="editPwdRef"]')
        if (el) el.focus()
      }
    }

    function askDelete(){ deleteMode.value = true; deleteError.value = ''; deleteSuccess.value = ''; delPassword.value = ''; nextTick(()=>{ const el=document.querySelector('input[ref=\"delPwdRef\"]'); if(el) el.focus() }) }

    function cancelDelete(){ deleteMode.value = false; delPassword.value=''; deleteError.value=''; deleteSuccess.value='' }

    function doDelete(){
      deleteError.value = ''
      deleteSuccess.value = ''
      if (!delPassword.value) { deleteError.value = t('app.confirmDeletePrompt') || '비밀번호를 입력하세요.'; nextTick(()=>{ const el=document.querySelector('input[ref=\"delPwdRef\"]'); if(el) el.focus() }); return }
      try {
        deletePost(id, delPassword.value)
        deleteSuccess.value = t('app.deleted')
        try { window.dispatchEvent(new Event('ggb-posts-changed')) } catch(e){}
        setTimeout(()=> router.push('/board'), 400)
      } catch(e){
        deleteError.value = e.message || t('app.deleteFail') || '삭제 실패'
        setTimeout(()=>{ const el = document.querySelector('input[ref=\"delPwdRef\"]'); if(el) el.focus() }, 0)
      }
    }

    function goBack() {
      router.push('/community')
    }

    onMounted(load)
    return { t, post, editing, deleteMode, editTitle, editContent, editPassword, delPassword, startEdit, cancelEdit, doUpdate, askDelete, doDelete, format, goBack, editError, editSuccess, deleteError, deleteSuccess, cancelDelete }
  }
}
</script>

<style scoped>
.post-content { white-space:pre-wrap; margin:8px 0 12px 0; color:#0b1220; }
.delete-inline { margin-top:8px; display:flex; gap:8px; align-items:center; }
.delete-inline input { padding:8px; border-radius:6px; border:1px solid rgba(11,17,34,0.06); flex:1; }
.error { color:#ef4444; margin-top:6px; }
.success { color:#059669; margin-top:6px; }

/* 버튼 여백 보정 (버튼 클래스는 전역 스타일 .btn 사용) */
.btn { padding:10px 14px; border-radius:10px; font-weight:600; }
.btn.primary { background:#2563eb; color:#fff; border:none; box-shadow:0 8px 24px rgba(15,99,254,0.12); }
.btn.ghost { background:transparent; border:1px solid rgba(11,17,34,0.06); color:#2563eb; }
</style>