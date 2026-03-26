---
name: CBD
description: "Component-Based Design — Figma Plugin 程式碼產出。這是 UIFlow 的 Step 4 子流程。觸發詞：「建元件」「component」「CBD」「auto layout」「轉Figma」「Figma plugin」「建 Component」「figma-plugin」「產Figma程式碼」。觸發後請同時參考 UIFlow skill 的 Step 4 完整說明。"
---

# CBD — Component-Based Design（Figma Plugin 程式碼產出）

這是 **UIFlow Step 4** 的獨立觸發入口。通用的 Figma Plugin Component 開發方法論，適用於任何 UI 迭代專案。

**專案特定的 Component 規格、off-canvas 定位表、圖片規則等，請查閱 PROJECT.md。**

---

## Plugin 結構（code.js 路由器模式）

```javascript
// 1. 共用 DS tokens (var C = { bg, surfaceAlt, primary, ... })
//    → 從 PROJECT.md 的 Design System Tokens 填入
// 2. 共用工具函式 (rgb, fill, txt, box, setText, setImage, loadImages)
// 3. placeRight() — 放置新 frame 在畫布最右邊
// 4. 共用元件（如 NavBar）
// 5. 路由器 (PAGE_REGISTRY + figma.command switch)
// 6. 各頁面 buildXxx() 函式（含 Components）
```

---

## 避坑指南（通用經驗）

| 問題 | 原因 | 解法 |
|------|------|------|
| Plugin 掛起不動 | Auto Layout HUG + section.height=0 | **用絕對定位** |
| Plugin 掛起不動 | `setProperties()` 某些情況無限迴圈 | **用 `setText()` (findOne)** |
| effects 格式錯誤 | DROP_SHADOW 需完整 blendMode/color.a/offset | **省略 shadow，不用 effects** |
| 圖片不顯示 | URL 過期或網路問題 | **try/catch + fallback solid fill** |
| 字體錯誤 | 未預載 font weight | **每個 weight 都要 loadFontAsync** |
| Component 找不到 | 放在頁面內被蓋住 | **放在 off-canvas (x=-700/x=-400)** |
| Component 互相覆蓋 | 多個 Component 同一位置 | **staggered y 值** |

---

## Component 建立模式

### 1. 建立 Component
```javascript
var MyCard = figma.createComponent();
MyCard.name = "MyCard";
MyCard.resize(180, 310);
noFill(MyCard);
MyCard.clipsContent = false;
```

### 2. 加入子元素
```javascript
var cover = box("CardCover", 180, 250, C.surfaceHigh, 8);
MyCard.appendChild(cover);

var title = txt("CardTitle", "預設文字", 13, 700, C.white, 180);
title.x = 0; title.y = 258;
MyCard.appendChild(title);
```

### 3. Off-canvas 定位（不要蓋住頁面！）
```javascript
MyCard.x = -700; MyCard.y = 0;   // 桌機 Components
// 或
MyCard.x = -400; MyCard.y = 0;   // 手機 Components
```

### 4. 使用 Instance
```javascript
var inst = MyCard.createInstance();
inst.x = 140; inst.y = 200;
page.appendChild(inst);
```

### 5. 設定 Instance 內容
```javascript
setText(inst, "CardTitle", "實際標題");
setImage(inst, "CardCover", imageHash);
```

---

## Off-canvas 定位策略

- **桌機 Components**: `x = -700`，y 值 staggered（避免重疊）
- **手機 Components**: `x = -400`，y 值 staggered
- **新增 Component 時**：桌機 y 從最後一個 + 其高度 + 間距開始；手機同理

**具體的 Component 列表和 y 值定位，請查閱 PROJECT.md 的「Component 規格表」。**

---

## 圖片載入模式

```javascript
var imageHashes = [];
for (var i = 0; i < IMAGES.length; i++) {
  try {
    var img = await figma.createImageAsync(IMAGES[i]);
    imageHashes.push(img.hash);
  } catch(e) {
    imageHashes.push(null);
  }
}
```

**圖片來源規則（MCP asset / Stitch 生成 / 外部 URL）請查閱 PROJECT.md。**

---

## setText / setImage 工具函式

```javascript
function setText(inst, childName, text) {
  var node = inst.findOne(function(n) {
    return n.name === childName && n.type === "TEXT";
  });
  if (node) node.characters = text;
}

function setImage(inst, childName, hash) {
  if (!hash) return;
  var node = inst.findOne(function(n) {
    return n.name === childName;
  });
  if (node) node.fills = [{ type: "IMAGE", scaleMode: "FILL", imageHash: hash }];
}
```

---

## manifest.json 路由器架構

新增頁面時需同步更新 3 個地方：

1. **`manifest.json`** → menu 加入新項目
```json
{ "name": "{emoji} {頁面名}", "command": "{page-command}" }
```

2. **`code.js` → PAGE_REGISTRY** 加入頁面資訊
```javascript
{ cmd: "{page-command}", label: "{頁面名}", fn: "buildXxx" }
```

3. **`code.js` → loadAndRun switch** 加入 case
```javascript
case "{page-command}": await buildXxx(page); break;
```

4. **`code.js`** → 實作 `buildXxx()` 函式

---

## Component 命名規範

- 桌機: `Desktop{功能}Card` / `Desktop{功能}Item`（例：`DesktopBookCard`）
- 手機: `Mobile{功能}Card` / `Mobile{功能}Item`（例：`MobileBookCard`）
- 功能元件: `{功能}{類型}`（例：`ReaderFloatingPill`、`CommentCard`、`ChapterRow`）
- 子元素: `Card{部位}`（例：`CardCover`、`CardTitle`、`CardMeta`、`CardBadge`）

---

## 頁面建構模式

```javascript
async function buildXxx(page) {
  // 1. 載入字體
  await figma.loadFontAsync({ family: "{字體}", style: "Regular" });
  await figma.loadFontAsync({ family: "{字體}", style: "Bold" });
  // ...每個用到的 weight 都要載

  // 2. 載入圖片（try/catch）
  var imageHashes = await loadImages(IMAGES);

  // 3. 建立 Components（off-canvas）
  var MyCard = figma.createComponent();
  // ... 設定 Component 結構
  MyCard.x = -700; MyCard.y = 0;

  // 4. 建立頁面 frame
  var frame = figma.createFrame();
  frame.name = "{頁面名}";
  frame.resize(PAGE_W, 1);
  frame.fills = [fill(C.bg)];
  page.appendChild(frame);

  // 5. 絕對定位累加 y
  var y = 0;

  // Section 1
  var section1 = box("Section1", PAGE_W, 64, C.surfaceAlt, 0);
  section1.y = y; frame.appendChild(section1);
  y += 64;

  // Section 2 — 用 Component instances
  for (var i = 0; i < 6; i++) {
    var inst = MyCard.createInstance();
    inst.x = MARGIN + i * (CARD_W + GAP);
    inst.y = y;
    frame.appendChild(inst);
    setText(inst, "CardTitle", titles[i]);
    setImage(inst, "CardCover", imageHashes[i]);
  }
  y += CARD_H + SECTION_GAP;

  // 6. Resize
  frame.resize(PAGE_W, y);

  // 7. 放置
  placeRight(page, frame);
}
```
