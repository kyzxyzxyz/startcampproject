#!/usr/bin/env bash
set -e

ROOT_DIR="$(pwd)"
echo "Scaffolding project in: $ROOT_DIR"

# Directories
mkdir -p src/views src/components src/utils public scripts

# Warn if public/data missing
if [ ! -d "public/data" ]; then
  echo "경고: public/data 폴더가 없습니다. 제공 JSON 파일을 public/data/ 로 복사하세요."
else
  echo "public/data 존재 확인."
fi

# package.json
cat > package.json <<'EOF'
{
  "name": "ggb-vue-spa",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "extract-manifest": "node scripts/extract-collection-dates.js"
  },
  "dependencies": {
    "vue": "^3.3.0",
    "vue-router": "^4.2.0",
    "uuid": "^9.0.0"
  },
  "devDependencies": {
    "vite": "^5.0.0"
  }
}
EOF

# vite.config.js
cat > vite.config.js <<'EOF'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  base: '/'
})
EOF

# .env.example
cat > .env.example <<'EOF'
VITE_OPENAI_API_KEY=sk-REPLACE_WITH_LIMITED_KEY
VITE_REGION=구미_경북권
EOF

# netlify.toml
cat > netlify.toml <<'EOF'
[build]
  command = "npm run build"
  publish = "dist"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
EOF

# README.md
cat > README.md <<'EOF'
프로젝트 실행
1. .env 파일 생성: cp .env.example .env (VITE_OPENAI_API_KEY 포함)
2. 설치: npm install
3. 개발: npm run dev
4. 빌드: npm run build
5. Netlify: Git 리포지토리 연결 후 배포(환경변수 VITE_OPENAI_API_KEY 설정 권장)

주의: Vite의 VITE_ 접두사 환경변수는 클라이언트 번들에 포함되어 노출됩니다. 데모/테스트용으로만 사용하세요.
EOF

# scripts/extract-collection-dates.js
cat > scripts/extract-collection-dates.js <<'EOF'
/*
 실행: npm run extract-manifest
 목적: public/data/ 내부 제공 JSON 파일들의 최신 modifiedtime을 추출해 public/data_manifest.json 생성
*/
import fs from 'fs'
const files = [
  'public/data/구미_경북권_관광지.json',
  'public/data/구미_경북권_레포츠.json',
  'public/data/구미_경북권_문화시설.json',
  'public/data/구미_경북권_쇼핑.json',
  'public/data/구미_경북권_숙박.json',
  'public/data/구미_경북권_여행코스.json',
  'public/data/구미_경북권_음식점.json',
  'public/data/구미_경북권_축제공연행사.json'
];

const manifest = [];

for(const f of files) {
  if (!fs.existsSync(f)) { console.warn(`${f} not found`); continue; }
  const obj = JSON.parse(fs.readFileSync(f,'utf8'));
  const times = (obj.items || []).map(it => it.modifiedtime || it.createdtime).filter(Boolean);
  const latest = times.length ? times.sort().pop() : null;
  manifest.push({
    file: f.replace('public/',''),
    contentType: obj.contentType || null,
    contentTypeId: obj.contentTypeId || null,
    total: obj.total || (obj.items || []).length,
    license: '공공누리 제3유형 (한국관광공사 Tour API)',
    source: '한국관광공사 Tour API v4 (https://www.data.go.kr/data/15101578/openapi.do)',
    latestModifiedTime: latest
  })
}

fs.writeFileSync('public/data_manifest.json', JSON.stringify(manifest, null, 2))
console.log('wrote public/data_manifest.json')
EOF

# public/data_manifest.json (placeholder)
cat > public/data_manifest.json <<'EOF'
[]
EOF

# src/main.js
cat > src/main.js <<'EOF'
import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import HomeView from './views/HomeView.vue'
import BoardView from './views/BoardView.vue'
import BoardDetail from './views/BoardDetail.vue'
import ChatView from './views/ChatView.vue'

