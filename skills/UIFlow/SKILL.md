---
name: UIFlow
description: "端到端 UI 設計流程 — 分析 Figma 設計檔提取 Design System + 讀取 PM 原型圖 + Stitch SDK 生成設計（含真實圖片）+ 自動產出 Figma Plugin 程式碼。觸發詞：「分析設計檔」「提取DS」「從原型出設計」「UIFlow」「迭代設計」「redesign」「依照規則出設計」「分析Figma」「PM原型轉UI」「出設計稿」「生成設計」「CAD」「CBD」「建元件」「轉Figma」「Figma plugin」「產Figma程式碼」「stitch」「generate design」"
---

# UIFlow — 通用 UI 設計生成流程

從「Figma 設計檔 DS 分析」→「PM 原型理解」→「Stitch 生成（含圖片）」→「產出 Figma Plugin 程式碼」的端到端工作流。適用於任何 UI 迭代專案。

```
Step 1: 分析 DS → Step 2: 讀原型 → Step 3: Stitch 生成 → Step 4: 寫 Figma Plugin
(Figma MCP)      (Figma MCP)      (Stitch SDK)       (含真實圖片)
```

---

## 專案設定檔概念

每個使用 UIFlow 的專案必須建立一個 `PROJECT.md`，放在對應 skill 目錄下（如 `.claude/skills/UIFlow/PROJECT.md`）。它包含：

- 品牌名稱、設計檔 URL、原型圖 URL
- 完整 DS tokens（色彩、字體、佈局常數）
- Component 規格表 + off-canvas 定位表
- 圖片資源規則（書封/頭像/Banner 等）
- manifest.json 當前狀態
- 已刪除頁面清單
- 其他專案特定規則

**使用時，先讀取 PROJECT.md 取得專案設定，再按下面的通用步驟執行。**

### PROJECT.md 模板結構

```markdown
# {品牌名} — 專案設定檔

## 基本資訊
- 品牌名稱: {品牌名}
- 設計檔 URL: {設計檔URL}
- 原型圖 URL: {原型圖URL}

## Design System Tokens

### 色彩
| Token | 值 | 用途 |
|-------|-----|------|
| background | #XXXXXX | 頁面底色 |
| primary | #XXXXXX | 主色 |
| ... | ... | ... |

### 字體
- Family: {字體名稱}
- Weights: [Regular, Medium, Bold, ...]

### 佈局常數
- 桌機: page_width={}, content_width={}, margin={}
- 手機: width={}, padding={}, inner={}, gap={}

### 圓角 / 間距
- radius: [...]
- spacing: [...]

## Component 規格表
| Component | 尺寸 | Off-canvas | 用途 | 排列 |
|-----------|------|------------|------|------|
| ... | ... | ... | ... | ... |

### Component 結構圖
（每個 Component 的 ASCII 結構圖）

## 圖片資源規則
- **書封/商品圖/角色圖等核心視覺一律從 Figma 設計稿提取**（透過 `get_design_context` 取得 MCP asset URL）
- **不使用 AI 生成圖取代設計稿實際圖片**（Stitch 僅用於整頁佈局生成，不用於替換書封）
- 使用來源優先順序: ① Figma 設計稿 MCP asset → ② 外部 URL → ③ Stitch 生成
- Asset UUID 表: {列出所有從設計稿提取的 UUID + 用途}
- URL 格式: `https://www.figma.com/api/mcp/asset/{uuid}`（有效期 7 天）
- 過期處理: 對原設計稿節點重新呼叫 `get_design_context` 取得新 URL（UUID 不變）

## Badge / 標籤系統
| 狀態 | 顏色 | opacity | 尺寸(桌機) | 尺寸(手機) |
|------|------|---------|-----------|-----------|

## 文字常數
（書名、分類、作者等常用文字）

## manifest.json 當前狀態
（完整 JSON）

## 已刪除頁面（不要再建立）
- ...

