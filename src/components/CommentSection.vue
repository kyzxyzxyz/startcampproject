<template>
  <div class="comment-section">
    <h4 class="cs-title">{{ t('comment.title', { count: comments.length }) }}</h4>

    <div class="new-comment card">
      <input v-model="author" :placeholder="t('comment.authorPlaceholder')" />
      <input v-model="newPassword" ref="newPasswordRef" type="password" :placeholder="t('app.passwordPlaceholder')" />
      <textarea v-model="content" :placeholder="t('comment.contentPlaceholder')" rows="3"></textarea>
      <div class="error" v-if="newError">{{ newError }}</div>
      <div class="actions">
        <BaseButton variant="primary" @click="submit">{{ t('comment.submit') }}</BaseButton>
      </div>
    </div>

    <ul class="comment-list">
      <li v-for="c in rootComments" :key="c.id" class="comment-item card">
        <div class="comment-body">
          <div class="meta">
            <div>
              <strong class="author">{{ c.author }}</strong>
              <span class="time"> · {{ formatDate(c.createdAt) }}</span>
            </div>

            <div class="item-actions">
              <BaseButton variant="ghost" size="sm" class="link" @click="toggleReply(c.id)">{{ t('comment.reply') }}</BaseButton>
              <BaseButton variant="ghost" size="sm" class="link" @click="startEdit(c)">{{ editingId === c.id ? t('comment.editing') : t('comment.edit') }}</BaseButton>
              <BaseButton variant="ghost" size="sm" class="link" @click="startDelete(c)">{{ deletingId === c.id ? t('comment.confirm') : t('comment.delete') }}</BaseButton>
            </div>
          </div>

          <div v-if="editingId !== c.id" class="content">{{ c.content }}</div>

          <div v-else class="edit-area">
            <textarea v-model="editContent" rows="3"></textarea>
            <input
              v-model="editPasswords[c.id]"
              type="password"
              :placeholder="t('app.passwordPlaceholder')"
              :ref="el => setEditRef(c.id, el)"
            />
            <div class="actions">
              <BaseButton variant="primary" @click="confirmEdit(c.id)">{{ t('comment.save') }}</BaseButton>
              <BaseButton variant="ghost" @click="cancelEdit">{{ t('app.close') }}</BaseButton>
            </div>
            <div class="error" v-if="editErrors[c.id]">{{ editErrors[c.id] }}</div>
          </div>

          <div v-if="deletingId === c.id" class="delete-area">
            <input
              v-model="deletePasswords[c.id]"
              type="password"
              :placeholder="t('app.passwordPlaceholder')"
              :ref="el => setDeleteRef(c.id, el)"
            />
            <div class="actions">
              <BaseButton variant="neutral" class="danger" @click="confirmDelete(c.id)">{{ t('comment.deleteConfirm') }}</BaseButton>
              <BaseButton variant="ghost" @click="cancelDelete">{{ t('app.close') }}</BaseButton>
            </div>
            <div class="error" v-if="deleteErrors[c.id]">{{ deleteErrors[c.id] }}</div>
          </div>
        </div>

        <!-- reply form -->
        <div v-if="replyingTo === c.id" class="reply-form">
          <input v-model="replyAuthor" :placeholder="t('comment.authorPlaceholder')" />
          <input
            v-model="replyPasswords[c.id]"
            type="password"
            :placeholder="t('app.passwordPlaceholder')"
            :ref="el => setReplyRef(c.id, el)"
          />
          <textarea v-model="replyContent" :placeholder="t('comment.replyPlaceholder')" rows="2"></textarea>
          <div class="actions">
            <BaseButton variant="primary" @click="submitReply(c.id)">{{ t('comment.replySubmit') }}</BaseButton>
            <BaseButton variant="ghost" @click="toggleReply(null)">{{ t('app.close') }}</BaseButton>
          </div>
          <div class="error" v-if="replyErrors[c.id]">{{ replyErrors[c.id] }}</div>
        </div>

        <!-- replies -->
        <ul class="replies">
          <li v-for="r in childMap[c.id] || []" :key="r.id" class="comment-reply">
            <div class="meta">
              <div>
                <strong class="author">{{ r.author }}</strong>
                <span class="time"> · {{ formatDate(r.createdAt) }}</span>
              </div>
              <div class="item-actions">
                <BaseButton variant="ghost" size="sm" class="link" @click="startEdit(r)">{{ editingId === r.id ? t('comment.editing') : t('comment.edit') }}</BaseButton>
                <BaseButton variant="ghost" size="sm" class="link" @click="startDelete(r)">{{ deletingId === r.id ? t('comment.confirm') : t('comment.delete') }}</BaseButton>
              </div>
            </div>

            <div v-if="editingId !== r.id" class="content">{{ r.content }}</div>

            <div v-else class="edit-area">
              <textarea v-model="editContent" rows="3"></textarea>
              <input
                v-model="editPasswords[r.id]"
                type="password"
                :placeholder="t('app.passwordPlaceholder')"
                :ref="el => setEditRef(r.id, el)"
              />
              <div class="actions">
                <BaseButton variant="primary" @click="confirmEdit(r.id)">{{ t('comment.save') }}</BaseButton>
                <BaseButton variant="ghost" @click="cancelEdit">{{ t('app.close') }}</BaseButton>
              </div>
              <div class="error" v-if="editErrors[r.id]">{{ editErrors[r.id] }}</div>
            </div>

            <div v-if="deletingId === r.id" class="delete-area">
              <input
                v-model="deletePasswords[r.id]"
                type="password"
                :placeholder="t('app.passwordPlaceholder')"
                :ref="el => setDeleteRef(r.id, el)"
              />
              <div class="actions">
                <BaseButton variant="neutral" class="danger" @click="confirmDelete(r.id)">{{ t('comment.deleteConfirm') }}</BaseButton>
                <BaseButton variant="ghost" @click="cancelDelete">{{ t('app.close') }}</BaseButton>
              </div>
              <div class="error" v-if="deleteErrors[r.id]">{{ deleteErrors[r.id] }}</div>
            </div>
          </li>
        </ul>
      </li>
    </ul>
  </div>
