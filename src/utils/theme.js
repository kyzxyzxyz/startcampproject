export function updateMetaThemeColor(){
  const meta = document.querySelector('meta[name="theme-color"]') || (function(){
    const m=document.createElement('meta'); m.name='theme-color'; document.head.appendChild(m); return m;
  })();
  meta.content = document.documentElement.classList.contains('dark') ? '#121214' : '#ffffff';
}

export function setTheme(isDark){
  document.documentElement.classList.toggle('dark', !!isDark);
  try { localStorage.setItem('theme', isDark ? 'dark' : 'light'); } catch(e){}
  updateMetaThemeColor();
}

export function initThemeStorageSync(){
  window.addEventListener('storage', e => {
    if (e.key === 'theme') document.documentElement.classList.toggle('dark', e.newValue === 'dark');
  });
}