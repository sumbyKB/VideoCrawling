---
name: tiktok-creator-grid-scan
description: 抓取 TikTok 达人近期 20 条视频数据（播放量、点赞、分享、评论、收藏、发布时间、置顶状态）。触发：用户发 TikTok 视频链接（tiktok.com/@handle/video/id）并要求分析达人、拉最近视频、看播放量、达人数据、近期 20 条、creator recent videos。Use when user sends a TikTok video link and asks for creator's recent video stats. Prerequisite: user must run start-tiktok-chrome.bat first to launch dedicated Chrome on port 9223.
---

# TikTok 达人近期视频抓取

## 触发条件
用户发 TikTok 视频链接（如 `https://www.tiktok.com/@katmndzonig/video/7671936325502749973`）+ 要求"分析达人"/"拉最近 20 条视频"/"看播放量"/"达人数据"等。

## 前置检查（必须先做）
1. 从链接提取 handle（`@` 后面、`/video/` 前面那段，如 `katmndzonig`）
2. 检查端口 9223 是否在监听：
   ```bash
   node -e "const s=require('net').Socket();s.setTimeout(2000);s.on('connect',()=>{console.log('OK');s.destroy();process.exit(0)});s.on('error',()=>{console.log('DOWN');process.exit(1)});s.on('timeout',()=>{console.log('DOWN');process.exit(1)});s.connect(9223,'127.0.0.1')"
   ```
3. 如果输出 `DOWN` → 告诉用户：「请双击桌面的 `start-tiktok-chrome.bat` 启动专用 Chrome，启动后告诉我」→ 等用户确认后重试
4. 如果输出 `OK` → 继续

## 执行抓取
运行抓取脚本（脚本路径相对本 skill）：
```bash
node ~/.claude/skills/tiktok-creator-grid-scan/scripts/scan.js <handle>
```

脚本会：
- 连接 127.0.0.1:9223 的专用 Chrome
- 后台 tab 加载 `https://www.tiktok.com/@<handle>`
- 拦截 TikTok SPA 发出的 `/api/post/item_list/` 响应（官方接口，含完整签名）
- 滚动触发分页，收集多页
- 合并去重，取前 20 条
- 输出 JSON 到 stdout（日志走 stderr）

## 解析输出
脚本 stdout 是 JSON，结构：
```json
{
  "handle": "katmndzonig",
  "nickname": "KAT MNDZONIG",
  "uniqueId": "katmndzonig",
  "profileUrl": "https://www.tiktok.com/@katmndzonig",
  "totalItems": 67,
  "unique": 67,
  "top20": [
    {
      "rank": 1,
      "id": "7658121941106035988",
      "url": "https://www.tiktok.com/@katmndzonig/video/7658121941106035988",
      "publishedAt": "2026-07-03 10:24",
      "playCount": 141400,
      "likeCount": 2447,
      "shareCount": 258,
      "commentCount": 19,
      "collectCount": 1334,
      "isPinned": true,
      "desc": "ft. @BaredPH #linentop ..."
    }
  ]
}
```

## 输出给用户
先回一行达人名（handle 超链到其主页，名字旁可直接点击进入主页）：

`达人：[katmndzonig](https://www.tiktok.com/@katmndzonig)`

再把它 top20 转成 markdown 表格：

| # | 视频 ID | 发布时间 (UTC+8) | 播放量 | 点赞 | 分享 | 评论 | 收藏 | 置顶 | 描述 |
|---:|---|---:|---:|---:|---:|---:|---:|:---:|---|

- **达人名一律用 markdown 链接** `[@handle](https://www.tiktok.com/@handle)`；若 JSON 里有 `nickname`，写成 `[nickname](profileUrl)（@handle）`
- 置顶列：`isPinned` 为 true 用 ✅，否则 —
- 描述截断到 40 字符
- 表格后附一行汇总：总播放、总点赞、置顶数

## 多达人批量
用户一次发多个链接时：去重 handle 后逐个跑 scan.js，最后输出汇总报告（每位一节 + 跨账号对比表）。

- 每位一节的小标题用超链达人名：`## 达人：[@handle](https://www.tiktok.com/@handle)`
- 跨账号对比表的「达人」列同样用 `[@handle](https://www.tiktok.com/@handle)` 超链，名字旁边即可点击进主页

## 失败处理（按顺序排查）

| 症状 | 原因 | 处理 |
|---|---|---|
| 9223 DOWN | 专用 Chrome 没开 | 提示用户双击 .bat |
| scan.js 输出 `{"error":"chrome not reachable"}` | 9223 端口在但 Chrome 异常 | 提示用户关掉专用 Chrome 窗口重新双击 .bat |
| top20 为空数组 | 页面加载失败/验证码/登录态过期 | 让用户在专用 Chrome 里手动打开 `https://www.tiktok.com/@<handle>` 看看：若弹验证码→关掉重开；若要求登录→登录 TikTok；若正常显示→回来重跑 |
| top20 不足 20 条 | 滚动没触发足够分页 | 重跑一次（脚本内置重试） |
| 用户说"数据和我看到的不一致" | 可能抓到的是错误页 | 让用户在专用 Chrome 里确认该达人主页能正常显示视频网格 |

## 重要约束
- **不要绕过验证码**：遇到滑块验证码就停，提示用户刷新
- **不要在专用 Chrome 里操作用户已有标签**：脚本只创建后台 tab，用完关闭
- **不要请求用户的 TikTok 密码**：登录态由用户自己在专用 Chrome 里维护
- msToken 约 6-12 小时过期，过期时 top20 会变空，提示用户在专用 Chrome 刷新任意达人主页即可