## 其他專案規則
- ...
```

---

## 專案路徑結構

```
{project_root}/
├── .mcp.json              # MCP 設定（Figma + Stitch）
├── design-system.json     # DS tokens（可選）
├── figma-plugin/
│   ├── manifest.json      # → main: code.js, 多頁面路由器
│   ├── code.js            # 主檔案（路由器 + 所有頁面）
│   ├── ui.html            # 選擇頁面 UI
│   └── ...
├── scripts/               # 輔助腳本（可選）
└── output/                # Stitch 生成結果
    └── {page-name}/
        ├── design.html
        ├── design.png
        ├── screen-id.txt
        └── project-id.txt
```

---

## Figma MCP 設定

UIFlow 依賴 Figma MCP 來截圖、取結構、提取 DS tokens。有兩種連線方式：

### 方式 A：Figma API MCP（推薦，遠端）

透過 Figma 官方 MCP HTTP 端點連線，可存取任何你有權限的 Figma 檔案。

**設定 `.mcp.json`：**
```json
{
  "mcpServers": {
    "figma": {
      "type": "http",
      "url": "https://mcp.figma.com/mcp"
    }
  }
}
```

**首次使用會觸發 OAuth 認證流程（在瀏覽器中登入 Figma 授權）。**

**呼叫方式：**
工具名稱前綴為 MCP server name，如：
```
mcp__{server-id}__get_screenshot(fileKey, nodeId)
mcp__{server-id}__get_design_context(fileKey, nodeId)
mcp__{server-id}__get_variable_defs(fileKey, nodeId)
mcp__{server-id}__get_figjam(fileKey, nodeId)
mcp__{server-id}__get_metadata(fileKey, nodeId)
```

> `{server-id}` 是 Claude Code 自動分配的，每個使用者不同。首次呼叫時會看到確切的 tool name。

**⚠️ 注意事項：**
- Starter plan 有 rate limit（約 20-30 次/小時），升級 Professional 可大幅增加
- 檔案必須在 Professional team 下才能避免 rate limit
- `fileKey` 從 Figma URL 提取：`figma.com/design/{fileKey}/...`
- `nodeId` 格式：URL 中的 `node-id=225-9629` → API 中用 `225:9629`

### 方式 B：Figma Dev Mode MCP（本地）

透過 Figma 桌面版的本地 MCP Server，只能存取**當前活動分頁**的檔案。

**啟用步驟：**
1. Figma 桌面版 → 左上角 `Figma` 選單 → `Preferences`
2. 勾選 **Enable Dev Mode MCP Server**
3. （需要較新版本的 Figma 桌面版，若看不到此選項請先 Check for Updates）

**呼叫方式：**
前綴為 `mcp__Figma__`：
```
mcp__Figma__get_screenshot(nodeId)  ← 不需 fileKey
mcp__Figma__get_design_context(nodeId)
mcp__Figma__get_metadata(nodeId)
```

**⚠️ 注意事項：**
- 只能存取 Figma 桌面版**當前活動分頁**的檔案
- 不需要 fileKey（自動使用當前檔案）
- 不受 API rate limit 限制
- FigJam board 可能不支援

### 兩種方式的選擇

| | API MCP | Dev Mode MCP |
|---|---------|-------------|
| 需要 | .mcp.json + OAuth | Figma 桌面版 + Preferences 啟用 |
| 存取範圍 | 任何有權限的檔案 | 僅當前活動分頁 |
| 需要 fileKey | ✅ | ❌ |
| Rate limit | Starter 有限制 | 無限制 |
| FigJam 支援 | ✅ get_figjam | ❌ |
| 適用場景 | 批量分析、跨檔案 | 即時預覽、單檔操作 |

**建議：兩者都設好，API MCP 為主，Dev Mode MCP 作為 fallback。**

---

## Step 1：分析 Figma 設計檔（提取 DS）

### 輸入
使用者提供 Figma 設計檔 URL，如：
```
https://figma.com/design/{fileKey}/{品牌名}_UI?node-id={nodeId}
```
提取 `fileKey`、`nodeId`（格式 `XXXX:YYYYY`，URL 中的 `-` 替換為 `:`）

### 執行
```
1. get_screenshot(fileKey, nodeId)        → 看整體視覺
2. get_design_context(fileKey, nodeId)    → 取得結構/尺寸/色彩
3. get_variable_defs(fileKey, nodeId)     → 取得 design tokens
```

> 使用哪個 MCP 前綴取決於你的設定（API MCP 或 Dev Mode MCP）

### 提取圖片資源（重要！）

在分析設計稿時，**同時提取所有圖片資源**（書封、banner、icon 等）：

1. 對包含圖片的節點呼叫 `get_design_context` → 回傳的 code 中含 `https://www.figma.com/api/mcp/asset/{uuid}` 格式的圖片 URL
2. 記錄每張圖的 UUID 和用途（如 banner、書封#1、icon 等）
3. 寫入 PROJECT.md 的「Asset UUID 表」