const routes = [
  { path: '/', component: HomeView },
  { path: '/board', component: BoardView },
  { path: '/board/:id', component: BoardDetail, props: true },
  { path: '/chat', component: ChatView }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

createApp(App).use(router).mount('#app')
EOF

# src/App.vue
cat > src/App.vue <<'EOF'
<template>
  <div id="app">
    <header>
      <h1>구미_경북권 지역정보</h1>
      <nav>
        <router-link to="/">홈</router-link> |
        <router-link to="/board">커뮤니티</router-link> |
        <router-link to="/chat">챗봇</router-link>
      </nav>
    </header>
    <main>
      <router-view />
    </main>
  </div>
</template>

<style>
body { font-family: system-ui, Arial; margin:0; padding:0; }
header { padding:12px; background:#f6f6f8; }
main { padding:16px; }
</style>
EOF

# src/views/HomeView.vue
cat > src/views/HomeView.vue <<'EOF'
<template>
  <div>
    <h2>홈</h2>
    <p>로컬 데이터 기반 Vue3 SPA — 제공 JSON으로 동작합니다.</p>
    <ul>
      <li><router-link to="/board">커뮤니티(카테고리 게시판)</router-link></li>
      <li><router-link to="/chat">챗봇 (OpenAI + 로컬 데이터)</router-link></li>
    </ul>
  </div>
</template>
EOF

# src/views/BoardView.vue
cat > src/views/BoardView.vue <<'EOF'
<template>
  <div>
    <h2>커뮤니티 게시판 (카테고리: 관광지)</h2>
    <BoardEditor @created="onCreated" />
    <BoardList :posts="posts" @refresh="load" />
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import BoardList from '../components/BoardList.vue'
import BoardEditor from '../components/BoardEditor.vue'
import { loadPosts } from '../utils/storage'

export default {
  components: { BoardList, BoardEditor },
  setup() {
    const posts = ref([]);
    function load() { posts.value = loadPosts().filter(p => p.category === '관광지'); }
    onMounted(load);
    function onCreated() { load(); }
    return { posts, load, onCreated }
  }
}
</script>
EOF

# src/views/BoardDetail.vue
cat > src/views/BoardDetail.vue <<'EOF'
<template>
  <div>
    <h2>게시글 상세</h2>
    <div v-if="post">
      <h3>{{ post.title }}</h3>
      <div>{{ post.content }}</div>
      <small>작성: {{ format(post.createdAt) }}</small>
      <div style="margin-top:8px">
        <button @click="startEdit">수정</button>
        <button @click="askDelete">삭제</button>
      </div>
    </div>
    <div v-else>
      <p>게시글을 찾을 수 없습니다.</p>
    </div>

    <div v-if="editing">
      <h4>수정 (비밀번호 확인)</h4>
      <input v-model="editTitle" />
      <textarea v-model="editContent"></textarea>
      <input v-model="editPassword" type="password" placeholder="비밀번호 입력" />
      <button @click="doUpdate">저장</button>
      <button @click="cancelEdit">취소</button>
    </div>

    <div v-if="confirmDelete">
      <h4>삭제 (비밀번호 입력)</h4>
      <input v-model="delPassword" type="password" />
      <button @click="doDelete">삭제</button>
      <button @click="confirmDelete=false">취소</button>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { loadPosts, updatePost, deletePost } from '../utils/storage'
import { useRouter, useRoute } from 'vue-router'

export default {
  setup() {
    const router = useRouter()
    const route = useRoute()
    const id = route.params.id
    const post = ref(null)
    const editing = ref(false)
    const confirmDelete = ref(false)
    const editTitle = ref('')
    const editContent = ref('')
    const editPassword = ref('')
    const delPassword = ref('')

    function load() {
      const p = loadPosts().find(x => x.id === id)
      post.value = p || null
    }
    function format(t){ return t ? new Date(t).toLocaleString() : '' }

    function startEdit(){
      editing.value = true
      editTitle.value = post.value.title
      editContent.value = post.value.content
    }
    function cancelEdit(){ editing.value=false; editPassword.value='' }

    function doUpdate() {
      try {
        updatePost(id, { title: editTitle.value, content: editContent.value }, editPassword.value)
        alert('수정되었습니다.')
        editing.value = false
        load()
      } catch (e) { alert(e.message) }
    }

    function askDelete(){ confirmDelete.value = true }

    function doDelete(){
      try {
        deletePost(id, delPassword.value)
        alert('삭제되었습니다.')
        router.push('/board')
      } catch(e){ alert(e.message) }
    }

    onMounted(load)
    return { post, editing, confirmDelete, editTitle, editContent, editPassword, delPassword, startEdit, cancelEdit, doUpdate, askDelete, doDelete, format }
  }
}
</script>
EOF

# src/views/ChatView.vue
cat > src/views/ChatView.vue <<'EOF'
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
EOF

# src/components/BoardEditor.vue
cat > src/components/BoardEditor.vue <<'EOF'
<template>
  <div class="editor">
    <h3>게시글 작성</h3>
    <form @submit.prevent="submit">
      <div>
        <label>제목 <input v-model="title" required /></label>
      </div>
      <div>
        <label>본문 <textarea v-model="content" rows="4" required></textarea></label>
      </div>
      <div>
        <label>비밀번호(수정/삭제용) <input v-model="password" type="password" required /></label>
      </div>
      <button type="submit">작성</button>
    </form>
  </div>
</template>

<script>
import { ref } from 'vue'
import { addPost } from '../utils/storage'
import { v4 as uuidv4 } from 'uuid'

export default {
  emits: ['created'],
  setup(_, { emit }) {
    const title = ref('')
    const content = ref('')
    const password = ref('')
    function submit() {
      const post = {
        id: uuidv4(),
        category: '관광지',
        title: title.value,
        content: content.value,
        password: password.value,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }
      addPost(post)
      title.value = content.value = password.value = ''
      emit('created')
    }
    return { title, content, password, submit }
  }
}
</script>

<style>
.editor { margin-bottom: 16px; }
</style>
EOF

# src/components/BoardList.vue
cat > src/components/BoardList.vue <<'EOF'
<template>
  <div>
    <h3>게시글 목록</h3>
    <div>
      <input v-model="q" placeholder="검색(제목/내용)" />
      <button @click="doSearch">검색</button>
      <button @click="clearSearch">전체</button>
    </div>
    <ul>
      <li v-for="p in paged" :key="p.id">
        <router-link :to="\`/board/\${p.id}\`">{{ p.title }}</router-link>
        <small> — {{ new Date(p.createdAt).toLocaleString() }}</small>
      </li>
    </ul>
    <div v-if="pages>1">
      <button @click="prev" :disabled="page===1">이전</button>
      <span>{{page}} / {{pages}}</span>
      <button @click="next" :disabled="page===pages">다음</button>
    </div>
  </div>
</template>

<script>
import { computed, ref, watch } from 'vue'
import { loadPosts } from '../utils/storage'

export default {
  emits: ['refresh'],
  props: { posts: Array },
  setup(props, { emit }) {
    const q = ref('')
    const page = ref(1)
    const pageSize = 10

    const filtered = computed(() => {
      const arr = loadPosts().filter(p => p.category === '관광지')
      if (!q.value) return arr
      return arr.filter(p => (p.title + p.content).toLowerCase().includes(q.value.toLowerCase()))
    })

    const pages = computed(() => Math.max(1, Math.ceil(filtered.value.length / pageSize)))
    const paged = computed(() => filtered.value.slice((page.value-1)*pageSize, page.value*pageSize))

    function doSearch() { page.value = 1 }
    function clearSearch() { q.value=''; page.value=1 }
    function next(){ if(page.value<pages.value) page.value++ }
    function prev(){ if(page.value>1) page.value-- }

    watch(filtered, () => { if(page.value>pages.value) page.value = pages.value })

    return { q, page, pages, paged, doSearch, clearSearch, next, prev }
  }
}
</script>
EOF

# src/components/ChatMessage.vue
cat > src/components/ChatMessage.vue <<'EOF'
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
EOF

# src/components/ChatBot.vue
cat > src/components/ChatBot.vue <<'EOF'
<template>
  <div class="chat-wrapper">
    <div class="header"><strong>지역 챗봇</strong></div>
    <div class="history" ref="historyRef">
      <ChatMessage v-for="(m, i) in history" :key="i" :role="m.role" :text="m.text" />
    </div>
    <div class="input-row">
      <input v-model="q" @keydown.enter="send" placeholder="질문을 입력하세요. (예: 금오산 근처 추천 관광지)" />
      <button @click="send">전송</button>
      <button @click="clear">초기화</button>
    </div>
    <div class="quick">
      <button @click="preset('금오산 근처 추천 관광지 3곳 알려줘')">관광지 추천</button>
      <button @click="preset('이번 달 구미 축제 일정 알려줘')">축제 일정</button>
      <button @click="preset('모범음식점 추천해줘')">음식점 위치</button>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import ChatMessage from './ChatMessage.vue'
import { loadAllData, simpleRank } from '../utils/dataSearch'
import { callOpenAI } from '../utils/openai'

export default {
  components: { ChatMessage },
  setup() {
    const q = ref('')
    const history = ref([
      { role:'system', text:'당신은 구미_경북권 지역 안내 봇입니다. 제공된 지역 데이터 기반으로 사실에 근거해 답변하세요.' }
    ])
    const dataCache = ref([])

    onMounted(async () => {
      dataCache.value = await loadAllData()
    })

    async function send() {
      if (!q.value.trim()) return;
      const userText = q.value.trim()
      history.value.push({ role:'user', text: userText })

      // 간단 RAG: 로컬 데이터 검색 후 요약을 system context로 추가
      const top = simpleRank(userText, dataCache.value, 5)
      const summary = top.map(t => \`- \${t.title || ''}\${t.addr1 ? ' / ' + t.addr1 : ''}\${t.mapx && t.mapy ? \` (lon:\${t.mapx},lat:\${t.mapy})\` : ''}\`).join('\\n')
      const systemContext = \`참고자료(상위 \${top.length}개):\\n\${summary}\\n위 자료를 참고하여 질문에 답변하시오. 출처: 한국관광공사 Tour API.\`

      const messages = [
        { role:'system', content: systemContext },
        ...history.value.filter(h=>h.role!=='system').map(h=>({role:h.role, content:h.text})),
        { role:'user', content: userText }
      ]

      history.value.push({ role:'assistant', text: '응답을 생성 중입니다...' })
      try {
        const ai = await callOpenAI(messages)
        // replace placeholder assistant message
        history.value[history.value.length-1].text = ai
      } catch (e) {
        history.value[history.value.length-1].text = \`오류: \${e.message}\`
      }

      q.value = ''
      // 스크롤
      setTimeout(()=> {
        const el = document.querySelector('.history')
        if(el) el.scrollTop = el.scrollHeight
      }, 50)
    }

    function clear() {
      history.value = [{ role:'system', text:'당신은 구미_경북권 지역 안내 봇입니다. 제공된 지역 데이터 기반으로 사실에 근거해 답변하세요.' }]
    }

    function preset(t){ q.value = t; send() }

    return { q, history, send, clear, preset }
  }
}
</script>

<style>
.chat-wrapper { border:1px solid #ddd; padding:12px; width:100%; max-width:720px; }
.history { height:300px; overflow:auto; background:#fff; padding:8px; border:1px solid #eee; }
.input-row { margin-top:8px; display:flex; gap:8px; }
.quick { margin-top:8px; display:flex; gap:8px; flex-wrap:wrap; }
</style>
EOF

# src/utils/storage.js
cat > src/utils/storage.js <<'EOF'
export const BOARD_KEY = 'ggb_board_posts_v1';

export function loadPosts() {
  const raw = localStorage.getItem(BOARD_KEY);
  return raw ? JSON.parse(raw) : [];
}

export function savePosts(posts) {
  localStorage.setItem(BOARD_KEY, JSON.stringify(posts));
}

export function addPost(post) {
  const posts = loadPosts();
  posts.unshift(post);
  savePosts(posts);
}

export function updatePost(id, updated, password) {
  const posts = loadPosts();
  const idx = posts.findIndex(p => p.id === id);
  if (idx === -1) throw new Error('Not found');
  if (posts[idx].password !== password) throw new Error('Invalid password');
  posts[idx] = {...posts[idx], ...updated, updatedAt: new Date().toISOString()};
  savePosts(posts);
}

export function deletePost(id, password) {
  const posts = loadPosts();
  const idx = posts.findIndex(p => p.id === id);
  if (idx === -1) throw new Error('Not found');
  if (posts[idx].password !== password) throw new Error('Invalid password');
  posts.splice(idx,1);
  savePosts(posts);
}
EOF

# src/utils/dataSearch.js
cat > src/utils/dataSearch.js <<'EOF'
export async function loadAllData() {
  const files = [
    '/data/구미_경북권_관광지.json',
    '/data/구미_경북권_음식점.json',
    '/data/구미_경북권_축제공연행사.json',
    '/data/구미_경북권_문화시설.json',
    '/data/구미_경북권_레포츠.json',
    '/data/구미_경북권_숙박.json',
    '/data/구미_경북권_여행코스.json',
    '/data/구미_경북권_쇼핑.json'
  ];
  const results = await Promise.all(files.map(f => fetch(f).then(r => r.json()).catch(()=>({items:[]}))));
  const merged = results.flatMap(r => r.items || []);
  return merged;
}

export function simpleRank(query, items, topN=5) {
  const q = query.toLowerCase();
  const scored = items.map(it => {
    const text = ((it.title||'') + ' ' + (it.addr1||'') + ' ' + (it.cat1||'') + ' ' + (it.cat2||'') + ' ' + (it.lclsSystm3||'')).toLowerCase();
    let score = 0;
    if (text.includes(q)) score += 10;
    const qwords = q.split(/\\s+/).filter(Boolean);
    for(const w of qwords) if(text.includes(w)) score += 2;
    return {it, score};
  }).filter(x=>x.score>0).sort((a,b)=>b.score-a.score);
  return scored.slice(0, topN).map(s => s.it);
}
EOF

# src/utils/openai.js
cat > src/utils/openai.js <<'EOF'
const API_URL = 'https://api.openai.com/v1/chat/completions';

export async function callOpenAI(messages, model = 'gpt-4o-mini') {
  const key = import.meta.env.VITE_OPENAI_API_KEY;
  if (!key) throw new Error('OpenAI API key not set in VITE_OPENAI_API_KEY');
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${key}`
    },
    body: JSON.stringify({
      model,
      messages,
      max_tokens: 800,
      temperature: 0.2
    })
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`${res.status} ${txt}`);
  }
  const data = await res.json();
  const content = data.choices?.[0]?.message?.content || '';
  return content;
}
EOF

echo "Scaffold complete. 생성된 파일 목록 (요약):"
echo " - package.json, vite.config.js, .env.example, netlify.toml, README.md"
echo " - scripts/extract-collection-dates.js"
echo " - public/data_manifest.json (빈 템플릿)"
echo " - src/ (main.js, App.vue, views/, components/, utils/)"
echo ""
echo "다음 단계:"
echo "1) 제공 JSON 파일들을 project/public/data/ 에 넣으세요 (이미 워크스페이스에 있다면 확인)."
echo "2) npm install"
echo "3) cp .env.example .env 후 VITE_OPENAI_API_KEY 값을 제한된 키로 설정"
echo "4) npm run dev"