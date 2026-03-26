---
name: CAD
description: "Computer-Aided Design — Stitch SDK 生成 UI 設計。這是 UIFlow 的 Step 3 子流程。觸發詞：「生成設計」「stitch」「CAD」「產出UI」「generate design」「generate screen」「設計變體」「用AI產UI」。觸發後請同時參考 UIFlow skill 的 Step 3 完整說明。"
---

# CAD — Stitch SDK 生成設計

這是 **UIFlow Step 3** 的獨立觸發入口。通用的 Stitch SDK 使用方法論，適用於任何 UI 迭代專案。

**專案特定的 DS tokens、圖片規則等，請查閱 PROJECT.md。**

---

## 初始化

**API key 從 .mcp.json 或環境變數讀取，不要寫死在程式碼中。**

```javascript
import { StitchToolClient } from '@google/stitch-sdk';

// 方式 1: 從 .mcp.json 讀取（推薦）
import { readFileSync } from 'fs';
const mcpConfig = JSON.parse(readFileSync('.mcp.json', 'utf8'));
const apiKey = mcpConfig.mcpServers?.stitch?.env?.STITCH_API_KEY || '{STITCH_API_KEY}';

// 方式 2: 從環境變數讀取
// const apiKey = process.env.STITCH_API_KEY;

const client = new StitchToolClient({ apiKey });
```

**不要用 `new Stitch(config)`** — 會報 `callTool is not a function`

---

## 生成流程

```javascript
// 1. 建專案
const proj = await client.callTool('create_project', { title: '{頁面名稱}' });
const projectId = proj.name.replace('projects/', '');

// 2. 生成畫面
const raw = await client.callTool('generate_screen_from_text', {
  projectId,
  prompt: '完整的 prompt（含 DS tokens + 佈局描述 + 圖片需求）',
  deviceType: 'DESKTOP'  // 或 'MOBILE'
});

// 3. 找 screenId（⚠️ 必須遍歷 outputComponents）
let screenId;
for (const oc of raw.outputComponents) {
  if (oc.design?.screens?.length > 0) {
    screenId = oc.design.screens[0].id.split('/').pop();
    break;
  }
}

// 4. 下載 HTML + 截圖（⚠️ 必須用 get_screen）
const screen = await client.callTool('get_screen', {
  projectId, screenId,
  name: 'projects/' + projectId + '/screens/' + screenId
});
const html = await (await fetch(screen.htmlCode.downloadUrl)).text();
const img = Buffer.from(await (await fetch(screen.screenshot.downloadUrl)).arrayBuffer());
```

---

## 踩坑筆記

| 問題 | 解法 |
|------|------|
| `callTool is not a function` | 用 `StitchToolClient`，不要用 `new Stitch()` |
| screenId 取不到 | 遍歷 `raw.outputComponents`，找有 `design.screens` 的項目 |
| HTML 取不到 | 必須呼叫 `get_screen` 拿 `downloadUrl`，不能直接從 generate 結果取 |
| 圖片 URL 過期 | downloadUrl 有效期有限，需及時下載 |

---

## 可用工具

| 工具 | 用途 |
|------|------|
| `create_project` | 建立新專案 |
| `get_project` | 取得專案資訊 |
| `list_projects` | 列出所有專案 |
| `list_screens` | 列出專案內所有畫面 |
| `get_screen` | 取得畫面詳細（含 HTML + screenshot downloadUrl） |
| `generate_screen_from_text` | 從文字 prompt 生成畫面 |
| `edit_screens` | 修改既有畫面 |
| `generate_variants` | 生成設計變體 |

---

## 輸出目錄

```
{project_root}/output/{page-name}/
├── design.html       # 生成的 HTML
├── design.png        # 截圖
├── screen-id.txt     # screenId（方便後續 edit_screens）
└── project-id.txt    # projectId
```

---

## Prompt 撰寫建議

好的 Stitch prompt 應包含：

1. **頁面用途**：「這是一個{品牌名}的{頁面類型}」
2. **DS tokens**：背景色、主色、字體、圓角等
3. **佈局結構**：每個 section 的精確尺寸和內容
4. **圖片需求**：需要什麼樣的圖片（書封、頭像、Banner 等）
5. **裝置類型**：DESKTOP (1440px) 或 MOBILE (375px)

```
範例 prompt 結構:
"Design a {頁面類型} for {品牌名}.
Background: {bg色}. Primary: {主色}. Font: {字體}.
Layout (top to bottom):
1. NavBar (h=64): ...
2. Banner (h=269): ...
3. Card Grid: 6 cards, 180x310 each, gap=16
...
Use realistic {類型} cover images.
Device: DESKTOP 1440px."
```