```
⚠️ 關鍵原則：
- 書封/商品圖等核心視覺 **必須使用設計稿中的實際圖片**
- 不能用 AI 生成圖或 placeholder 取代
- MCP asset URL 有效期 7 天，過期重新呼叫 get_design_context 即可
- UUID 是永久的，只有完整 URL 會過期
```

### 提取結果
整理成 DS 物件，並寫入 PROJECT.md：

```json
{
  "colors": {
    "background": "#XXXXXX",
    "surfaceAlt": "#XXXXXX",
    "primary": "#XXXXXX",
    "white": "#FFFFFF",
    "grey300": "#E0E0E0",
    "grey500": "#9E9E9E"
  },
  "typography": {
    "family": "{字體}",
    "weights": ["Regular","Medium","Bold"]
  },
  "layout": {
    "page_width": 1440,
    "content_width": 1160,
    "margin": 140
  },
  "mobile": {
    "width": 375,
    "padding": 16,
    "inner": 343,
    "gap": 8
  },
  "radius": [4, 8, 12, 16, 24, 50],
  "spacing": "2/4/8倍數制: [2, 4, 8, 12, 16, 24, 32, 40, 48, 56, 64, 80, 96]"
}
```

---

## Step 2：讀取 PM 原型圖

### 輸入
PM 原型 URL（FigJam board 或 Figma Design file），如：
```
https://figma.com/board/{fileKey}/{品牌名}_wireframe?node-id={nodeId}
```

### 執行
```
1. get_screenshot(fileKey, nodeId)   → 看版面配置（優先 API MCP，fallback Dev Mode）
2. get_figjam(fileKey, nodeId)       → FigJam board 結構（僅 API MCP 支援）
   或 get_design_context             → design file 結構（兩種 MCP 都支援）
```

### 分析重點
從截圖中逐 section 分析，產出結構化描述：
```
頁面名稱: {頁面名}
裝置: {DESKTOP/MOBILE} ({寬度}px)

Section 清單（由上至下）:
1. {Section名} (h={高度}): {內容描述}
2. {Section名} (h={高度}): {內容描述}
...
```

**關鍵：必須仔細對照原型圖的精確佈局，不能自行發揮！**

---

## Step 3：Stitch SDK 生成設計（含真實圖片）

### 關鍵 API 模式（踩過的坑）

**初始化（從 .mcp.json 讀取 API key）：**
```javascript
import { StitchToolClient } from '@google/stitch-sdk';
const client = new StitchToolClient({
  apiKey: '{STITCH_API_KEY}' // 從 .mcp.json 或環境變數讀取，不要寫死
});
```
不要用 `new Stitch(config)` — 會報 `callTool is not a function`

**建立專案 + 生成：**
```javascript
const proj = await client.callTool('create_project', { title: '{頁面名稱}' });
const projectId = proj.name.replace('projects/', '');

const raw = await client.callTool('generate_screen_from_text', {
  projectId,
  prompt: '完整的 prompt（含 DS tokens + 佈局描述 + 圖片需求）',
  deviceType: 'DESKTOP'  // 或 'MOBILE'
});
```

**回應結構（必須遍歷找 design）：**
```javascript
let screenId = null;
for (const oc of raw.outputComponents) {
  if (oc.design && oc.design.screens && oc.design.screens.length > 0) {
    screenId = oc.design.screens[0].id.split('/').pop();
    break;
  }
}
```

**取得 HTML/截圖（必須用 get_screen）：**
```javascript
const screen = await client.callTool('get_screen', {
  projectId, screenId,
  name: 'projects/' + projectId + '/screens/' + screenId
});
const html = await (await fetch(screen.htmlCode.downloadUrl)).text();
```

