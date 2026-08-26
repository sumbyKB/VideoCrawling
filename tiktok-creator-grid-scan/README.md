# TikTok 达人视频数据抓取工具

## 这是什么
给运营同事用的 TikTok 达人数据抓取工具。发一个 TikTok 视频链接，自动拉出该达人**近期 20 条视频**的完整数据：播放量、点赞、分享、评论、收藏、发布时间、**置顶状态**。

## 一次性安装（3 步，5 分钟）

### 第 1 步：安装 skill 到 Claude Code
把这个文件夹（`tiktok-creator-grid-scan`）整个复制到：
```
C:\Users\<你的用户名>\.claude\skills\
```
最终路径应该是：
```
C:\Users\<你的用户名>\.claude\skills\tiktok-creator-grid-scan\
├── SKILL.md
├── scripts\scan.js
└── start-tiktok-chrome.bat
```

> 如果 `.claude\skills\` 文件夹不存在，自己建一个。

### 第 2 步：把启动器放桌面
把 `start-tiktok-chrome.bat` 复制到桌面。

### 第 3 步：首次启动 + 登录 TikTok
1. 双击桌面的 `start-tiktok-chrome.bat`
2. 会弹出一个**新的 Chrome 窗口**（独立 profile，不影响你日常浏览器）
3. 在这个新窗口里，打开 `https://www.tiktok.com` **登录一次 TikTok**
4. 登录后保持窗口开着

**安装完成！**

---

## 日常使用（每次抓数据）

1. **双击桌面的 `start-tiktok-chrome.bat`** 启动专用 Chrome（如果已经开着就跳过）
2. **保持那个 Chrome 窗口开着**（不用打开 TikTok，开着就行）
3. **在 Claude Code 里发视频链接**，比如：
   ```
   分析这个达人，拉最近 20 条视频数据
   https://www.tiktok.com/@katmndzonig/video/7671936325502749973
   ```
4. Claude 会自动跑出一份表格：发布时间、播放量、点赞、分享、评论、置顶状态

**可以一次发多个链接**，Claude 会按达人去重批量跑。

---

## 常见问题

**Q: 双击 .bat 没反应？**
A: 检查文件名是不是 `start-tiktok-chrome.bat`（纯英文）。如果还是不行，右键 → 用管理员身份运行。

**Q: Claude 说"9223 端口没开"？**
A: 专用 Chrome 没启动。双击桌面的 `start-tiktok-chrome.bat`。

**Q: 抓出来数据是空的 / 和我看到的不一致？**
A: 在专用 Chrome 窗口里手动打开那个达人的主页看看：
- 如果弹验证码 → 关掉那个标签，重开
- 如果要求登录 → 登录 TikTok
- 如果正常显示视频 → 回 Claude 重跑

**Q: 之前能抓，突然抓不到了？**
A: TikTok 的访问令牌（msToken）约 6-12 小时过期。在专用 Chrome 里打开任意达人主页刷新一下，回来重跑即可。

**Q: 会不会影响我日常用的 Chrome？**
A: 不会。专用 Chrome 用独立 profile（`C:\Users\<用户名>\WorkBuddy\tiktok-chrome`），和你日常 Chrome 完全隔离。

**Q: 会不会弹"允许调试"的授权框？**
A: 不会。用 .bat 命令行启动的 Chrome 已显式声明调试端口，不再弹授权。

---

## 技术说明（给好奇的同事）

- 数据来源：TikTok 官方接口 `/api/post/item_list/`（SPA 自动发出的请求，带完整签名）
- 抓取方式：Claude Code 连接专用 Chrome 的调试端口（9223），拦截 SPA 请求的响应
- 不绕过验证码、不存密码、只读取公开数据
- 置顶状态来自接口的 `isPinnedItem` 字段
