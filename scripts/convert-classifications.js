const fs = require('fs')
const path = require('path')

const inDir = process.argv[2] || '.'
const outFile = process.argv[3] || path.join(process.cwd(), 'public', 'data', 'classifications.json')

const mids = {}
const subs = {}

function parseFile(fp) {
  let txt
  try {
    txt = fs.readFileSync(fp, 'utf8')
  } catch (e) {
    console.warn('skip (read error):', fp)
    return
  }
  const lines = txt.split(/\r?\n/)
  for (const lineRaw of lines) {
    const line = lineRaw.trim()
    if (!line) continue

    // 중분류: "중분류: FD01 (한식)"
    const mMid = line.match(/중분류:\s*([A-Z0-9_]+)\s*\(\s*([^\)]+)\s*\)/i)
    if (mMid) {
      const code = mMid[1].trim().toUpperCase()
      const label = mMid[2].trim()
      if (code) mids[code] = label
    }

    // 소분류: "소분류: FD010100 (관광식당)"
    const mSub = line.match(/소분류:\s*([A-Z0-9_]+)\s*\(\s*([^\)]+)\s*\)/i)
    if (mSub) {
      const code = mSub[1].trim().toUpperCase()
      const label = mSub[2].trim()
      if (code) subs[code] = label
    }

    // 괄호 없는 변형 처리: "소분류: FD010100 관광식당"
    if (!mSub) {
      const mSub2 = line.match(/소분류:\s*([A-Z0-9_]+)\s+(.+)/i)
      if (mSub2) {
        const code = mSub2[1].trim().toUpperCase()
        const label = mSub2[2].trim().replace(/\(.+\)$/, '').trim()
        if (code) subs[code] = label
      }
    }
    if (!mMid) {
      const mMid2 = line.match(/중분류:\s*([A-Z0-9_]+)\s+(.+)/i)
      if (mMid2) {
        const code = mMid2[1].trim().toUpperCase()
        const label = mMid2[2].trim().replace(/\(.+\)$/, '').trim()
        if (code) mids[code] = label
      }
    }
  }
}

function walkDir(dir) {
  const entries = fs.readdirSync(dir)
  for (const e of entries) {
    const full = path.join(dir, e)
    try {
      const st = fs.statSync(full)
      if (st.isDirectory()) walkDir(full)
      else if (st.isFile()) parseFile(full)
    } catch (err) {
      // ignore
    }
  }
}

walkDir(inDir)

fs.mkdirSync(path.dirname(outFile), { recursive: true })
const out = { mid: mids, sub: subs }
fs.writeFileSync(outFile, JSON.stringify(out, null, 2), 'utf8')
console.log('wrote', outFile, 'mid:', Object.keys(mids).length, 'sub:', Object.keys(subs).length)