---

## Step 4：產出 Figma Plugin 程式碼

詳細方法論請參考 **CBD skill**（`.claude/skills/CBD/SKILL.md`）。

### 快速流程
1. 從 Stitch HTML 提取所有圖片 URL
2. 定義 DS tokens 作為 `var C = { ... }` 常數
3. 建立 Components（放在 off-canvas），詳見 CBD skill
4. 用 Components createInstance 組裝頁面
5. 更新 manifest.json + PAGE_REGISTRY + switch case

### Plugin 開發注意事項（踩過的坑）
1. **不要用 Auto Layout + `layoutSizingVertical: "HUG"`** — section.height 回傳 0 → Plugin 掛掉
2. **不要用 `setProperties()`** — 某些情況無限掛起 → 用 `setText()` (findOne) 取代
3. **不要用 `effects` 的 `DROP_SHADOW`** — 需要完整的 blendMode, color.a, offset, radius → 容易出錯，省略 shadow
4. **用絕對定位**：每個 section 用 `var y` 累加
5. **圖片載入用 try/catch**：`figma.createImageAsync()` 可能失敗
6. **字體一定要預載**：每個 weight 都要 `loadFontAsync`
7. **Component 放在 off-canvas**：x=-700（桌機）/ x=-400（手機）
8. **最後 resize page**：`page.resize(PAGE_W, y)`

---

## Stitch MCP 工具清單

```
create_project           — 建立新專案
get_project              — 取得專案資訊
list_projects            — 列出所有專案
list_screens             — 列出專案內所有畫面
get_screen               — 取得畫面詳細（含 HTML downloadUrl + screenshot downloadUrl）
generate_screen_from_text — 從文字生成畫面
edit_screens             — 修改既有畫面
generate_variants        — 生成設計變體
```

## Figma MCP 工具清單

```
所有 Figma MCP 工具（前綴取決於你的 MCP server name）：

get_screenshot(fileKey, nodeId)       — 節點截圖（視覺參考）
get_design_context(fileKey, nodeId)   — 設計結構 + React/Tailwind 程式碼
get_variable_defs(fileKey, nodeId)    — Design tokens / 變數定義
get_figjam(fileKey, nodeId)           — FigJam board 結構（僅 API MCP）
get_metadata(fileKey, nodeId)         — 節點元資料（名稱、ID、子節點）
create_design_system_rules            — 建立設計系統規則
search_design_system                  — 搜尋設計系統
```

⚠️ **Dev Mode MCP** 的 get_screenshot / get_design_context 不需要 fileKey，自動使用當前活動檔案。

⚠️ **踩坑經驗：**
- `get_metadata` 在大節點上可能 timeout → 改用 `get_screenshot` + `get_design_context`
- `get_design_context` 可能回傳 "nothing selected" → 確認 nodeId 正確
- `get_figjam` 在 design file 上會報錯 → 僅用於 FigJam board
- API MCP 有 rate limit → Starter plan ~20次/小時，Professional 大幅增加
- 圖片 asset URL 格式：`https://www.figma.com/api/mcp/asset/{uuid}`，有效期 7 天

---

## 完整使用範例

使用者說：
> 「按照這個設計檔的 DS https://figma.com/design/xxx 和這個原型 https://figma.com/board/yyy 出一個首頁」

執行流程：
```
0. 讀取 PROJECT.md 取得專案設定（DS tokens、Component 規格、圖片規則等）
1. get_screenshot + get_design_context → 提取/驗證 DS
2. get_screenshot（原型）→ 分析每個 section 的精確佈局
3. Stitch generate_screen_from_text → 生成 HTML + 真實圖片
4. get_screen → 下載 HTML + 截圖
5. 從 HTML 提取所有圖片 URL
6. 寫 Figma Plugin JS（含 Components + 真實圖片 + 原型佈局）
7. 更新 manifest.json
8. 使用者在 Figma 跑 plugin
```

單步使用：
> 「CAD：生成一個收藏頁」→ 只跑 Step 3
> 「CBD：把設計轉 Figma」→ 只跑 Step 4
> 「分析這個設計檔」→ 只跑 Step 1
