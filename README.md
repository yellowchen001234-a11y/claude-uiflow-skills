# UIFlow Skills for Claude Code

從 Figma 設計檔 → PM 原型圖 → AI 生成 → Figma Plugin 程式碼，端到端自動化。

## 一鍵安裝

```bash
bash <(curl -sL https://raw.githubusercontent.com/yellowchen001234-a11y/claude-uiflow-skills/main/install.sh)
```

> 在你的專案目錄下執行。自動裝好 Skills + 設好 Figma MCP + 建好 Plugin 骨架。

## 使用方式

裝完後啟動 Claude Code，直接說話就能用：

| 你說的話 | 觸發的 Skill | 做什麼 |
|---------|-------------|--------|
| `UIFlow 出一個首頁` | UIFlow | 全流程（分析DS→讀原型→生成→寫code） |
| `分析這個設計檔 {Figma URL}` | UIFlow Step 1 | 提取 Design System |
| `CAD 生成一個登入頁` | CAD | 用 Stitch AI 生成設計圖 |
| `CBD 建元件` | CBD | 寫 Figma Plugin 程式碼 |

## 前置需求

| 項目 | 必要性 | 說明 |
|------|--------|------|
| [Claude Code](https://claude.com/claude-code) | 必要 | `npm i -g @anthropic-ai/claude-code` |
| [Figma](https://figma.com) 帳號 | 必要 | Professional plan 建議 |
| Google Stitch SDK | 選用 | Step 3（CAD）需要 |

## 安裝後的檔案結構

```
your-project/
├── .claude/skills/
│   ├── UIFlow/
│   │   ├── SKILL.md       ← 通用工作流（4 步驟）
│   │   └── PROJECT.md     ← 你的專案設定（需自己填）
│   ├── CBD/
│   │   └── SKILL.md       ← Component-Based Design 方法論
│   └── CAD/
│       └── SKILL.md       ← Stitch SDK 生成方法論
├── .mcp.json               ← Figma MCP 設定
└── figma-plugin/
    ├── manifest.json
    ├── code.js
    └── ui.html
```

## 詳細文件

安裝後看 `.claude/skills/UIFlow/SKILL.md` 取得完整使用說明。
