---
name: VideoCrawling
description: 抓取 TikTok 达人近期视频数据（播放量、点赞、分享、评论、收藏、时长、话题标签、置顶状态）+ 主页级指标（粉丝数、获赞、作品总数），自动留档到 data/scans/ 并支持与上次扫描自动增量对比。触发：用户发 TikTok 视频链接（tiktok.com/@handle/video/id）并要求分析达人、拉最近视频、看播放量、达人数据、"拉 N 条"、"对比上次"、"导出 CSV"。Use when user sends a TikTok video link and asks for creator's recent video stats. Chrome on port 9223 is auto-launched by this skill when missing — no manual step needed.
---

# TikTok 达人近期视频抓取 v2

## 触发条件
用户发 TikTok 视频链接（如 `https://www.tiktok.com/@katmndzonig/video/7671936325502749973`）或 @handle + 「分析达人」/「拉最近 20 条视频」/「拉 50 条」/「看播放量」等。

## 路径常量
- skill 目录（本机为软链，同事机器为普通拷贝——两种情况命令都一样）：`$USERPROFILE/.claude/skills/VideoCrawling/`
- 数据留档根目录：`$USERPROFILE/.claude/skills/VideoCrawling/data/scans/`（随安装位置走，不在仓库里写死盘符）
- ⚠️ 所有命令一律用 `$USERPROFILE` 形式，**禁用 `$HOME` 或 `~/` 开头的路径**：部分机器设了 MSYS_NO_PATHCONV=1 禁用路径转换，`/c/Users/...` 会被 Windows 程序解析成不存在的 `C:\c\Users\...`。实测 `$USERPROFILE/C:/风格` 在转换开与关两种模式下均可用

## 标准流程

### 1. 提取 handle
从链接取 `@` 后面那段；scan.js 自己也能接受完整 URL / @handle / 纯 handle。

### 2. 检查专用 Chrome
```bash
node -e "const s=require('net').Socket();s.setTimeout(2000);s.on('connect',()=>{console.log('OK');s.destroy();process.exit(0)});s.on('error',()=>{console.log('DOWN');process.exit(1)});s.on('timeout',()=>{console.log('DOWN');process.exit(1)});s.connect(9223,'127.0.0.1')"
```
- 输出 `OK` → 直接跳到第 4 步
- 输出 `DOWN` → **自动拉起**（不要让用户手动双击）：

