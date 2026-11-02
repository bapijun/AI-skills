#!/usr/bin/env zsh

# 因为会在 ~/.zshrc 中写 source ~/.config/opencode/source_opencode.sh ，而我们又经常需要在 bash/sh 脚本中执行 source .zshrc 。
# 从而容易导致 bash/sh 脚本 source .zshrc → .zshrc 又 source 了 source_opencode.sh（含 zsh 语法）→ bash 解析报错
# 解决办法：在 source_opencode.sh 头部加 $ZSH_VERSION 判断，让非 zsh shell 直接跳过，不执行内容。加在 .zshrc 的 source 行上也可以，但加在被 source 的文件自身更防漏。
[ -n "$ZSH_VERSION" ] || return 0 2>/dev/null || exit 0


# ============================================================
# Opencode 会话选择器
# 交互式选择恢复历史会话
# 支持：macOS（Intel / M 芯片）、统信 UOS
# 用法：opencode_list
# ============================================================

export DB="$HOME/.local/share/opencode/opencode.db"

# 有参数 → 透传
# 无参数 → 弹会话列表（选一个恢复 / 回车开新 / q 退出）
# 分页取数：每次只查一页（默认10条），避免一次查30条。
# ⚠️ opencode v2 数据库结构变更：session → session_v2；
#    message+part 两表合并为 session_message（type='user'，按 seq 排序，data JSON 含 $.text）
# 每条记录含3个关联子查询（首条/倒二/末条用户消息），
# 查10条 = 30次子查询，查30条 = 90次子查询。
_oc_session_q() {
    local limit=$1 offset=$2
    sqlite3 "$DB" "
        SELECT s.id || '│' ||
               COALESCE(p.name, s.directory, '?') || '│' ||
               COALESCE(s.title, '') || '│' ||
               COALESCE(substr(replace((SELECT json_extract(sm.data, '$.text')
                                         FROM session_message sm
                                         WHERE sm.session_id = s.id
                                           AND sm.type = 'user'
                                         ORDER BY sm.seq ASC
                                         LIMIT 1), char(10), ' '), 1, 40), '') || '│' ||
               COALESCE(substr(replace((SELECT json_extract(sm.data, '$.text')
                                         FROM session_message sm
                                         WHERE sm.session_id = s.id
                                           AND sm.type = 'user'
                                         ORDER BY sm.seq DESC
                                         LIMIT 1 OFFSET 1), char(10), ' '), 1, 40), '') || '│' ||
               COALESCE(substr(replace((SELECT json_extract(sm.data, '$.text')
                                         FROM session_message sm
                                         WHERE sm.session_id = s.id
                                           AND sm.type = 'user'
                                         ORDER BY sm.seq DESC
                                         LIMIT 1), char(10), ' '), 1, 40), '')
        FROM session_v2 s
        LEFT JOIN project p ON s.project_id = p.id
        ORDER BY s.time_updated DESC LIMIT $limit OFFSET $offset;
    "
}

_oc_session_count() {
    sqlite3 "$DB" "SELECT COUNT(*) FROM session_v2;"
}

opencode_list() {
    if [ $# -gt 0 ]; then
        command opencode "$@"
        return
    fi

    local sid
    local per_page=10
    local page=1
    local total=$(_oc_session_count)
    local total_pages=$(( (total + per_page - 1) / per_page ))

    while true; do
        local offset=$(( (page - 1) * per_page ))
        local rows
        local page_count
        if [ -n "$ZSH_VERSION" ]; then
            rows=("${(@f)$(_oc_session_q $per_page $offset)}")
            page_count=${#rows[@]}
        else
            rows=()
            while IFS= read -r line; do rows+=("$line"); done < <(_oc_session_q $per_page $offset)
            page_count=${#rows[@]}
            rows=("" "${rows[@]}")
        fi

        echo "=== 最近的会话 (第${page}/${total_pages}页，共${total}条) ==="
        for ((i=page_count; i>=1; i--)); do
            local row="${rows[$i]}"
            local proj=$(echo "$row" | awk -F'│' '{print $2}')
            local ttl=$(echo "$row" | awk -F'│' '{print $3}')
            local fin=$(echo "$row" | awk -F'│' '{print $4}')
            local dao=$(echo "$row" | awk -F'│' '{print $5}')
            local lin=$(echo "$row" | awk -F'│' '{print $6}')
            printf "  %2d) \033[1;36m[%s]\033[0m \033[1;32m%s\033[0m\n" "$i" "${proj:-?}" "${ttl:-}"
            [ -n "$fin" ] && printf "      ├─ 输入: %s\n" "$fin"
            [ -n "$dao" ] && printf "      ├─ 倒二: %s\n" "$dao"
            [ -n "$lin" ] && printf "      └─ 最后: %s\n" "$lin"
        done

        local prompt="输入序号恢复"
        [[ $page -lt $total_pages ]] && prompt="${prompt}，\033[33mn\033[35m=下一页"
        [[ $page -gt 1 ]] && prompt="${prompt}，\033[33mp\033[35m=上一页"
        prompt="${prompt}，直接回车=新会话，\033[33mq\033[35m=退出: "
        echo -ne "\033[35m${prompt}\033[0m"
        read -r reply

        case "$reply" in
            q|Q) return ;;
            n|N) [[ $page -lt $total_pages ]] && ((page++)) && continue ;;
            p|P) [[ $page -gt 1 ]] && ((page--)) && continue ;;
            '') break ;;
            *)
                if [[ "$reply" =~ ^[0-9]+$ ]] && [ "$reply" -ge 1 ] && [ "$reply" -le $page_count ]; then
                    sid=$(echo "${rows[$reply]}" | awk -F'│' '{print $1}') && break
                fi
                ;;
        esac
    done

    if [ -n "$sid" ]; then
        command opencode -s "$sid"
    else
        command opencode
    fi
}
