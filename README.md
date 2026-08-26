# TikTok 达人视频数据抓取工具

> 给运营同事用的 TikTok 达人数据抓取工具。发一个视频链接，自动拉出该达人**近期 20 条视频**的完整数据：播放量、点赞、分享、评论、收藏、发布时间、**置顶状态**。

## 它解决什么问题

TikTok 主页的视频列表接口需要签名（X-Bogus / X-Gnarly），直接调 API 会被拦。这个工具通过**专用 Chrome 拦截 TikTok 自己发出的请求**，拿到完整签名后的真实数据——和你打开主页看到的一模一样。

## 工作原理

```
同事双击 start-tiktok-chrome.bat
  → 启动专用 Chrome（端口 9223，独立 profile，不弹授权）
  → 同事登录一次 TikTok（登录态长期保留）

同事在 Claude Code 发视频链接
  → Claude 加载 skill
  → 连接专用 Chrome（9223）
  → 打开达人主页，拦截 TikTok SPA 发出的 /api/post/item_list/ 响应
  → 解析出 20 条视频数据（含置顶状态）
  → 生成表格回给同事
```

## 一次性安装（5 分钟）

### 1. 克隆仓库

```bash
git clone https://github.com/<你的组织>/tiktok-creator-scan.git
cd tiktok-creator-scan
```

### 2. 安装 skill 到 Claude Code

把 `tiktok-creator-grid-scan` 文件夹复制到 Claude Code 的 skills 目录：

```bash
# Windows
xcopy /E /I tiktok-creator-grid-scan "%USERPROFILE%\.claude\skills\tiktok-creator-grid-scan"

# macOS / Linux
cp -R tiktok-creator-grid-scan ~/.claude/skills/
```

如果 `.claude/skills/` 不存在，先创建：
```bash
mkdir -p ~/.claude/skills/
```

### 3. 放置启动器到桌面

```bash
# Windows
copy start-tiktok-chrome.bat "%USERPROFILE%\Desktop\"

# macOS / Linux（需改用对应的 Chrome 启动脚本，见下方说明）
```

### 4. 首次启动 + 登录 TikTok

1. 双击桌面的 `start-tiktok-chrome.bat`
2. 会弹出一个**新的 Chrome 窗口**（独立 profile，不影响日常浏览器）
3. 在这个窗口里打开 `https://www.tiktok.com` **登录一次 TikTok**
4. 登录后保持窗口开着

**安装完成！**

---

## 日常使用

1. **双击 `start-tiktok-chrome.bat`**（如果专用 Chrome 已开着就跳过）
2. **在 Claude Code 里发视频链接**：

   ```
   分析这个达人，拉最近 20 条视频数据
   https://www.tiktok.com/@katmndzonig/video/7671936325502749973
   ```

3. Claude 自动跑出表格：发布时间、播放量、点赞、分享、评论、置顶状态

**可以一次发多个链接**，Claude 按达人去重批量跑。

---

## 仓库结构

```
tiktok-creator-scan/
├── README.md                          # 本文件
├── start-tiktok-chrome.bat            # 专用 Chrome 启动器（Windows）
├── tiktok-creator-grid-scan/          # Claude Code skill
│   ├── SKILL.md                       # skill 触发词 + 工作流
│   ├── scripts/
│   │   └── scan.js                    # 核心抓取脚本（CDP + 拦截 post/item_list）
│   └── README.md                      # skill 内部说明
├── start-tiktok-chrome.sh             # macOS/Linux 启动器（见下方）
└── docs/
    └── TROUBLESHOOTING.md             # 常见问题排查
```

---

## macOS / Linux 用户

用 `start-tiktok-chrome.sh` 替代 `.bat`：

```bash
chmod +x start-tiktok-chrome.sh
./start-tiktok-chrome.sh
```

脚本会启动 Chrome 并开启 9223 调试端口。首次运行后在弹出的 Chrome 里登录 TikTok。

---

## 常见问题

<details>
<summary><b>双击 .bat 没反应？</b></summary>

- 确认文件名是 `start-tiktok-chrome.bat`（纯英文）
- 右键 → 用管理员身份运行
- 或在命令行里手动执行：`start "" "%USERPROFILE%\Desktop\start-tiktok-chrome.bat"`

</details>

<details>
<summary><b>Claude 说"9223 端口没开"？</b></summary>

专用 Chrome 没启动。双击桌面的 `start-tiktok-chrome.bat`。

</details>

<details>
<summary><b>抓出来数据是空的 / 和我看到的不一致？</b></summary>

在专用 Chrome 窗口里手动打开那个达人的主页看看：

- 弹验证码 → 关掉标签重开
- 要求登录 → 登录 TikTok
- 正常显示视频 → 回 Claude 重跑

</details>

<details>
<summary><b>之前能抓，突然抓不到了？</b></summary>

TikTok 的访问令牌（msToken）约 6-12 小时过期。在专用 Chrome 里打开任意达人主页刷新一下，回来重跑即可。

</details>

<details>
<summary><b>会不会影响我日常用的 Chrome？</b></summary>

不会。专用 Chrome 用独立 profile（`~/WorkBuddy/tiktok-chrome`），和你日常 Chrome 完全隔离。

</details>

<details>
<summary><b>会不会弹"允许调试"授权框？</b></summary>

不会。用 `.bat` / `.sh` 命令行启动的 Chrome 已显式声明调试端口，不再弹授权。

</details>

---

## 技术说明

- **数据来源**：TikTok 官方接口 `/api/post/item_list/`（SPA 自动发出，带完整签名）
- **抓取方式**：Claude Code 连接专用 Chrome 调试端口（9223），拦截 SPA 请求的响应
- **置顶状态**：来自接口的 `isPinnedItem` 字段
- **不绕过验证码**、不存密码、只读取公开数据
- **要求**：Node.js 22+（Claude Code 自带）

## 限制

- 需要保持专用 Chrome 开着（不用操作 TikTok，开着就行）
- msToken 约 6-12 小时过期，需刷新一次主页
- 受 TikTok 风控影响，偶尔需要重试
- 如需完全无浏览器、团队级稳定方案，建议接入 [KSS MCP（达人精灵）](https://www.kolsprite.com)

## License

MIT
