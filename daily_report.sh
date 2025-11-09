#!/bin/bash
# 每日进度报告 - 优化版（所有路径从进程动态获取，无硬编码）

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# 动态获取脚本目录和日志路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

TODAY=$(date +%Y%m%d)
LOG_FILE="$LOG_DIR/videoforge_${TODAY}.log"
REPORT_LOG="$LOG_DIR/daily_reports.log"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📊 VideoForge 每日进度报告${NC}"
echo -e "${CYAN}日期: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}日志目录: $LOG_DIR${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 从进程中动态提取所有路径（无硬编码）
PYTHON_PID=$(pgrep -f "python.*videoforge.py transcode" | head -1)
OUTPUT_DIR=""
SOURCE_DIR=""
CODEC=""
QUALITY=""

if [ -n "$PYTHON_PID" ]; then
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
fi

# 1. 任务状态
echo -e "${YELLOW}📋 任务状态${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$PYTHON_PID" ]; then
    RUNTIME=$(ps -p $PYTHON_PID -o etime= | tr -d ' ')
    echo -e "${GREEN}✅ 运行中 (PID: $PYTHON_PID)${NC}"
    echo "运行时长: $RUNTIME"
    echo ""
    echo "配置:"
    [ -n "$SOURCE_DIR" ] && echo "  源: $SOURCE_DIR"
    [ -n "$OUTPUT_DIR" ] && echo "  输出: $OUTPUT_DIR"
    [ -n "$CODEC" ] && echo "  编码: $CODEC"
    [ -n "$QUALITY" ] && echo "  质量: $QUALITY"
else
    echo -e "${RED}❌ 未运行${NC}"
    echo ""
    echo "提示: 如果日志存在，表示任务曾经运行过"
fi

# 2. 今日统计
echo ""
echo -e "${YELLOW}📈 今日统计${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$LOG_FILE" ]; then
    TODAY_TOTAL=$(grep -c "Processing file\|处理 \[" "$LOG_FILE" 2>/dev/null || echo "0")
    TODAY_SKIPPED=$(grep -c "智能跳过\|Skipping" "$LOG_FILE" 2>/dev/null || echo "0")
    TODAY_COMPLETED=$(grep -c "转码完成\|Successfully" "$LOG_FILE" 2>/dev/null || echo "0")
    TODAY_FAILED=$(grep -c "ERROR\|Failed\|转码失败" "$LOG_FILE" 2>/dev/null || echo "0")
    
    echo "处理文件: $TODAY_TOTAL"
    echo "  智能跳过: $TODAY_SKIPPED"
    echo "  转码完成: $TODAY_COMPLETED"
    echo "  失败: $TODAY_FAILED"
    
    if [ "$TODAY_TOTAL" -gt 0 ]; then
        SKIP_RATE=$(awk "BEGIN {printf \"%.2f\", $TODAY_SKIPPED * 100 / $TODAY_TOTAL}")
        echo "  跳过率: ${SKIP_RATE}%"
    fi
else
    echo -e "${YELLOW}⚠️  今日无日志文件${NC}"
fi

# 3. 总体进度（从所有日志汇总）
echo ""
echo -e "${YELLOW}📊 总体进度${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ALL_LOGS="$LOG_DIR/videoforge_*.log"
if ls $ALL_LOGS 1> /dev/null 2>&1; then
    TOTAL_SKIPPED=$(grep -h "智能跳过\|Skipping" $ALL_LOGS 2>/dev/null | wc -l | xargs)
    TOTAL_COMPLETED=$(grep -h "转码完成\|Successfully" $ALL_LOGS 2>/dev/null | wc -l | xargs)
    TOTAL_FAILED=$(grep -h "ERROR\|Failed\|转码失败" $ALL_LOGS 2>/dev/null | wc -l | xargs)
    
    # 从日志中提取总文件数
    TOTAL_FILES=$(grep -h "找到.*个视频文件" $ALL_LOGS 2>/dev/null | tail -1 | grep -oE '[0-9]+' | head -1)
    
    echo "累计跳过: $TOTAL_SKIPPED"
    echo "累计完成: $TOTAL_COMPLETED"
    echo "累计失败: $TOTAL_FAILED"
    
    if [ -n "$TOTAL_FILES" ] && [ "$TOTAL_FILES" -gt 0 ]; then
        PROCESSED=$((TOTAL_SKIPPED + TOTAL_COMPLETED + TOTAL_FAILED))
        PERCENT=$((PROCESSED * 100 / TOTAL_FILES))
        REMAINING=$((TOTAL_FILES - PROCESSED))
        echo ""
        echo "总文件数: $TOTAL_FILES"
        echo "已处理: $PROCESSED ($PERCENT%)"
        echo "剩余: $REMAINING"
    fi