</template>

<script>
import { ref, reactive, computed, onMounted, watch, nextTick } from 'vue'
import { getCommentsForPost, addComment, updateComment, deleteComment } from '../utils/storage'
import { useI18n } from 'vue-i18n'
import BaseButton from './BaseButton.vue'

export default {
  name: 'CommentSection',
  components: { BaseButton },
  props: { postId: { type: String, required: true } },
  setup(props) {
    const { t, locale } = useI18n()

    const comments = ref([])
    const author = ref('')
    const newPassword = ref('')
    const content = ref('')

    const replyAuthor = ref('')
    const replyContent = ref('')

    const replyingTo = ref(null)
    const editingId = ref(null)
    const editContent = ref('')

    const deletingId = ref(null)

    const editPasswords = reactive({})
    const deletePasswords = reactive({})
    const replyPasswords = reactive({})

    const editErrors = reactive({})
    const deleteErrors = reactive({})
    const replyErrors = reactive({})
    const newError = ref('')

    const editRefs = {}
    const deleteRefs = {}
    const replyRefs = {}
    const newPasswordRef = ref(null)

    function setEditRef(id, el) { if (el) editRefs[id] = el; else delete editRefs[id] }
    function setDeleteRef(id, el) { if (el) deleteRefs[id] = el; else delete deleteRefs[id] }
    function setReplyRef(id, el) { if (el) replyRefs[id] = el; else delete replyRefs[id] }

    function load() {
      comments.value = getCommentsForPost(props.postId)
    }

    onMounted(load)
    window.addEventListener('ggb-comments-changed', load)
    watch(() => props.postId, load)

    const rootComments = computed(() => comments.value.filter(c => !c.parentId).sort((a,b)=> (a.createdAt < b.createdAt)?1:-1))
    const childMap = computed(() => {
      const m = {}
      comments.value.forEach(c => {
        if (c.parentId) {
          if (!m[c.parentId]) m[c.parentId] = []
          m[c.parentId].push(c)
        }
      })
      Object.keys(m).forEach(k => m[k].sort((a,b)=> (a.createdAt > b.createdAt)?1:-1))
      return m
    })

    function formatDate(s){
      try {
        const d = new Date(s)
        const loc = (locale && locale.value) ? locale.value : undefined
        return d.toLocaleString(loc)
      } catch(e) { return s }
    }

    async function submit() {
      newError.value = ''
      if (!content.value.trim()) { newError.value = t('comment.errContent') ; return }
      if (!newPassword.value) { newError.value = t('app.confirmDeletePrompt'); await nextTick(); if (newPasswordRef.value) newPasswordRef.value.focus(); return }
      try {
        addComment({ postId: props.postId, parentId: null, author: author.value || t('comment.authorFallback'), content: content.value.trim(), password: newPassword.value })
        author.value = ''; newPassword.value = ''; content.value = ''; load()
      } catch (e) {
        newError.value = e.message || t('comment.errSubmit')
        setTimeout(()=>{ if (newPasswordRef.value) newPasswordRef.value.focus() },0)
      }
    }

    function toggleReply(id) {
      if (replyingTo.value === id) replyingTo.value = null
      else {
        replyingTo.value = id
        replyAuthor.value = ''
        replyPasswords[id] = ''
        replyContent.value = ''
        nextTick(()=>{ if (replyRefs[id]) replyRefs[id].focus() })
      }
    }

    async function submitReply(parentId) {
      replyErrors[parentId] = ''
      if (!replyContent.value.trim()) { replyErrors[parentId] = t('comment.errContent'); return }
      if (!replyPasswords[parentId]) { replyErrors[parentId] = t('app.confirmDeletePrompt'); await nextTick(); if (replyRefs[parentId]) replyRefs[parentId].focus(); return }
      try {
        addComment({ postId: props.postId, parentId, author: replyAuthor.value || t('comment.authorFallback'), content: replyContent.value.trim(), password: replyPasswords[parentId] })
        replyAuthor.value = ''; replyPasswords[parentId] = ''; replyContent.value = ''; replyingTo.value = null; load()
      } catch(e) {
        replyErrors[parentId] = e.message || t('comment.errSubmit')
        setTimeout(()=>{ if (replyRefs[parentId]) replyRefs[parentId].focus() },0)
      }
    }

    function startEdit(c) {
      editErrors[c.id] = ''
      editingId.value = c.id
      editContent.value = c.content || ''
      editPasswords[c.id] = ''
      nextTick(() => { if (editRefs[c.id]) editRefs[c.id].focus() })
    }

    async function confirmEdit(id) {
      editErrors[id] = ''
      const pwd = (editPasswords[id] || '').toString().trim()
      if (!editContent.value.trim()) { editErrors[id] = t('comment.errContent'); return }
      if (!pwd) { editErrors[id] = t('app.confirmDeletePrompt'); await nextTick(); if (editRefs[id]) editRefs[id].focus(); return }
      try {
        updateComment(id, editContent.value.trim(), pwd)
        editingId.value = null
        editContent.value = ''
        editPasswords[id] = ''
        load()
      } catch (e) {
        editErrors[id] = e.message || t('comment.errEdit')
        setTimeout(()=>{ if (editRefs[id]) editRefs[id].focus() },0)
      }
    }

    function cancelEdit() { if (editingId.value) { editErrors[editingId.value] = ''; editPasswords[editingId.value] = '' } editingId.value = null; editContent.value = '' }

    function startDelete(c) {
      deleteErrors[c.id] = ''
      deletingId.value = c.id
      deletePasswords[c.id] = ''
      nextTick(()=>{ if (deleteRefs[c.id]) deleteRefs[c.id].focus() })
    }

    async function confirmDelete(id) {
      deleteErrors[id] = ''
      const pwd = (deletePasswords[id] || '').toString().trim()
      if (!pwd) { deleteErrors[id] = t('app.confirmDeletePrompt'); await nextTick(); if (deleteRefs[id]) deleteRefs[id].focus(); return }
      try {
        deleteComment(id, pwd)
        deletingId.value = null
        deletePasswords[id] = ''
        load()
      } catch (e) {
        deleteErrors[id] = e.message || t('comment.errDelete')
        setTimeout(()=>{ if (deleteRefs[id]) deleteRefs[id].focus() },0)
      }
    }

    function cancelDelete() { if (deletingId.value) { deleteErrors[deletingId.value] = ''; deletePasswords[deletingId.value] = '' } deletingId.value = null }

    return {
      t, comments, rootComments, childMap, author, newPassword, content,
      replyAuthor, replyPasswords, replyContent, replyingTo, toggleReply,
      submitReply, submit,
      startEdit, confirmEdit, cancelEdit, editingId, editContent, editPasswords, setEditRef,
      startDelete, confirmDelete, cancelDelete, deletingId, deletePasswords, setDeleteRef,
      setReplyRef, replyErrors, editErrors, deleteErrors, newError, formatDate, newPasswordRef
    }

  }
}
</script>

