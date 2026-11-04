# Installing AI-qskills for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

Add AI-qskills to the `plugins` array in your `opencode.json` (global or project-level):

```json
{
  "plugins": ["ai-qskills@git+https://github.com/[你的github用户名]/AI-qskills.git"]
}
```

Restart OpenCode. That's it — the plugin auto-installs and registers all skills.

## Usage

AI-qskills skills will be automatically triggered based on their descriptions in SKILL.md files.

To manually use a skill:

```
use skill tool to load ai-qskills/life-reply-crush
```

## Available Skills

| Skill | 描述 |
|-------|------|
| life-reply-crush | Generate fun, flirty replies to crush messages |
| opencode-sessions-manager | opencode 会话自动记录与恢复 — 自动保存会话 ID、交互式会话选择器 |
| record-to-skill | 创建和完善 Skill |
| record-router | 内容分发路由 — 判断内容类型，路由到对应 Skill |
| record-to-hexo-blog | 将内容写入 hexo 博客 |
| record-to-script-repo | 将脚本分类到正确仓库和子目录 |

## Updating

AI-qskills updates automatically when you restart OpenCode.

To pin a specific version:

```json
{
  "plugins": ["ai-qskills@git+https://github.com/[你的github用户名]/AI-qskills.git#v1.0.0"]
}
```