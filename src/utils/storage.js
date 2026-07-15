export const BOARD_KEY = 'ggb_board_posts_v1';
export const COMMENT_KEY = 'ggb_board_comments_v1';

export function loadPosts() {
  const raw = localStorage.getItem(BOARD_KEY);
  return raw ? JSON.parse(raw) : [];
}

export function savePosts(posts) {
  localStorage.setItem(BOARD_KEY, JSON.stringify(posts));
}

export function addPost(post) {
  // ensure post.password normalized if present
  if (post.password !== undefined && post.password !== null) {
    post.password = String(post.password).trim();
  }
  const posts = loadPosts();
  posts.unshift(post);
  savePosts(posts);
  try { window.dispatchEvent(new Event('ggb-posts-changed')) } catch(e){}
}

export function updatePost(id, updated, password) {
  const posts = loadPosts();
  const idx = posts.findIndex(p => p.id === id);
  if (idx === -1) throw new Error('Not found');
  const storedPwd = String(posts[idx].password ?? '').trim();
  const provided = String(password ?? '').trim();
  if (storedPwd !== provided) throw new Error('Invalid password');
  posts[idx] = {...posts[idx], ...updated, updatedAt: new Date().toISOString()};
  // normalize stored password if updated contains it
  if (updated.password !== undefined) posts[idx].password = String(updated.password).trim();
  savePosts(posts);
  try { window.dispatchEvent(new Event('ggb-posts-changed')) } catch(e){}
}

export function deletePost(id, password) {
  const posts = loadPosts();
  const idx = posts.findIndex(p => p.id === id);
  if (idx === -1) throw new Error('Not found');
  const storedPwd = String(posts[idx].password ?? '').trim();
  const provided = String(password ?? '').trim();
  if (storedPwd !== provided) throw new Error('Invalid password');
  posts.splice(idx,1);
  savePosts(posts);
  try { window.dispatchEvent(new Event('ggb-posts-changed')) } catch(e){}
}

/* --- comment storage --- */

export function loadComments() {
  const raw = localStorage.getItem(COMMENT_KEY);
  return raw ? JSON.parse(raw) : [];
}

export function saveComments(comments) {
  localStorage.setItem(COMMENT_KEY, JSON.stringify(comments));
}

function genId(prefix='c') {
  return prefix + Date.now().toString(36) + Math.random().toString(36).slice(2,8);
}

/**
 * comment shape:
 * {
 *   id, postId, parentId|null, author, content, password, createdAt
 * }
 */
export function addComment({ postId, parentId = null, author = '익명', content = '', password = '' }) {
  if (!content || !String(content).trim()) throw new Error('Content required');
  if (!password || !String(password).trim()) throw new Error('Password required');
  const comments = loadComments();
  const c = {
    id: genId(),
    postId,
    parentId: parentId || null,
    author: author || '익명',
    content: content || '',
    password: String(password || '').trim(),
    createdAt: new Date().toISOString()
  };
  comments.unshift(c);
  saveComments(comments);
  try { window.dispatchEvent(new Event('ggb-comments-changed')) } catch(e){}
  return c;
}

export function updateComment(id, content, password) {
  const comments = loadComments();
  const idx = comments.findIndex(x => x.id === id);
  if (idx === -1) throw new Error('Not found');
  const storedPwd = String(comments[idx].password ?? '').trim();
  const provided = String(password ?? '').trim();
  if (storedPwd !== provided) throw new Error('Invalid password');
  comments[idx].content = content;
  comments[idx].updatedAt = new Date().toISOString();
  saveComments(comments);
  try { window.dispatchEvent(new Event('ggb-comments-changed')) } catch(e){}
}

function collectDescendantIds(comments, id) {
  const children = comments.filter(c => c.parentId === id).map(c => c.id);
  let all = [...children];
  children.forEach(childId => {
    all = all.concat(collectDescendantIds(comments, childId));
  });
  return all;
}

export function deleteComment(id, password) {
  let comments = loadComments();
  const idx = comments.findIndex(x => x.id === id);
  if (idx === -1) throw new Error('Not found');
  const storedPwd = String(comments[idx].password ?? '').trim();
  const provided = String(password ?? '').trim();
  if (storedPwd !== provided) throw new Error('Invalid password');
  // remove descendants too
  const desc = collectDescendantIds(comments, id);
  comments = comments.filter(c => c.id !== id && !desc.includes(c.id));
  saveComments(comments);
  try { window.dispatchEvent(new Event('ggb-comments-changed')) } catch(e){}
}

export function getCommentsForPost(postId) {
  const comments = loadComments();
  // newest-first (addComment uses unshift)
  return comments.filter(c => c.postId === postId).sort((a,b) => (a.createdAt < b.createdAt) ? 1 : -1);
}

export function getCommentById(id) {
  const comments = loadComments();
  return comments.find(c => c.id === id) || null;
}