#!/bin/bash
# 实时监控 VideoForge 转码状态（每10秒刷新）

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔥 VideoForge 实时监控"
echo "每10秒自动刷新，按 Ctrl+C 退出"
echo ""

# 使用 watch 命令实时刷新
if command -v watch &> /dev/null; then
    watch -n 10 "$SCRIPT_DIR/check_status.sh"
else
    # macOS 没有 watch，使用循环
    while true; do
        clear
        "$SCRIPT_DIR/check_status.sh"
        echo ""
        echo "⏱️  下次刷新: 10秒后... (按 Ctrl+C 退出)"
        sleep 10
    done
fi
