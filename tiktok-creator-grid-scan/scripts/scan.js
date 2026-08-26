#!/usr/bin/env node
// TikTok creator recent videos scanner
// Connects to dedicated Chrome on port 9223, intercepts /api/post/item_list,
// collects top 20 videos with full stats + pinned status.
// Usage: node scan.js <handle>
// Output: JSON to stdout, logs to stderr

const PORT = 9223;

async function main() {
  const handle = process.argv[2];
  if (!handle) {
    console.error('Usage: node scan.js <handle>');
    process.stdout.write(JSON.stringify({ error: 'no handle provided' }));
    process.exit(1);
  }

  // 1. Check Chrome reachable
  let ver;
  try {
    const resp = await fetch(`http://127.0.0.1:${PORT}/json/version`, { signal: AbortSignal.timeout(5000) });
    if (!resp.ok) throw new Error(`http ${resp.status}`);
    ver = await resp.json();
  } catch (e) {
    process.stdout.write(JSON.stringify({ handle, error: 'chrome not reachable', detail: e.message, hint: '请双击 start-tiktok-chrome.bat 启动专用 Chrome' }));
    process.exit(0);
  }

  // 2. Connect WebSocket
  const ws = new WebSocket(ver.webSocketDebuggerUrl);
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = () => rej(new Error('ws connect failed')); });

  let nextId = 0;
  const pending = new Map();
  const captured = [];

  ws.onmessage = (ev) => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
    else if (m.method === 'Network.responseReceived' && m.params && m.params.response) {
      const u = m.params.response.url;
      if (/\/api\/post\/item_list/.test(u)) {
        captured.push({ reqId: m.params.requestId, url: u, status: m.params.response.status });
      }
    }
  };

  const send = (method, params = {}, sid) => new Promise((r) => {
    const id = ++nextId;
    pending.set(id, r);
    ws.send(JSON.stringify({ id, method, params, sessionId: sid }));
    setTimeout(() => r({ timeout: true, method }), 90000);
  });

  // 3. Create background tab
  const cr = await send('Target.createTarget', { url: 'about:blank' });
  if (!cr.result || !cr.result.targetId) {
    process.stdout.write(JSON.stringify({ handle, error: 'createTarget failed', detail: JSON.stringify(cr).slice(0, 200) }));
    process.exit(0);
  }
  const tid = cr.result.targetId;
  const at = await send('Target.attachToTarget', { targetId: tid, flatten: true });
  const sid = at.result.sessionId;

  await send('Network.enable', { maxTotalBufferSize: 30000000 }, sid).catch(() => {});
  await send('Page.enable', {}, sid).catch(() => {});

  // 4. Navigate with retry until page loads
  const profileUrl = `https://www.tiktok.com/@${handle}`;
  let loaded = false;
  for (let attempt = 1; attempt <= 3 && !loaded; attempt++) {
    await send('Page.navigate', { url: profileUrl }, sid).catch(() => {});
    for (let poll = 0; poll < 8; poll++) {
      await new Promise(r => setTimeout(r, 3000));
      const r = await send('Runtime.evaluate', {
        expression: `JSON.stringify({links: document.querySelectorAll('a[href*="/video/"]').length, bodyLen: document.body ? document.body.innerText.length : 0, captcha: /Drag the slider|slider to fit|puzzle|verify/i.test(document.body ? document.body.innerText : '')})`,
        returnByValue: true
      }, sid);
      const v = r.result && r.result.result && r.result.result.value;
      if (v) {
        const st = JSON.parse(v);
        if (st.links > 0 || (st.bodyLen > 300 && !st.captcha)) { loaded = true; break; }
        if (st.captcha) { console.error(`[attempt ${attempt}] captcha detected`); break; }
      }
    }
  }

  // 5. Scroll to trigger pagination
  if (loaded) {
    for (let s = 0; s < 4; s++) {
      await send('Runtime.evaluate', { expression: 'window.scrollTo(0, document.body.scrollHeight)' }, sid).catch(() => {});
      await new Promise(r => setTimeout(r, 3000));
    }
  }

  // 6. Collect response bodies
  const items = [];
  for (const c of captured) {
    try {
      const { result } = await send('Network.getResponseBody', { requestId: c.reqId }, sid);
      if (result && result.body) {
        let txt = result.body;
        if (result.base64Encoded) txt = Buffer.from(txt, 'base64').toString('utf8');
        const j = JSON.parse(txt);
        if (j.itemList) items.push(...j.itemList);
      }
    } catch (e) {}
  }

  // 7. Dedupe and take top 20
  const seen = new Set();
  const unique = [];
  for (const it of items) {
    if (!seen.has(it.id)) { seen.add(it.id); unique.push(it); }
  }
  const top20 = unique.slice(0, 20).map((it, idx) => ({
    rank: idx + 1,
    id: String(it.id),
    url: `https://www.tiktok.com/@${handle}/video/${it.id}`,
    createTime: it.createTime,
    publishedAt: it.createTime ? new Date(parseInt(it.createTime) * 1000 + 8 * 3600 * 1000).toISOString().slice(0, 16).replace('T', ' ') : null,
    playCount: it.stats && it.stats.playCount,
    likeCount: it.stats && it.stats.diggCount,
    shareCount: it.stats && it.stats.shareCount,
    commentCount: it.stats && it.stats.commentCount,
    collectCount: it.stats && it.stats.collectCount,
    isPinned: !!it.isPinnedItem,
    desc: (it.desc || '').slice(0, 80)
  }));

  // 8. Close tab and output
  await send('Target.closeTarget', { targetId: tid }).catch(() => {});
  ws.close();

  const result = {
    handle,
    totalItems: items.length,
    unique: unique.length,
    pinnedCount: top20.filter(v => v.isPinned).length,
    loaded,
    top20
  };
  process.stdout.write(JSON.stringify(result, null, 2));
  setTimeout(() => process.exit(0), 200);
}

main().catch(e => {
  process.stdout.write(JSON.stringify({ error: 'fatal', detail: e.message }));
  process.exit(0);
});
