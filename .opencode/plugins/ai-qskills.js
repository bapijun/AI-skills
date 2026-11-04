/**
 * AI-qskills plugin for OpenCode.ai
 *
 * Injects AI-qskills bootstrap context via system prompt transform.
 * Skills are discovered via OpenCode's native skill tool from symlinked directory.
 *
 * ⚠️ opencode v2 插件 API 适配（2026-11-04）：
 * V1 的命名导出 hook 写法在 v2 加载失败：
 *   "Plugin must export a default definition with an id and an effect or setup function"
 * 迁移为 V2 的 default Plugin.define：
 *   - `experimental.chat.system.transform` → `ctx.session.hook("context")`，system 元素为 { type: "text", text } 结构
 *   详见 https://opencode.ai/v2/docs/build/plugins/migrate-v1
 */

import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { Plugin } from '@opencode/plugin';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const extractAndStripFrontmatter = (content) => {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) return { frontmatter: {}, content };

  const frontmatterStr = match[1];
  const body = match[2];
  const frontmatter = {};

  for (const line of frontmatterStr.split('\n')) {
    const colonIdx = line.indexOf(':');
    if (colonIdx > 0) {
      const key = line.slice(0, colonIdx).trim();
      const value = line.slice(colonIdx + 1).trim().replace(/^["']|["']$/g, '');
      frontmatter[key] = value;
    }
  }

  return { frontmatter, content: body };
};

const skillsDir = path.resolve(__dirname, '../../skills');

const getBootstrapContent = () => {
  const skillPath = path.join(skillsDir, 'life-reply-crush', 'SKILL.md');
  if (!fs.existsSync(skillPath)) return null;

  const fullContent = fs.readFileSync(skillPath, 'utf8');
  const { content } = extractAndStripFrontmatter(fullContent);

  return `<EXTREMELY_IMPORTANT>
You have AI-qskills.

**IMPORTANT: The life-reply-crush skill content is included below. It is ALREADY LOADED - you are currently following it. Do NOT use the skill tool to load "life-reply-crush" again - that would be redundant.**

${content}
</EXTREMELY_IMPORTANT>`;
};

export default Plugin.define({
  id: 'ai-qskills',
  async setup(ctx) {
    await ctx.session.hook('context', (event) => {
      const bootstrap = getBootstrapContent();
      if (bootstrap) {
        event.system.push({ type: 'text', text: bootstrap });
      }
    });
  },
});
