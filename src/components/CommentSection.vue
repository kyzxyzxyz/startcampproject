<template>
  <div class="comment-section">
    <h4 class="cs-title">댓글 ({{ comments.length }})</h4>

    <div class="new-comment card">
      <input v-model="author" placeholder="작성자" />
      <input v-model="newPassword" ref="newPasswordRef" type="password" placeholder="비밀번호" />
      <textarea v-model="content" placeholder="댓글을 입력하세요." rows="3"></textarea>
      <div class="error" v-if="newError">{{ newError }}</div>
      <div class="actions">
        <button class="btn" @click="submit">작성</button>
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
              <button class="link" @click="toggleReply(c.id)">답글</button>
              <button class="link" @click="startEdit(c)">{{ editingId === c.id ? '편집' : '수정' }}</button>
              <button class="link" @click="startDelete(c)">{{ deletingId === c.id ? '확인' : '삭제' }}</button>
            </div>
          </div>

          <div v-if="editingId !== c.id" class="content">{{ c.content }}</div>

          <div v-else class="edit-area">
            <textarea v-model="editContent" rows="3"></textarea>
            <input
              v-model="editPasswords[c.id]"
              type="password"
              placeholder="비밀번호"
              :ref="el => setEditRef(c.id, el)"
            />
            <div class="error" v-if="editErrors[c.id]">{{ editErrors[c.id] }}</div>
            <div class="actions">
              <button class="btn" @click="confirmEdit(c.id)">저장</button>
              <button class="btn ghost" @click="cancelEdit">취소</button>
            </div>
          </div>

          <div v-if="deletingId === c.id" class="delete-area">
            <input
              v-model="deletePasswords[c.id]"
              type="password"
              placeholder="비밀번호"
              :ref="el => setDeleteRef(c.id, el)"
            />
            <div class="error" v-if="deleteErrors[c.id]">{{ deleteErrors[c.id] }}</div>
            <div class="actions">
              <button class="btn danger" @click="confirmDelete(c.id)">삭제 확인</button>
              <button class="btn ghost" @click="cancelDelete">취소</button>
            </div>
          </div>
        </div>

        <!-- reply form -->
        <div v-if="replyingTo === c.id" class="reply-form">
          <input v-model="replyAuthor" placeholder="작성자" />
          <input
            v-model="replyPasswords[c.id]"
            type="password"
            placeholder="비밀번호"
            :ref="el => setReplyRef(c.id, el)"
          />
          <textarea v-model="replyContent" placeholder="답글을 입력하세요." rows="2"></textarea>
          <div class="error" v-if="replyErrors[c.id]">{{ replyErrors[c.id] }}</div>
          <div class="actions">
            <button class="btn" @click="submitReply(c.id)">답글 작성</button>
            <button class="btn ghost" @click="toggleReply(null)">취소</button>
          </div>
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
                <button class="link" @click="startEdit(r)">{{ editingId === r.id ? '편집' : '수정' }}</button>
                <button class="link" @click="startDelete(r)">{{ deletingId === r.id ? '확인' : '삭제' }}</button>
              </div>
            </div>

            <div v-if="editingId !== r.id" class="content">{{ r.content }}</div>

            <div v-else class="edit-area">
              <textarea v-model="editContent" rows="3"></textarea>
              <input
                v-model="editPasswords[r.id]"
                type="password"
                placeholder="비밀번호"
                :ref="el => setEditRef(r.id, el)"
              />
              <div class="error" v-if="editErrors[r.id]">{{ editErrors[r.id] }}</div>
              <div class="actions">
                <button class="btn" @click="confirmEdit(r.id)">저장</button>
                <button class="btn ghost" @click="cancelEdit">취소</button>
              </div>
            </div>

            <div v-if="deletingId === r.id" class="delete-area">
              <input
                v-model="deletePasswords[r.id]"
                type="password"
                placeholder="비밀번호"
                :ref="el => setDeleteRef(r.id, el)"
              />
              <div class="error" v-if="deleteErrors[r.id]">{{ deleteErrors[r.id] }}</div>
              <div class="actions">
                <button class="btn danger" @click="confirmDelete(r.id)">삭제 확인</button>
                <button class="btn ghost" @click="cancelDelete">취소</button>
              </div>
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

