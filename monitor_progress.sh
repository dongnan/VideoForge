#!/bin/bash
# 监控 VideoForge 转码进度

LOG_FILE="/Volumes/Disk0/CodeBuddy/VideoForge/logs/videoforge_$(date +%Y%m%d).log"

echo "🔥 VideoForge 转码进度监控"
echo "================================================"
echo "日志文件: $LOG_FILE"
echo "按 Ctrl+C 退出监控"
echo "================================================"
echo ""

# 实时显示最新日志
tail -f "$LOG_FILE" 2>/dev/null || echo "等待日志文件创建..."
