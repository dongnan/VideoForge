#!/bin/bash
# 监控 VideoForge 转码进度（动态路径，零硬编码）

# 颜色
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'; NC='\033[0m'

# 运行时获取脚本目录与日志目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
TODAY=$(date +%Y%m%d)
LOG_FILE="$LOG_DIR/videoforge_${TODAY}.log"

echo "🔥 VideoForge 转码进度监控"
echo "================================================"
echo -e "日志目录: ${CYAN}$LOG_DIR${NC}"
echo -e "日志文件: ${CYAN}$LOG_FILE${NC}"
echo "按 Ctrl+C 退出监控"
echo "================================================"
echo ""

# 如果今天的日志不存在，提示最近日志
if [ ! -f "$LOG_FILE" ]; then
  LATEST_LOG=$(find "$LOG_DIR" -name "videoforge_*.log" -type f -exec ls -t {} + 2>/dev/null | head -1)
  if [ -n "$LATEST_LOG" ]; then
    echo -e "${YELLOW}⚠️ 今日日志未找到，切换到最近日志:${NC} $LATEST_LOG"
    LOG_FILE="$LATEST_LOG"
  else
    echo -e "${YELLOW}等待日志文件创建...${NC}"
  fi
fi

# 实时显示最新日志
if [ -n "$LOG_FILE" ]; then
  tail -f "$LOG_FILE" 2>/dev/null || echo -e "${YELLOW}等待日志文件创建...${NC}"
else
  echo -e "${YELLOW}未检测到可用日志文件${NC}"
fi