export default {
  name: 'CommentSection',
  props: { postId: { type: String, required: true } },
  setup(props) {
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

    // use reactive maps to ensure v-model binding is stable
    const editPasswords = reactive({})
    const deletePasswords = reactive({})
    const replyPasswords = reactive({})

    const editErrors = reactive({})
    const deleteErrors = reactive({})
    const replyErrors = reactive({})
    const newError = ref('')

    // refs map for focusing
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

    function formatDate(s){ try { return new Date(s).toLocaleString() } catch(e){ return s } }

    // CREATE
    async function submit() {
      newError.value = ''
      if (!content.value.trim()) { newError.value = '댓글 내용을 입력하세요.'; return }
      if (!newPassword.value) { newError.value = '비밀번호를 입력하세요.'; await nextTick(); if (newPasswordRef.value) newPasswordRef.value.focus(); return }
      try {
        addComment({ postId: props.postId, parentId: null, author: author.value || '작성자', content: content.value.trim(), password: newPassword.value })
        author.value = ''; newPassword.value = ''; content.value = ''; load()
      } catch (e) {
        newError.value = e.message || '작성 실패'
        setTimeout(()=>{ if (newPasswordRef.value) newPasswordRef.value.focus() },0)
      }
    }

    // REPLY
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
      if (!replyContent.value.trim()) { replyErrors[parentId] = '답글 내용을 입력하세요.'; return }
      if (!replyPasswords[parentId]) { replyErrors[parentId] = '비밀번호를 입력하세요.'; await nextTick(); if (replyRefs[parentId]) replyRefs[parentId].focus(); return }
      try {
        addComment({ postId: props.postId, parentId, author: replyAuthor.value || '작성자', content: replyContent.value.trim(), password: replyPasswords[parentId] })
        replyAuthor.value = ''; replyPasswords[parentId] = ''; replyContent.value = ''; replyingTo.value = null; load()
      } catch(e) {
        replyErrors[parentId] = e.message || '작성 실패'
        setTimeout(()=>{ if (replyRefs[parentId]) replyRefs[parentId].focus() },0)
      }
    }

    // EDIT
    function startEdit(c) {
      editErrors[c.id] = ''
      editingId.value = c.id
      editContent.value = c.content || ''
      editPasswords[c.id] = ''
      nextTick(()=>{ if (editRefs[c.id]) editRefs[c.id].focus() })
    }

    async function confirmEdit(id) {
      editErrors[id] = ''
      const pwd = (editPasswords[id] || '').toString().trim()
      if (!editContent.value.trim()) { editErrors[id] = '내용을 입력하세요.'; return }
      if (!pwd) { editErrors[id] = '비밀번호를 입력하세요.'; await nextTick(); if (editRefs[id]) editRefs[id].focus(); return }
      try {
        updateComment(id, editContent.value.trim(), pwd)
        editingId.value = null
        editContent.value = ''
        editPasswords[id] = ''
        load()
      } catch (e) {
        editErrors[id] = e.message || '수정 실패'
        // do not clear the input; keep value so user can correct; focus input so they can type
        setTimeout(()=>{ if (editRefs[id]) editRefs[id].focus() },0)
      }
    }

    function cancelEdit() { if (editingId.value) { editErrors[editingId.value] = ''; editPasswords[editingId.value] = '' } editingId.value = null; editContent.value = '' }

    // DELETE
    function startDelete(c) {
      deleteErrors[c.id] = ''
      deletingId.value = c.id
      deletePasswords[c.id] = ''
      nextTick(()=>{ if (deleteRefs[c.id]) deleteRefs[c.id].focus() })
    }

    async function confirmDelete(id) {
      deleteErrors[id] = ''
      const pwd = (deletePasswords[id] || '').toString().trim()
      if (!pwd) { deleteErrors[id] = '비밀번호를 입력하세요.'; await nextTick(); if (deleteRefs[id]) deleteRefs[id].focus(); return }
      try {
        deleteComment(id, pwd)
        deletingId.value = null
        deletePasswords[id] = ''
        load()
      } catch (e) {
        deleteErrors[id] = e.message || '삭제 실패'
        setTimeout(()=>{ if (deleteRefs[id]) deleteRefs[id].focus() },0)
      }
    }

    function cancelDelete() { if (deletingId.value) { deleteErrors[deletingId.value] = ''; deletePasswords[deletingId.value] = '' } deletingId.value = null }

    return {
      comments, rootComments, childMap, author, newPassword, content,
      replyAuthor, replyPasswords, replyContent, replyingTo, toggleReply,
      submitReply, submit,
      startEdit, confirmEdit, cancelEdit, editingId, editContent, editPasswords, setEditRef: (id,el)=>{ setRef(editRefs,id,el) },
      startDelete, confirmDelete, cancelDelete, deletingId, deletePasswords, setDeleteRef: (id,el)=>{ setRef(deleteRefs,id,el) },
      setReplyRef: (id,el)=>{ setRef(replyRefs,id,el) }, replyErrors, editErrors, deleteErrors, newError, formatDate, newPasswordRef
    }

    // helper to set refs
    function setRef(map, id, el) { if (el) map[id] = el; else delete map[id] }
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
.link { background:transparent; border:none; color:#2563eb; cursor:pointer; font-size:13px; }
.content { margin-top:8px; color:#0b1220; white-space:pre-wrap; }
.replies { list-style:none; padding-left:12px; margin-top:8px; }
.comment-reply { padding:8px; border-left:3px solid #f1f5f9; margin-bottom:6px; border-radius:6px; }
.actions { display:flex; gap:8px; }
.btn { padding:6px 10px; border-radius:8px; background:#2563eb; color:#fff; border:none; cursor:pointer; }
.btn.ghost { background:transparent; border:1px solid rgba(11,17,34,0.06); color:#334155; }
.btn.danger { background:#ef4444; }
.edit-area textarea { width:100%; box-sizing:border-box; padding:8px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); margin-top:8px; }
.delete-area { margin-top:8px; display:flex; gap:8px; align-items:center; }
.delete-area input { padding:8px; border-radius:8px; border:1px solid rgba(11,17,34,0.06); flex:1; }
.error { color:#ef4444; margin-bottom:8px; font-size:13px; }
</style>