<style scoped>
.card { background:#fff; padding:12px; border-radius:8px; border:1px solid rgba(11,17,34,0.04); margin-bottom:12px; }
.comment-section { margin-top:18px; }
.cs-title { margin:0 0 8px; font-size:16px; }
.new-comment input, .new-comment textarea, .reply-form input { width:100%; box-sizing:border-box; margin-bottom:8px; padding:8px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); }
.comment-list { list-style:none; padding:0; margin:0; }
.comment-item { padding:12px; border-radius:8px; margin-bottom:8px; }
.meta { display:flex; gap:8px; align-items:center; justify-content:space-between; }
.author { color:#0b1220; }
.time { color:#64748b; font-size:12px; }
.item-actions { display:flex; gap:8px; }
.link { background:transparent; border:none; color:#2563eb; cursor:pointer; font-size:13px; padding:0; }
.content { margin-top:8px; color:#0b1220; white-space:pre-wrap; }
.replies { list-style:none; padding-left:12px; margin-top:8px; }
.comment-reply { padding:8px; border-left:3px solid #f1f5f9; margin-bottom:6px; border-radius:6px; }

/* actions layout unchanged */
.actions { display:flex; gap:8px; }

/* New: stack delete/edit/reply areas so error sits below buttons */
.edit-area,
.delete-area,
.reply-form {
  display:flex;
  flex-direction:column;
  gap:8px;
  margin-top:8px;
}
.edit-area textarea,
.reply-form textarea { width:100%; box-sizing:border-box; padding:8px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); }
.delete-area input,
.edit-area input,
.reply-form input { padding:8px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); width:100%; box-sizing:border-box; }

.btn { padding:6px 10px; border-radius:8px; background:#2563eb; color:#fff; border:none; cursor:pointer; }
.btn.ghost { background:transparent; border:1px solid rgba(11,17,34,0.06); color:#334155; }
.btn.danger { background:#ef4444; }
.danger { background:#ef4444 !important; color:#fff; }

.error { color:#ef4444; font-size:13px; }
</style>