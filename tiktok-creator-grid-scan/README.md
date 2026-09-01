# TikTok 达人视频数据抓取工具 v2

## 这是什么
给运营用的 TikTok 达人数据抓取工具。发一个 TikTok 视频链接，自动拉出该达人**近期 N 条视频**（默认 20，可说"拉 50 条"）的完整数据：

- 每条视频：播放量、点赞、分享、评论、收藏、发布时间、时长、话题标签、置顶状态、疑似带货标记
- 主页整体：粉丝数、获赞总数、作品总数

而且会**自动留档**：每次抓取的结果存成 JSON 存在 skill 目录下。同一个达人第二次抓时，自动生成"与上次相比"的变化报告（播放/点赞涨跌、新视频 🆕、消失的视频 ⚠️、粉丝增减）。

## 一次性安装（3 步，5 分钟）

### 第 1 步：安装 skill 到 Claude Code
把这个文件夹（`VideoCrawling`）整个复制到：
```
C:\Users\<你的用户名>\.claude\skills\
```
最终路径应该是：
```
C:\Users\<你的用户名>\.claude\skills\VideoCrawling\
├── SKILL.md
├── scripts\scan.js          # 抓取主脚本
├── scripts\compare.js       # 增量对比
├── scripts\to-csv.js        # 导出 Excel 可开的 CSV
└── start-tiktok-chrome.bat  # 专用 Chrome 启动器
```

> 如果 `.claude\skills\` 文件夹不存在，自己建一个。
>
> ⚠️ 从别人那里拿到的文件夹请确认里面没有 `data\` 子目录——那是对方的抓取留档，不该跟着安装包跑。需要的环境只有 Node.js 18+（装了 Claude Code 就有）。

### 第 2 步：把启动器放桌面
把 `start-tiktok-chrome.bat` 复制到桌面。

### 第 3 步：首次启动 + 登录 TikTok
1. 双击桌面的 `start-tiktok-chrome.bat`
2. 会弹出一个**新的 Chrome 窗口**（独立 profile，不影响你日常浏览器）
3. 在这个新窗口里，打开 `https://www.tiktok.com` **登录一次 TikTok**
4. 登录后保持窗口开着

**安装完成！**

---

## 换电脑装：Chrome 路径不用改

启动器**自动探测** Chrome 安装位置（按顺序）：

1. 标准安装目录：`Program Files` / `Program Files (x86)` / `%LocalAppData%` 下的 Google\Chrome\Application\chrome.exe
2. 注册表 App Paths（覆盖自定义盘符的安装）

全都没找到时才会问一次：
```
[!]在这台电脑上没找到 Google Chrome。
    请在下面输入 chrome.exe 的完整路径后按回车。
    小技巧：直接把 chrome.exe 文件拖进这个窗口再回车也行。
```
输入后路径会记住（保存在启动器旁边的 `chrome-path.txt`），以后每次双击直接生效，不再询问。

---

## 日常使用

1. 双击桌面的 `start-tiktok-chrome.bat` 启动专用 Chrome（已开着就跳过；没开的话 Claude 现在也会**自动帮你拉起**）
2. 保持那个 Chrome 窗口开着
3. 在 Claude Code 里发视频链接，比如：
   ```
   分析这个达人，拉最近 20 条视频数据
   https://www.tiktok.com/@katmndzonig/video/7671936325502749973
   ```
4. Claude 出表格后如果想留档分析，还可以说：
   - 「拉 50 条」—— 抓更多历史
   - 「导出 CSV」—— 生成 Excel 双击就能开的表格文件
   - 「统计话题标签」—— 该达人最爱用的话题 top10
   - 「看趋势」—— 历次抓取的粉丝数/播放量走势表

**可以一次发多个链接**，Claude 会按达人去重批量跑（带防风控间隔）。

### 第一次用，验证一下

在 Claude Code 里原样发这段话（换成任意 TikTok 链接都行）：

```
分析这个达人，拉最近20条视频数据
https://www.tiktok.com/@xxxxxx/video/1234567890123456789
```

正常的话你会得到类似这样的回复（数字为示意）：

> 达人：[Kat Mendoza](https://www.tiktok.com/@katmndzonig)（@katmndzonig）｜ 粉丝 1.82万 ｜ 获赞 48.18万 ｜ 作品 1806 条
>
> | # | 视频 | 发布时间 | 时长 | 播放 | 点赞 | ... |
> |---|---|---|---|---|---|---|
> | 1 | [035988](...) | 07-03 10:24 | 0:18 | 14.2万 | 2,462 | ... |

表格下面是汇总行。第二次扫同一个达人时，会自动多一节「与上次扫描相比」的涨跌报告。

**如果没反应或报错** → 按上面常见问题第一条检查；再不行把报错原文发给 Claude，它会按错误码告诉你下一步。

### 数据存在哪？
```
C:\Users\<你的用户名>\.claude\skills\VideoCrawling\data\scans\<达人handle>\<日期时间>.json
```
CSV 导出文件生成在同一目录里。想重置数据直接删 `data` 文件夹即可。

---

## 常见问题

**Q: 双击 .bat 没反应 / 提示找不到 Chrome？**
A: 按提示把 `chrome.exe` 的完整路径粘贴或拖进窗口回车即可，只需一次，之后永久记住。（写错了就删掉旁边生成的 `chrome-path.txt` 再来一遍）

**Q: Claude 说"9223 端口没开"？**
A: v2 里 Claude 通常会自己帮你启动专用 Chrome；如果连它也没搞定，双击桌面的 `.bat`。

**Q: 抓出来数据是空的？**
A: 多半是访问令牌（msToken）过期了（约 6–12 小时一轮）。在专用 Chrome 窗口里随便刷新一个达人主页，回来让 Claude 重跑即可。如果是全新装的 profile，先确认第 3 步的登录做过。

**Q: 会不会影响我日常用的 Chrome？**
A: 不会。专用 Chrome 用独立 profile（`C:\Users\<用户名>\WorkBuddy\tiktok-chrome`），和你日常 Chrome 完全隔离。

**Q: 数据准吗？**
A: 数据来自 TikTok 官方接口 `/api/post/item_list/`（浏览器自己发出的请求，带完整签名），非第三方估算。"疑似带货"列来自接口的广告/商品信号字段，标注为疑似而非事实。

---

## 技术说明（给好奇的同事）

- 抓取方式：Claude Code 连接专用 Chrome 的调试端口（9223），后台 tab 加载主页并拦截 SPA 请求响应；滚动页数按目标条数自适应
- 留档 JSON 带 `schemaVersion/capturedAt/source` 元信息，增量对比按视频 ID 精确匹配
- 不绕过验证码、不存密码、只读取公开数据
- 置顶状态来自接口的 `isPinnedItem` 字段
