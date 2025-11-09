#!/bin/bash
# 检查 VideoForge 转码状态（动态获取，零硬编码）

# 颜色
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

# 运行时获取脚本目录与日志目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
TODAY=$(date +%Y%m%d)
LOG_FILE="$LOG_DIR/videoforge_${TODAY}.log"

# 通过脚本名匹配查询转码任务进程
PYTHON_PID=$(pgrep -f "python.*videoforge.py transcode" | head -1)

echo "🔥 VideoForge 转码状态检查"
echo "================================================"

# 进程状态
if [ -n "$PYTHON_PID" ]; then
  echo -e "${GREEN}✅ 转码进程运行中${NC}"
  # 进程详情
  ps -p $PYTHON_PID -o pid,pcpu,pmem,etime,args | tail -1 | awk '{print "PID:"$1" | CPU:"$2"% | MEM:"$3"% | 运行:"$4}'
  
  # 从命令行提取参数
  FULL_CMD=$(ps -p $PYTHON_PID -o command=)
  SOURCE_DIR=$(echo "$FULL_CMD" | sed -n 's/.*transcode[[:space:]]\+\([^[:space:]]*\).*/\1/p' | tr -d '"')
  OUTPUT_DIR=$(echo "$FULL_CMD" | sed -n 's/.*-o[[:space:]]\+\([^[:space:]]*\).*/\1/p' | tr -d '"')
  if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR=$(echo "$FULL_CMD" | sed -n 's/.*--output[[:space:]]\+\([^[:space:]]*\).*/\1/p' | tr -d '"')
  fi
  CODEC=$(echo "$FULL_CMD" | sed -n 's/.*--codec[[:space:]]\+\([^[:space:]]*\).*/\1/p')
  QUALITY=$(echo "$FULL_CMD" | sed -n 's/.*--quality[[:space:]]\+\([^[:space:]]*\).*/\1/p')
  SMART_SKIP=$(echo "$FULL_CMD" | grep -q "--smart-skip" && echo "启用" || echo "未启用")
  
  echo -e "${YELLOW}配置:${NC}"
  [ -n "$SOURCE_DIR" ] && echo "  源目录: $SOURCE_DIR"
  [ -n "$OUTPUT_DIR" ] && echo "  输出目录: $OUTPUT_DIR"
  [ -n "$CODEC" ] && echo "  编码: $CODEC"
  [ -n "$QUALITY" ] && echo "  质量: $QUALITY"
  echo "  智能跳过: $SMART_SKIP"
  
  # FFmpeg 子进程
  FFMPEG_PID=$(pgrep -P $PYTHON_PID ffmpeg 2>/dev/null | head -1)
  if [ -n "$FFMPEG_PID" ]; then
    echo ""
    echo -e "${GREEN}🎬 FFmpeg 进程: PID $FFMPEG_PID${NC}"
    ps -p $FFMPEG_PID -o pid,pcpu,pmem,etime | tail -1 | awk '{print "   PID:"$1" | CPU:"$2"% | MEM:"$3"% | 运行:"$4}'
    CURRENT_FILE=$(ps -p $FFMPEG_PID -o args= | grep -o -- '-i [^[:space:]]*' | cut -d' ' -f2 | tr -d '"')
    if [ -n "$CURRENT_FILE" ]; then
      echo -e "${CYAN}   正在处理: $(basename "$CURRENT_FILE")${NC}"
      if [ -f "$CURRENT_FILE" ]; then
        ls -lh "$CURRENT_FILE" | awk '{print "   原始大小: "$5}'
      fi
      if [ -n "$OUTPUT_DIR" ] && [ -n "$SOURCE_DIR" ]; then
        RELATIVE_PATH="${CURRENT_FILE#$SOURCE_DIR/}"
        OUTPUT_FILE="$OUTPUT_DIR/$RELATIVE_PATH"
        [ -f "$OUTPUT_FILE" ] && ls -lh "$OUTPUT_FILE" | awk '{print "   已输出: "$5}'
      fi
    fi
  else
    echo -e "${YELLOW}ℹ️  FFmpeg 当前未运行（可能在智能跳过或队列等待）${NC}"
  fi
else
  echo -e "${RED}❌ 转码进程未运行${NC}"
fi

echo ""
echo "================================================"
echo "📊 处理统计（从日志）"
echo "================================================"

if [ -f "$LOG_FILE" ]; then
  TOTAL_FILES=$(grep '找到.*个视频文件' "$LOG_FILE" | tail -1 | grep -o '[0-9]\+' | head -1)
  PROCESSED=$(grep -c '处理 \[' "$LOG_FILE")
  COMPLETED=$(grep -c '转码完成' "$LOG_FILE")
  SMART_SKIP=$(grep -c '智能跳过\|Skipping' "$LOG_FILE")
  EXIST_SKIP=$(grep -c '跳过.*已存在' "$LOG_FILE")
  FAILED=$(grep -c '转码失败\|Failed' "$LOG_FILE")
  
  echo "总文件数: ${TOTAL_FILES:-未知}"
  echo "已处理: $PROCESSED"
  echo "  - 转码完成: $COMPLETED"
  echo "  - 智能跳过: $SMART_SKIP"
  echo "  - 已存在跳过: $EXIST_SKIP"
  echo "转码失败: $FAILED"
  if [ -n "$TOTAL_FILES" ] && [ "$TOTAL_FILES" -gt 0 ]; then
    PROGRESS=$(echo "scale=1; $PROCESSED * 100 / $TOTAL_FILES" | bc 2>/dev/null || echo "0.0")
    echo ""
    echo "总进度: $PROCESSED/$TOTAL_FILES ($PROGRESS%)"
  fi
  echo ""
  echo "最近处理记录:"
  grep -E '(处理 \[|转码完成|智能跳过|跳过.*已存在)' "$LOG_FILE" | tail -3
else
  echo -e "${YELLOW}⚠️  日志文件不存在: $LOG_FILE${NC}"
fi

echo ""
echo "================================================"
echo "💾 输出目录大小"
echo "================================================"

# 输出目录从进程参数动态获取
if [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ]; then
  du -sh "$OUTPUT_DIR"
  echo "文件数量: $(find "$OUTPUT_DIR" -type f -name "*.mp4" | wc -l | xargs)"
elif [ -n "$OUTPUT_DIR" ]; then
  echo -e "${YELLOW}⚠️  输出目录尚未创建: $OUTPUT_DIR${NC}"
else
  echo -e "${YELLOW}⚠️  未检测到输出目录参数（任务可能未运行）${NC}"
fi

echo ""
echo "================================================"