fi

# 4. 输出目录统计（使用动态路径）
echo ""
echo -e "${YELLOW}💾 输出统计${NC}"
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
    
    # 计算总体进度
    if [ -n "$TOTAL_SOURCE" ] && [ "$TOTAL_SOURCE" -gt 0 ]; then
        PROGRESS=$(awk "BEGIN {printf \"%.2f\", $FILE_COUNT * 100 / $TOTAL_SOURCE}")
        echo "完成度: ${PROGRESS}%"
    fi
elif [ -n "$OUTPUT_DIR" ]; then
    echo -e "${YELLOW}输出目录不存在: $OUTPUT_DIR${NC}"
else
    echo -e "${YELLOW}未检测到输出目录（任务未运行）${NC}"
fi

# 5. 错误摘要
echo ""
echo -e "${YELLOW}⚠️  错误摘要${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$LOG_FILE" ] && [ "${TODAY_FAILED:-0}" -gt 0 ]; then
    echo -e "${RED}今日发现 $TODAY_FAILED 个错误:${NC}"
    grep "ERROR\|Failed\|转码失败" "$LOG_FILE" 2>/dev/null | tail -5 | sed 's/^/  /'
else
    echo -e "${GREEN}✅ 今日无错误${NC}"
fi

# 6. 磁盘空间（动态检测）
echo ""
echo -e "${YELLOW}💿 磁盘空间${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$OUTPUT_DIR" ]; then
    df -h "$OUTPUT_DIR" 2>/dev/null | tail -1 | awk '{
        print "已使用: " $3 " (" $5 ")"
        print "可用: " $4
    }'
else
    df -h "$SCRIPT_DIR" | tail -1 | awk '{
        print "已使用: " $3 " (" $5 ")"
        print "可用: " $4
    }'
fi

# 7. 正在处理的文件
if [ -n "$PYTHON_PID" ]; then
    FFMPEG_PID=$(pgrep -P $PYTHON_PID ffmpeg 2>/dev/null | head -1)
    if [ -n "$FFMPEG_PID" ]; then
        CURRENT_FILE=$(ps -p $FFMPEG_PID -o command= | grep -o -- '-i [^[:space:]]*' | cut -d' ' -f2 | tr -d '"')
        if [ -n "$CURRENT_FILE" ]; then
            echo ""
            echo -e "${YELLOW}🔄 正在处理${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "文件: $(basename "$CURRENT_FILE")"
            
            if [ -f "$CURRENT_FILE" ]; then
                ORIG_SIZE=$(ls -lh "$CURRENT_FILE" | awk '{print $5}')
                echo "原始: $ORIG_SIZE"
            fi
            
            # 查找输出文件（使用动态路径）
            if [ -n "$OUTPUT_DIR" ] && [ -n "$SOURCE_DIR" ]; then
                RELATIVE_PATH="${CURRENT_FILE#$SOURCE_DIR/}"
                OUTPUT_FILE="$OUTPUT_DIR/$RELATIVE_PATH"
                if [ -f "$OUTPUT_FILE" ]; then
                    OUT_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
                    echo "已输出: $OUT_SIZE"
                fi
            fi
        fi
    fi
fi

# 保存报告到日志
echo ""
echo -e "${CYAN}💾 保存报告...${NC}"
{
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "报告日期: $(date '+%Y-%m-%d %H:%M:%S')"
    [ -n "$SOURCE_DIR" ] && echo "源: $SOURCE_DIR"
    [ -n "$OUTPUT_DIR" ] && echo "输出: $OUTPUT_DIR"
    echo "今日: 处理 ${TODAY_TOTAL:-0} | 跳过 ${TODAY_SKIPPED:-0} | 完成 ${TODAY_COMPLETED:-0} | 失败 ${TODAY_FAILED:-0}"
    echo "累计: 跳过 ${TOTAL_SKIPPED:-0} | 完成 ${TOTAL_COMPLETED:-0} | 失败 ${TOTAL_FAILED:-0}"
    if [ -n "$FILE_COUNT" ] && [ -n "$TOTAL_SIZE" ]; then
        echo "输出: $FILE_COUNT 文件 | 大小: $TOTAL_SIZE"
    fi
    if [ -n "$PYTHON_PID" ]; then
        echo "状态: 运行中 (PID: $PYTHON_PID, 运行时长: ${RUNTIME:-未知})"
    else
        echo "状态: 已停止"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
} >> "$REPORT_LOG"

echo -e "${GREEN}✅ 报告已保存到: $REPORT_LOG${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