```bash
powershell.exe -NoProfile -Command 'Start-Process -FilePath "$env:USERPROFILE\.claude\skills\VideoCrawling\start-tiktok-chrome.bat"'
```
注意：不要用 `cmd //c start` 形式——Git Bash 会吃掉引号和反斜杠导致静默失败；PowerShell 这条已实测通过。
然后轮询最多 6 次（每次 sleep 5 秒后再跑一次端口检查），任一次输出 `OK` 即继续。
6 次后仍 `DOWN` 才降级为人工提示：「请双击桌面或 `%USERPROFILE%\.claude\skills\VideoCrawling\` 里的 start-tiktok-chrome.bat」

### 3. 抓取并留档（临时文件 → 验错 → 归档）
```bash
node $USERPROFILE/.claude/skills/VideoCrawling/scripts/scan.js <handle> [条数] > /tmp/scan-tmp.json 2>/tmp/scan-log.txt
grep -q '"videos"' /tmp/scan-tmp.json || { cat /tmp/scan-log.txt /tmp/scan-tmp.json; 按「失败处理」表的 error 码行动; }
```
成功（输出含 `"videos"` 字段；错误对象没有它）才归档：
```bash
mkdir -p "$USERPROFILE/.claude/skills/VideoCrawling/data/scans/<handle>"
mv /tmp/scan-tmp.json "$USERPROFILE/.claude/skills/VideoCrawling/data/scans/<handle>/<YYYYMMDD-HHMM>.json"
```
时间戳用当下时刻。**每次成功抓取都必须归档，先归档再渲染输出。**

### 4. 增量对比（有历史档案时自动做）
```bash
ls -1 "$USERPROFILE/.claude/skills/VideoCrawling/data/scans/<handle>"/*.json
```
若除本次新档外还有更早的档案：取 `capturedAt` 最近早于本次的那份跑：
```bash
node $USERPROFILE/.claude/skills/VideoCrawling/scripts/compare.js <上次档案> <本次档案>
```
把 stdout 的 markdown 小节**原样接在主表格后面**。只有一个档案则跳过此步。

## 输出格式

第一行达人名（超链），随后一行主页指标（字段为 null 就省略那项）：

```
达人：[nickname](profileUrl)（@handle）✅认证 ｜ 粉丝 X.X万 ｜ 获赞 Y.Y万 ｜ 作品 Z 条
```

数字用中文习惯缩写（1.41万）；没有 profileStats 数据时这一行只剩名字。

主表格（列比 v1 多了时长与带货标记）：

| # | 视频 | 发布时间 | 时长 | 播放 | 点赞 | 评论 | 分享 | 收藏 | 置顶 | 描述 |
|---:|---|---|---:|---:|---:|---:|---:|---:|:---:|---|

- **视频列**是超链：`[尾号6位](url)`，例如 `[035988](https://www.tiktok.com/@handle/video/...)`
- 发布时间格式 `MM-DD HH:mm`（JSON 里是完整 UTC+8 串，截短即可）
- 时长秒数 >60 显示为分秒 `3:05`
- 置顶 ✅ / —；带货列为 true 用 🛒 否则省略（视为"疑似"，接口信号非精确事实）
- 描述截断 40 字符
- 表格后附汇总行：样本 N 条 ｜ 总播放、总点赞、置顶数、hashtag 出现过的个数

## 多达人批量
去重 handle 后**逐个顺序执行**完整标准流程（含各自留档与增量对比）。两个 handle 之间停顿 `sleep $((2 + RANDOM % 3))` 秒——单 Chrome 会话并发抢请求容易招风控。
最后附跨账号对比表，「达人」列同样用主页超链：

| 达人 | 粉丝 | 样本 | 总播放 | 最高单条 | 置顶 |
|---|---:|---:|---:|---:|---:|

## 按需短句

| 用户说 | 动作 |
|---|---|
| 「拉 50 条」（任意 N） | `scan.js <handle> 50` |
| 「导出 CSV」 | 对该 handle 最新档案跑 `to-csv.js <档案>`，生成的 .csv 在同目录，告知文件路径 |
| 「统计话题标签」 | 读最新档案 videos[].hashtags 做频次聚合，输出 top10 表格（标签、出现次数、对应播放量合计） |
| 「看趋势」 | 按 capturedAt 列出该 handle 全部档案的日期/粉丝数/总播放一张趋势表 |

## 失败处理（错误码驱动）

scan.js 失败时 stdout JSON 带 `error` 字段（/schemaVersion 2）。按码行动：

| error 码 | 含义 | 动作 |
|---|---|---|
| `CHROME_NOT_REACHABLE` | 9223 不通 | 回第 2 步走自动拉起流程 |
| `CREATE_TARGET_FAILED` | 端口通但 CDP 拒绝开 tab | 让用户关掉专用 Chrome 窗口，重跑（会触发自动拉起） |
| `NAV_FAILED_OR_CAPTCHA` | 页面没加载出/滑块验证码 | 请用户在专用 Chrome 手动打开该达人主页完成验证，回来重跑 |
| `EMPTY_RESULT_LIKELY_MS_TOKEN` | 页面在但 0 条数据 | 一句话告知：「msToken 大概率过期了，请在专用 Chrome 里刷新任意一个达人主页，然后告诉我重跑」。若是全新 profile 则还需登录 TikTok |
| `FATAL` | 其它异常 | 看 detail 重试 1 次；仍失败原样报告 detail |

warningCode `PARTIAL_COUNT(got:X,wanted:Y)` 不是失败：照常输出实有的 X 条并注明「达人在 Period 内只有 X 条或滚动未触发更多分页」。缺口超过 30%（要 50 只拿到 32 这种）时重跑 1 次，两次一致就如实展示。

脚本自身不做跨次重试之外的魔法；同一个 handle 连续两次同码失败就停下问人，不要循环空转。

## 重要约束
- **不要绕过验证码**：遇到滑块验证码就停，提示用户
- **不要在专用 Chrome 里操作用户已有标签**：脚本只创建后台 tab，用完关闭
- **不要请求用户的 TikTok 密码**：登录态由用户自己在专用 Chrome 里维护
- **data/scans/ 不进 git**：属业务数据
