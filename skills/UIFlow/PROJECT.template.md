# {品牌名} — 專案設定檔

## 基本資訊
- 品牌名稱: {品牌名}
- 設計檔 URL: {Figma 設計檔 URL}
- 原型圖 URL: {Figma 原型圖 URL}

---

## Design System Tokens

### 色彩
| Token | 值 | 用途 |
|-------|-----|------|
| background | #XXXXXX | 頁面底色 |
| primary | #XXXXXX | 主色/強調色 |
| white | #FFFFFF | 白色文字 |

### 字體
- Family: {字體名稱}
- Weights: `Regular (400)`, `Medium (500)`, `Bold (700)`

### 佈局常數
- 桌機: page_width=`1440`, content_width=`1160`, margin=`140`
- 手機: width=`375`, padding=`16`, inner=`343`, gap=`8`

### 圓角
- `[4, 8, 12, 16, 24, 50]`

### 間距
- 2/4/8倍數制: `[2, 4, 8, 12, 16, 24, 32, 40, 48, 56, 64, 80, 96]`

---

## Component 規格表
| Component | 尺寸 | Off-canvas | 用途 | 排列 |
|-----------|------|------------|------|------|
| DesktopBookCard | 180×310 | x=-700, y=0 | 桌機卡片 | 6張/排，gap=16 |
| MobileBookCard | 109×193 | x=-400, y=0 | 手機卡片 | 3張/排，gap=8 |

---

## 圖片資源規則
- **書封/商品圖等核心視覺一律從 Figma 設計稿提取**（透過 `get_design_context` 取得 MCP asset URL）
- **不使用 AI 生成圖取代設計稿實際圖片**
- 使用來源優先順序: ① Figma 設計稿 MCP asset → ② 外部 URL → ③ Stitch 生成
- URL 格式: `https://www.figma.com/api/mcp/asset/{uuid}`（有效期 7 天）

### Asset UUID 表
| 用途 | UUID | 備註 |
|------|------|------|
| banner | {uuid} | 首頁 banner |

---

## manifest.json 當前狀態
```json
{
  "name": "{插件名}",
  "id": "{plugin-id}",
  "api": "1.0.0",
  "main": "code.js",
  "ui": "ui.html",
  "editorType": ["figma"],
  "menu": [
    { "name": "📋 選擇頁面", "command": "pick" }
  ]
}
```

---

## 已刪除頁面（不要再建立）
- （無）

## 其他專案規則
- （無）
