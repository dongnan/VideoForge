#!/bin/bash
# 检查转码状态 - 优化版（动态获取所有路径）

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo -e "${BLUE}📊 VideoForge 转码状态监控${NC}"
echo "========================================"
echo ""

# 1. 通过脚本名查找进程（更严谨）
echo -e "${YELLOW}🔍 进程状态:${NC}"
PYTHON_PID=$(pgrep -f "python.*videoforge.py transcode" | head -1)

if [ -z "$PYTHON_PID" ]; then
    echo -e "${RED}  ❌ 未找到运行中的转码任务${NC}"
    echo ""
    echo "提示: 使用以下命令启动转码任务:"
    echo "  cd $SCRIPT_DIR"
    echo "  python videoforge.py transcode [源目录] -o [输出目录] ..."
    exit 1
fi

echo -e "${GREEN}  ✅ Python 主进程 (PID: $PYTHON_PID)${NC}"

# 获取完整命令行
FULL_CMD=$(ps -p $PYTHON_PID -o command=)

# 从命令行中提取参数（动态获取）
# 提取源目录（transcode 后的第一个参数）
SOURCE_DIR=$(echo "$FULL_CMD" | sed -n 's/.*transcode[[:space:]]\+\([^[:space:]]*\).*/\1/p' | tr -d '"')

# 提取输出目录（-o 或 --output 后的参数）
OUTPUT_DIR=$(echo "$FULL_CMD" | sed -n 's/.*-o[[:space:]]\+\([^[:space:]]*\).*/\1/p' | tr -d '"')
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR=$(echo "$FULL_CMD" | sed -n 's/.*--output[[:space:]]\+\([^[:space:]]*\).*/\1/p' | tr -d '"')
fi

# 提取编码格式
CODEC=$(echo "$FULL_CMD" | sed -n 's/.*--codec[[:space:]]\+\([^[:space:]]*\).*/\1/p')

# 提取质量
QUALITY=$(echo "$FULL_CMD" | sed -n 's/.*--quality[[:space:]]\+\([^[:space:]]*\).*/\1/p')

# 显示进程详情
ps -p $PYTHON_PID -o pid,pcpu,pmem,etime,command | head -2 | tail -1 | awk '{print "     PID: "$1" | CPU: "$2"% | MEM: "$3"% | 运行时长: "$4}'

# 检查 FFmpeg 子进程
FFMPEG_PID=$(pgrep -P $PYTHON_PID ffmpeg 2>/dev/null | head -1)
if [ -n "$FFMPEG_PID" ]; then
    echo ""
    echo -e "${GREEN}  ✅ FFmpeg 转码进程 (PID: $FFMPEG_PID)${NC}"
    ps -p $FFMPEG_PID -o pid,pcpu,pmem,etime | tail -1 | awk '{print "     PID: "$1" | CPU: "$2"% | MEM: "$3"% | 运行时长: "$4}'
    
    # 从 FFmpeg 参数中获取当前处理的文件
    CURRENT_FILE=$(ps -p $FFMPEG_PID -o command= | grep -o -- '-i [^[:space:]]*' | cut -d' ' -f2 | tr -d '"')
    if [ -n "$CURRENT_FILE" ]; then
        echo -e "${CYAN}     正在处理: $(basename "$CURRENT_FILE")${NC}"
        if [ -f "$CURRENT_FILE" ]; then
            FILE_SIZE=$(ls -lh "$CURRENT_FILE" | awk '{print $5}')
            echo "     原始大小: $FILE_SIZE"
        fi
    fi
else
    echo -e "${YELLOW}  ℹ️  FFmpeg 进程未运行（可能在智能跳过检查）${NC}"
fi

echo ""
echo "========================================"

