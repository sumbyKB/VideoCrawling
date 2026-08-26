# 常见问题排查

## 1. 双击 .bat 没反应

**原因**：文件编码/换行符问题，或 Chrome 路径不对。

**排查**：
- 确认文件名是 `start-tiktok-chrome.bat`（纯英文，无中文）
- 右键 .bat → 编辑，检查 `CHROME` 路径指向的 chrome.exe 是否存在
- 如果 Chrome 装在非默认路径，修改 .bat 里的 `set CHROME=...`
- 命令行手动执行看报错：`start-tiktok-chrome.bat`

## 2. Claude 说"9223 端口没开"

**原因**：专用 Chrome 没启动。

**解决**：双击 `start-tiktok-chrome.bat`。如果双击没反应，参考第 1 条。

## 3. 抓出来数据是空的（0 条）

**可能原因**（按概率排序）：

### a. 专用 Chrome 没登录 TikTok
在专用 Chrome 窗口里打开 `https://www.tiktok.com`，确认右上角是登录状态。如果没登录，登录一次。

### b. msToken 过期（6-12 小时一次）
在专用 Chrome 里打开任意达人主页（如 `https://www.tiktok.com/@katmndzonig`），等页面加载完，回来重跑。

### c. 页面弹了验证码
在专用 Chrome 里手动打开那个达人主页看看：
- 如果弹滑块验证码 → 关掉这个标签，重新打开
- 如果显示"出错了" → 刷新页面
- 如果正常显示视频网格 → 回 Claude 重跑

### d. TikTok 风控临时升级
等 10-30 分钟再试。如果持续不行，换一个网络环境（手机热点试试）。

## 4. 数据和我在浏览器看到的不一致

**原因**：可能抓到的是错误页（TikTok 返回了"出错了"页面）。

**解决**：
1. 在专用 Chrome 里手动打开该达人主页
2. 确认视频网格正常显示（能看到视频缩略图和播放量）
3. 回 Claude 重跑

## 5. 之前能抓，突然抓不到了

**原因**：msToken 过期（最常见）或 Chrome 被关了。

**解决**：
1. 确认专用 Chrome 还开着
2. 在专用 Chrome 里刷新任意达人主页
3. 回 Claude 重跑

## 6. Claude Code 没识别到 skill

**排查**：
- 确认 skill 路径：`~/.claude/skills/tiktok-creator-grid-scan/SKILL.md` 存在
- 在 Claude Code 里问：「你能看到 tiktok-creator-grid-scan 这个 skill 吗？」
- 如果看不到，重启 Claude Code

## 7. macOS / Linux 上 .sh 脚本无法运行

```bash
chmod +x start-tiktok-chrome.sh
./start-tiktok-chrome.sh
```

如果 Chrome 路径不对，编辑脚本里的 `CHROME` 变量。

## 8. 端口 9223 被占用

```bash
# Windows
netstat -ano | findstr :9223
# 找到 PID 后
taskkill /PID <PID> /F

# macOS / Linux
lsof -i :9223
kill <PID>
```

然后重新双击 .bat / 运行 .sh。
