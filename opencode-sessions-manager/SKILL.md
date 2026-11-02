---
name: opencode-sessions-manager
version: 0.0.3
description: |
  交互式 opencode 会话选择器 - 分页浏览恢复历史会话
  触发场景：
  - 用户输入"配置opencode会话管理"
  - 用户说"帮我设置 opencode 的会话恢复功能"
  - 用户在新机器上要配置会话选择器
---

# Opencode 会话选择器

交互式会话选择器：打开终端输入 `opencode_list` 即可分页浏览历史会话并选择恢复。不覆盖原生命令，`opencode` 行为不受影响。

## 触发条件

用户需要配置 opencode 会话自动记录和恢复功能时触发：
- "配置opencode会话管理"
- "帮我设置 opencode 的会话恢复功能"
- 新机器上需要配置 opencode 会话管理

## 安装步骤

### 1. 复制脚本文件

将 [`scripts/source_opencode.sh`](scripts/source_opencode.sh) 复制到 `~/.config/opencode/source_opencode.sh`：

```bash
mkdir -p ~/.config/opencode
cp scripts/source_opencode.sh ~/.config/opencode/source_opencode.sh
```

### 2. 自动配置 shell

自动检测当前 shell，选择对应的 rc 文件并写入 source 行：

```bash
case "$SHELL" in
    */zsh) RC_FILE="$HOME/.zshrc" ;;
    */bash) RC_FILE="$HOME/.bashrc" ;;
    *) echo "错误：不支持 Shell: $SHELL"; exit 1 ;;
esac

if [ ! -f "$RC_FILE" ]; then
    echo "错误：$RC_FILE 不存在"
    exit 1
fi

echo "source ~/.config/opencode/source_opencode.sh" >> "$RC_FILE"
echo "✅ 已添加到 $RC_FILE"
```

### 3. 生效

```bash
source "$RC_FILE"
```

## 使用说明

| 命令 | 效果 |
|------|------|
| `opencode_list` | 弹会话列表（显示项目名、标题、首条/倒二/末条用户输入），最新会话在最底部，1 号位离输入框最近 |
| `opencode web` | 原样透传 |
| `opencode -s ses_xxx` | 原样透传 |
| `opencode --help` | 原样透传 |

## 依赖

- **sqlite3**：macOS 自带；统信 UOS 需 `sudo apt install sqlite3`

## 卸载步骤

1. 删除脚本文件：`rm ~/.config/opencode/source_opencode.sh`
2. 从 rc 文件中移除 `source ~/.config/opencode/source_opencode.sh` 行
3. 重新加载：`source ~/.bashrc` 或 `source ~/.zshrc`

## 参考博客

[dvlproadHexo的《AI-③opencode会话管理》](https://dvlproad.github.io/AI/AI-③opencode会话管理/)

## 版本记录

### 0.0.3 (2026-11-02): 适配 opencode v2

- opencode v2 数据库结构变更：`session` → `session_v2`；`message`+`part` 两表合并为 `session_message`（`type='user'`，按 `seq` 排序，`data` JSON 的 `$.text` 直接是输入内容）
- 已在 v2.1.4 上实测通过；不兼容 v1 及更早数据库

### 0.0.2 (2026-05-20): 改进版本

- 脚本兼容 bash + zsh（1 处 if/else + 数组补空元素技巧）
- 安装步骤自动检测 `$SHELL` 选择 rc 文件

### 0.0.1 (2026-05-18): 初始版本
