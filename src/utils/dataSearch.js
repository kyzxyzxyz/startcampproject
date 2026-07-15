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
