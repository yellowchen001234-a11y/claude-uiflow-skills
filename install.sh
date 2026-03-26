#!/usr/bin/env bash
set -euo pipefail

# ─── UIFlow Skills 一鍵安裝 ───
# 用法：bash <(curl -sL https://raw.githubusercontent.com/yellowchen001234-a11y/claude-uiflow-skills/main/install.sh)

REPO_RAW="https://raw.githubusercontent.com/yellowchen001234-a11y/claude-uiflow-skills/main"
SKILLS_DIR=".claude/skills"

C_RESET="\033[0m"
C_GREEN="\033[32m"
C_CYAN="\033[36m"
C_YELLOW="\033[33m"
C_RED="\033[31m"

ok()   { printf "${C_GREEN}✓${C_RESET} %s\n" "$1"; }
info() { printf "${C_CYAN}→${C_RESET} %s\n" "$1"; }
warn() { printf "${C_YELLOW}⚠${C_RESET} %s\n" "$1"; }
fail() { printf "${C_RED}✗${C_RESET} %s\n" "$1"; exit 1; }

# ─── 檢查 curl ───
command -v curl >/dev/null 2>&1 || fail "需要 curl，請先安裝"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   UIFlow Skills Installer            ║"
echo "║   Figma DS → AI Design → Plugin Code ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ─── 下載 Skills ───
# 格式：repo 路徑|本地路徑（相對於 .claude/skills/）
DOWNLOADS=(
  "skills/UIFlow/SKILL.md|UIFlow/SKILL.md"
  "skills/CBD/SKILL.md|CBD/SKILL.md"
  "skills/CAD/SKILL.md|CAD/SKILL.md"
  "skills/UIFlow/PROJECT.template.md|UIFlow/PROJECT.md"
)

for entry in "${DOWNLOADS[@]}"; do
  src="${entry%%|*}"
  dest="${entry##*|}"
  target="${SKILLS_DIR}/${dest}"
  mkdir -p "$(dirname "$target")"
  # PROJECT.md 不覆蓋已有的
  if [[ "$dest" == *"PROJECT.md" ]] && [[ -f "$target" ]]; then
    info "PROJECT.md 已存在，跳過（不覆蓋你的專案設定）"
    continue
  fi
  info "下載 ${dest}..."
  if curl -sfL "${REPO_RAW}/${src}" -o "$target"; then
    ok "$(basename "$target")"
  else
    fail "下載失敗：${src}（請確認 repo 存在且 public）"
  fi
done

# ─── 建立 skills README ───
cat > "${SKILLS_DIR}/README.md" << 'SKILLSREADME'
# UIFlow 使用指南 — 快速上手

> 從 Figma 設計檔 → PM 原型圖 → AI 生成 → Figma Plugin 程式碼，端到端自動化。

## 觸發方式

| 你說的話 | 觸發的 Skill | 做什麼 |
|---------|-------------|--------|
| UIFlow 出一個首頁 | UIFlow | 全流程（分析DS→讀原型→生成→寫code） |
| 分析這個設計檔 {Figma URL} | UIFlow Step 1 | 提取 Design System |
| CAD 生成一個登入頁 | CAD | 用 Stitch AI 生成設計圖 |
| CBD 建元件 | CBD | 寫 Figma Plugin 程式碼 |

## Skills 結構

```
.claude/skills/
├── UIFlow/
│   ├── SKILL.md     ← 通用工作流（4 步驟）
│   ├── PROJECT.md   ← 專案設定（DS tokens、Components）
│   └── README.md
├── CBD/
│   └── SKILL.md     ← Component-Based Design 方法論
└── CAD/
    └── SKILL.md     ← Stitch SDK 生成方法論
```
SKILLSREADME
ok "skills/README.md"

# ─── 設定 .mcp.json（Figma MCP） ───
if [[ -f ".mcp.json" ]]; then
  info ".mcp.json 已存在，跳過"
else
  cat > .mcp.json << 'MCP'
{
  "mcpServers": {
    "figma": {
      "type": "http",
      "url": "https://mcp.figma.com/mcp"
    }
  }
}
MCP
  ok ".mcp.json（Figma MCP 已設定）"
fi

# ─── 建立 figma-plugin 骨架 ───
if [[ -d "figma-plugin" ]]; then
  info "figma-plugin/ 已存在，跳過"
else
  mkdir -p figma-plugin
  cat > figma-plugin/manifest.json << 'MANIFEST'
{
  "name": "UIFlow Plugin",
  "id": "uiflow-plugin",
  "api": "1.0.0",
  "main": "code.js",
  "ui": "ui.html",
  "editorType": ["figma"],
  "menu": [
    { "name": "📋 選擇頁面", "command": "pick" }
  ]
}
MANIFEST
  cat > figma-plugin/ui.html << 'UI'
<div id="app" style="font-family:system-ui;padding:16px">
  <h3>選擇要生成的頁面</h3>
  <div id="pages"></div>
</div>
<script>
  window.onmessage = function(e) {
    if (e.data.pluginMessage && e.data.pluginMessage.type === 'pages') {
      var container = document.getElementById('pages');
      e.data.pluginMessage.pages.forEach(function(p) {
        var btn = document.createElement('button');
        btn.textContent = p.label;
        btn.style.cssText = 'display:block;width:100%;padding:8px;margin:4px 0;cursor:pointer;border:1px solid #ddd;border-radius:4px;background:#fff';
        btn.onclick = function() { parent.postMessage({ pluginMessage: { type: 'run', command: p.cmd } }, '*'); };
        container.appendChild(btn);
      });
    }
  };
</script>
UI
  touch figma-plugin/code.js
  ok "figma-plugin/ 骨架已建立"
fi

echo ""
echo "────────────────────────────────────────"
ok "安裝完成！"
echo ""
info "下一步："
echo "  1. cd $(pwd)"
echo "  2. claude"
echo "  3. 說「分析這個設計檔 {Figma URL}」或「UIFlow 出一個首頁」"
echo ""
info "記得編輯 .claude/skills/UIFlow/PROJECT.md 填入你的專案資訊"
info "（或直接叫 Claude：「分析這個設計檔 {URL}」自動幫你填好）"
echo ""
