---
name: opencode-sessions-manager
version: 0.0.6
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
| 列表内 `d` | 批量删除会话：单个 `3` / 多个 `3 5 8` / 区间 `2-5`（含两端）/ 混合 `2-5 8`，空格分隔，**仅当前页有效**；y/N 统一确认后逐条删除，删完自动刷新。**v1 / v2 均支持**：v2 走官方 `opencode session delete`，v1 走 SQL 级联（无自动备份，删前有 ⚠️ 提醒） |
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

### 0.0.6 (2026-11-11): v1 也支持删除（SQL 级联）

- `d=删除` 在 v1 / v2 环境都显示；v2 仍走官方 `opencode session delete`（不变），v1 新增 SQL 实现
- **运行时表结构自省**（不硬编码 v1 表名，兼容 v1 各小版本差异）：含 `session_id` 列的表 → 一级子表（如 `message`）；含 `message_id` 列的表 → 二级子表（如 `part`）；`session` 表有 `parent_id` 列 → 启用递归。结果批内缓存，同一批次只扫一次
- **递归删子代**：与 v2 官方行为对齐。`parent_id` 存在时用 `WITH RECURSIVE` 收集全部后代会话一并删除；无该列的老 v1 库只删自身。递归用 `UNION`（去重）而非 `UNION ALL`——实测 `parent_id` 若有环，`UNION ALL` 会无限递归挂死
- **单事务 + `.bail on` + `.timeout 3000`**：任一语句失败立即中止，未 COMMIT 的事务随连接关闭自动回滚。实测不加 `.bail on` 时 sqlite3 会继续执行后续语句并 COMMIT，即使退出码非零数据也已部分提交（“删一半还报成功”）
- 父子同批重叠过滤（v1/v2 共用）：批内某会话的祖先也在本批里时，该子会话从执行列表剔除，预览标注 `(级联) … 将随父会话一起删除`，不计入确认数量——避免“删父时代码已级联删掉子、轮到子时找不到”造成假失败统计
- v1 无官方命令兜底、也无自动备份，确认行前额外打印 `⚠️ v1 为直接改库且无自动备份，删除不可逆`
- sid 拼进 SQL 前做单引号翻倍转义；`PRAGMA busy_timeout` 改用 `.timeout`（前者会把 `3000` 打进输出，污染失败原因）
- fixture 实测覆盖：三层嵌套（父→子→孙）级联、环数据 0 秒终止、无 `parent_id` 列只删自身、强制失败完整回滚且报错干净、同批父子重叠过滤、非法输入整批拒绝、v2 回归无变化
- 已知边界：v1 **无自动备份**（与 v2 交互一致，风险自担）；统信 UOS 真机上的库锁行为未验证；建议首次使用先拿一条废弃会话实测

### 0.0.5 (2026-11-11): 批量删除会话（多个 / 区间）

- `opencode_list` 提示行新增 `d=删除`（仅 v2 环境显示；本版删除只支持 v2，v1 仅保留列表浏览）
- 输入语法：单个 `3` / 多个 `3 5 8` / 区间 `2-5`（含两端，倒序自动纠正）/ 混合 `2-5 8`；空格分隔，仅当前页有效（每批 ≤ 页大小，与选号恢复的页内语义一致）
- 严格校验：任何非法 / 越界 token **整批拒绝**并提示原因，绝不部分执行；按 sid 去重
- 序号输入禁止前导零（zsh 数组下标按八进制解析，`010` 会错位到第 8 行导致误删）；非法输入整批拒绝
- 修复历史遗留 bug：`while` 循环里重复 `local rows` / `local page_count`（以及再次进入 `d` 分支时的 `local del_reply ...`）会因 zsh `typeset_silent` 默认关闭而**打印旧值**，表现为第 2 页起每翻一页/每次按 `d` 都喷一坨 `rows=( ... ) page_count=10` 脏数据 → 函数内加 `setopt localoptions typeset_silent` 解决
- 删除统一走官方 `opencode session delete`（自动级联子会话、事件表、session_message/inbox/pending），不手写 SQL
- 删除前列出会话清单 + `y/N` 一次性确认；删除后刷新当前页并停留，页码越界自动回退，删空整个库则直接开新会话
- 已知边界：删除其他终端正活跃的会话行为未验证；分隔符仅支持空格

### 0.0.4 (2026-11-02): v1/v2 版本自适应

- 惰性探测：首次调用时查 `sqlite_master` 有无 `session_v2` 表（比解析 `opencode --version` 更可靠——查的就是 DB，判断依据与数据本身绑定），结果缓存到 `_OC_DB_V2`
- `_OC_DB_V2=1` 走 v2 SQL（`session_v2`/`session_message`），`=0` 走 v1 SQL（0.0.2 原版 `session`/`message`/`part`），同一份脚本兼容两代数据库
- DB 文件不存在时短路返回空，`opencode_list` 总数 0 时直接开新会话，不再报 `no such table`
- 已验证：v2 真实库 / 假 v1 库 / 无 DB 三种场景

### 0.0.3 (2026-11-02): 适配 opencode v2

- opencode v2 数据库结构变更：`session` → `session_v2`；`message`+`part` 两表合并为 `session_message`（`type='user'`，按 `seq` 排序，`data` JSON 的 `$.text` 直接是输入内容）
- 已在 v2.1.4 上实测通过；不兼容 v1 及更早数据库

### 0.0.2 (2026-05-20): 改进版本

- 脚本兼容 bash + zsh（1 处 if/else + 数组补空元素技巧）
- 安装步骤自动检测 `$SHELL` 选择 rc 文件

### 0.0.1 (2026-05-18): 初始版本
