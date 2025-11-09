#!/bin/bash
# 长时间任务监控脚本 - 优化版（所有路径动态获取，无硬编码）

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取脚本所在目录（运行时动态获取）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║      🔥 VideoForge 长时间任务监控 🔥                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${CYAN}监控时间: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}脚本目录: $SCRIPT_DIR${NC}"
echo ""

# 1. 通过脚本名查找进程
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}📊 进程状态${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PYTHON_PID=$(pgrep -f "python.*videoforge.py transcode" | head -1)

if [ -z "$PYTHON_PID" ]; then
    echo -e "${RED}❌ 转码任务未运行${NC}"
    echo ""
    echo "请使用以下命令启动任务:"
    echo "  cd $SCRIPT_DIR"
    echo "  python videoforge.py transcode [源目录] -o [输出目录] ..."
    exit 1
fi

# 获取完整命令行并提取参数（动态获取，无硬编码）
FULL_CMD=$(ps -p $PYTHON_PID -o command=)

# 提取源目录
SOURCE_DIR=$(echo "$FULL_CMD" | sed -n 's/.*transcode[[:space:]]\+\([^[:space:]]*\).*/\1/p' | tr -d '"')

# 提取输出目录
OUTPUT_DIR=$(echo "$FULL_CMD" | sed -n 's/.*-o[[:space:]]\+\([^[:space:]]*\).*/\1/p' | tr -d '"')
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR=$(echo "$FULL_CMD" | sed -n 's/.*--output[[:space:]]\+\([^[:space:]]*\).*/\1/p' | tr -d '"')
fi

# 提取其他参数
CODEC=$(echo "$FULL_CMD" | sed -n 's/.*--codec[[:space:]]\+\([^[:space:]]*\).*/\1/p')
QUALITY=$(echo "$FULL_CMD" | sed -n 's/.*--quality[[:space:]]\+\([^[:space:]]*\).*/\1/p')

# 显示主进程
echo -e "${GREEN}✅ Python 主进程: PID $PYTHON_PID${NC}"
ps -p $PYTHON_PID -o pid,pcpu,pmem,etime | tail -1 | awk '{print "   PID: "$1" | CPU: "$2"% | MEM: "$3"% | 运行时长: "$4}'

# 显示任务参数（从进程动态获取）
echo ""
echo "任务配置:"
[ -n "$SOURCE_DIR" ] && echo "  源: $SOURCE_DIR"
[ -n "$OUTPUT_DIR" ] && echo "  输出: $OUTPUT_DIR"
[ -n "$CODEC" ] && echo "  编码: $CODEC"
[ -n "$QUALITY" ] && echo "  质量: $QUALITY"

# 检查 FFmpeg 子进程
echo ""
FFMPEG_PID=$(pgrep -P $PYTHON_PID ffmpeg 2>/dev/null | head -1)
if [ -n "$FFMPEG_PID" ]; then
    echo -e "${GREEN}✅ FFmpeg 转码进程: PID $FFMPEG_PID${NC}"
    ps -p $FFMPEG_PID -o pid,pcpu,pmem,etime | tail -1 | awk '{print "   PID: "$1" | CPU: "$2"% | MEM: "$3"% | 运行时长: "$4}'
    
    # 从 FFmpeg 命令行提取当前文件（动态获取）
    CURRENT_FILE=$(ps -p $FFMPEG_PID -o command= | grep -o -- '-i [^[:space:]]*' | cut -d' ' -f2 | tr -d '"')
    if [ -n "$CURRENT_FILE" ]; then
        echo ""
        echo -e "${CYAN}📄 正在处理: $(basename "$CURRENT_FILE")${NC}"
        if [ -f "$CURRENT_FILE" ]; then
            ls -lh "$CURRENT_FILE" | awk '{print "   原始大小: "$5}'
        fi
        
        # 检查输出文件（使用动态获取的路径）
        if [ -n "$OUTPUT_DIR" ] && [ -n "$SOURCE_DIR" ]; then
            RELATIVE_PATH="${CURRENT_FILE#$SOURCE_DIR/}"
            OUTPUT_FILE="$OUTPUT_DIR/$RELATIVE_PATH"
            if [ -f "$OUTPUT_FILE" ]; then
                ls -lh "$OUTPUT_FILE" | awk '{print "   已输出: "$5}'
                
                # 计算压缩率
                if [ -f "$CURRENT_FILE" ]; then
                    ORIG_SIZE=$(stat -f%z "$CURRENT_FILE" 2>/dev/null || stat -c%s "$CURRENT_FILE" 2>/dev/null)
                    OUT_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
                    if [ -n "$ORIG_SIZE" ] && [ -n "$OUT_SIZE" ] && [ "$ORIG_SIZE" -gt 0 ]; then
                        PROGRESS=$((OUT_SIZE * 100 / ORIG_SIZE))
                        echo "   进度: ${PROGRESS}%"
                    fi
                fi
            fi
        fi
    fi
else
    echo -e "${YELLOW}⏸️  FFmpeg: 待机中（可能在智能跳过检查）${NC}"
fi

# 输出目录统计（使用动态路径）
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}📁 输出统计${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$SOURCE_DIR" ] && [ -d "$SOURCE_DIR" ]; then
    TOTAL_SOURCE=$(find "$SOURCE_DIR" -type f \( -name "*.mp4" -o -name "*.MP4" -o -name "*.mov" -o -name "*.MOV" -o -name "*.avi" -o -name "*.mkv" \) 2>/dev/null | wc -l | tr -d ' ')
    echo "源文件总数: $TOTAL_SOURCE"
fi

if [ -n "$OUTPUT_DIR" ] && [ -d "$OUTPUT_DIR" ]; then
    FILE_COUNT=$(find "$OUTPUT_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
    TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)
    
    echo "已生成文件: $FILE_COUNT"
    echo "总大小: $TOTAL_SIZE"
    
    # 最新生成的5个文件
    echo ""
    echo "最新生成文件:"
    find "$OUTPUT_DIR" -type f -exec ls -lth {} + 2>/dev/null | head -5 | awk '{print "  " $9 " (" $5 ")"}'
elif [ -n "$OUTPUT_DIR" ]; then
    echo -e "${YELLOW}输出目录尚未创建: $OUTPUT_DIR${NC}"
else
    echo -e "${YELLOW}未检测到输出目录参数${NC}"
fi

# 日志分析（动态路径）
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}📝 处理进度${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

LOG_FILE="$LOG_DIR/videoforge_$(date +%Y%m%d).log"
if [ -f "$LOG_FILE" ]; then
    # 统计处理状态
    TOTAL=$(grep -c "Processing file\|处理 \[" "$LOG_FILE" 2>/dev/null || echo "0")
    SKIPPED=$(grep -c "智能跳过\|Skipping" "$LOG_FILE" 2>/dev/null || echo "0")
    COMPLETED=$(grep -c "转码完成\|Successfully" "$LOG_FILE" 2>/dev/null || echo "0")
    FAILED=$(grep -c "ERROR\|Failed\|转码失败" "$LOG_FILE" 2>/dev/null || echo "0")
    
    echo "已处理文件: $TOTAL"
    echo "  - 智能跳过: $SKIPPED"
    echo "  - 转码完成: $COMPLETED"
    echo "  - 失败: $FAILED"
    
    if [ "$TOTAL" -gt 0 ]; then
        PROGRESS=$(awk "BEGIN {printf \"%.2f\", ($COMPLETED + $SKIPPED) * 100 / $TOTAL}")
        echo "  - 完成度: ${PROGRESS}%"
    fi
    
    # 最后处理的文件
    echo ""
    echo "最近3条日志:"
    tail -3 "$LOG_FILE" | sed 's/^/  /'
else
    echo -e "${YELLOW}日志文件不存在: $LOG_FILE${NC}"
fi

# 磁盘空间（动态检测）
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}💾 磁盘空间${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$OUTPUT_DIR" ]; then
    df -h "$OUTPUT_DIR" 2>/dev/null | tail -1 | awk '{
        print "磁盘: " $1
        print "总空间: " $2
        print "已使用: " $3 " (" $5 ")"
        print "可用: " $4
    }'
else
    df -h "$SCRIPT_DIR" | tail -1 | awk '{
        print "磁盘: " $1
        print "总空间: " $2
        print "已使用: " $3 " (" $5 ")"
        print "可用: " $4
    }'
fi

echo ""
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${CYAN}提示: watch -n 10 bash $0 实现每10秒自动刷新${NC}"
echo ""