# 2. 任务配置（从进程参数动态获取）
echo -e "${YELLOW}📋 任务配置:${NC}"
[ -n "$SOURCE_DIR" ] && echo "  源目录: $SOURCE_DIR"
[ -n "$OUTPUT_DIR" ] && echo "  输出目录: $OUTPUT_DIR"
[ -n "$CODEC" ] && echo "  编码: $CODEC"
[ -n "$QUALITY" ] && echo "  质量: $QUALITY"
echo "$FULL_CMD" | grep -q "\-\-smart-skip" && echo "  智能跳过: 启用 ✅"

echo ""
echo "========================================"

# 3. 日志统计（动态路径）
echo -e "${YELLOW}📊 处理统计:${NC}"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/videoforge_$(date +%Y%m%d).log"

if [ -f "$LOG_FILE" ]; then
    TOTAL=$(grep "找到.*个视频文件" "$LOG_FILE" | tail -1 | grep -oE '[0-9]+' | head -1)
    PROCESSING=$(grep "处理 \[" "$LOG_FILE" | tail -1 | grep -oE '\[[0-9]+' | grep -oE '[0-9]+')
    SKIPPED=$(grep -c "智能跳过" "$LOG_FILE")
    TRANSCODING=$(grep -c "开始转码" "$LOG_FILE")
    COMPLETED=$(grep -c "转码完成" "$LOG_FILE")
    FAILED=$(grep -c "转码失败" "$LOG_FILE")
    
    echo "  总文件数: ${TOTAL:-未知}"
    echo "  当前处理: ${PROCESSING:-0}/${TOTAL:-?}"
    echo "  智能跳过: ${SKIPPED:-0}"
    echo "  已转码: ${COMPLETED:-0}"
    echo "  失败: ${FAILED:-0}"
    
    if [ -n "$TOTAL" ] && [ -n "$PROCESSING" ] && [ "$TOTAL" -gt 0 ]; then
        PERCENT=$((PROCESSING * 100 / TOTAL))
        echo "  进度: ${PERCENT}%"
    fi
else
    echo "  ⚠️  日志文件不存在"
fi

echo ""
echo "========================================"

# 4. 输出目录统计（从进程参数获取）
echo -e "${YELLOW}💾 输出统计:${NC}"
if [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ]; then
    FILE_COUNT=$(find "$OUTPUT_DIR" -type f 2>/dev/null | wc -l | xargs)
    TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" 2>/dev/null | awk '{print $1}')
    echo "  已生成文件: ${FILE_COUNT:-0} 个"
    echo "  总大小: ${TOTAL_SIZE:-0}"
    
    # 最新生成的文件
    LATEST_FILE=$(find "$OUTPUT_DIR" -type f -exec ls -lt {} + 2>/dev/null | head -2 | tail -1 | awk '{print $NF}')
    if [ -n "$LATEST_FILE" ]; then
        echo "  最新: $(basename "$LATEST_FILE")"
    fi
elif [ -n "$OUTPUT_DIR" ]; then
    echo "  ⚠️  输出目录不存在: $OUTPUT_DIR"
else
    echo "  ⚠️  未检测到输出目录参数"
fi

echo ""
echo "========================================"

# 5. 最新日志
echo -e "${YELLOW}📝 最新日志 (最后3条):${NC}"
if [ -f "$LOG_FILE" ]; then
    tail -3 "$LOG_FILE" | sed 's/^/  /'
else
    echo "  无日志"
fi

echo ""
echo "========================================"

# 6. 磁盘空间（动态检测）
echo -e "${YELLOW}💿 磁盘空间:${NC}"
if [ -n "$OUTPUT_DIR" ]; then
    df -h "$OUTPUT_DIR" 2>/dev/null | tail -1 | awk '{print "  可用: "$4" / 总计: "$2" ("$5" 已用)"}'
else
    df -h "$SCRIPT_DIR" | tail -1 | awk '{print "  可用: "$4" / 总计: "$2" ("$5" 已用)"}'
fi

echo ""
echo "========================================"
echo -e "${CYAN}💡 提示: watch -n 2 bash $0 实时监控${NC}"
echo "========================================"
