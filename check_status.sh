#!/bin/bash
# 检查 VideoForge 转码状态

LOG_FILE="/Volumes/Disk0/CodeBuddy/VideoForge/logs/videoforge_$(date +%Y%m%d).log"
OUTPUT_DIR="/Volumes/Disk0/Processing/行车视频"

echo "🔥 VideoForge 转码状态检查"
echo "================================================"

# 检查进程（包括 ffmpeg）
PYTHON_PID=$(pgrep -f "videoforge.py" | head -1)
FFMPEG_PID=$(pgrep -f "ffmpeg.*行车记录" | head -1)

if [ -n "$PYTHON_PID" ] || [ -n "$FFMPEG_PID" ]; then
    echo "✅ 转码进程正在运行"
    echo ""
    
    if [ -n "$PYTHON_PID" ]; then
        echo "Python 主进程 (PID: $PYTHON_PID):"
        ps -p $PYTHON_PID -o pid,pcpu,pmem,etime,comm | tail -1 | awk '{printf "  CPU: %s%%, 内存: %s%%, 运行时长: %s\n", $2, $3, $4}'
    fi
    
    if [ -n "$FFMPEG_PID" ]; then
        echo ""
        echo "FFmpeg 转码进程 (PID: $FFMPEG_PID):"
        ps -p $FFMPEG_PID -o pid,pcpu,pmem,vsz,rss,etime,comm | tail -1 | awk '{
            vsz_gb = $4/1024/1024
            rss_mb = $5/1024
            printf "  CPU: %s%%, 内存: %s%% (%.2f GB虚拟, %.0f MB物理)\n", $2, $3, vsz_gb, rss_mb
            printf "  运行时长: %s\n", $6
        }'
        
        # 显示当前正在处理的文件
        CURRENT_FILE=$(lsof -p $FFMPEG_PID 2>/dev/null | grep "\.mp4$" | head -1 | awk '{print $NF}')
        if [ -n "$CURRENT_FILE" ]; then
            echo "  当前文件: $(basename "$CURRENT_FILE")"
        fi
    fi
    
    # 系统资源总览
    echo ""
    echo "系统资源使用:"
    top -l 1 | grep -E "^CPU|^PhysMem" | sed 's/^/  /'
else
    echo "❌ 转码进程未运行"
fi

echo ""
echo "================================================"
echo "📊 处理统计（从日志）"
echo "================================================"

if [ -f "$LOG_FILE" ]; then
    TOTAL_FILES=$(grep '找到.*个视频文件' "$LOG_FILE" | tail -1 | grep -o '[0-9]\+' | head -1)
    PROCESSED=$(grep -c '处理 \[' "$LOG_FILE")
    COMPLETED=$(grep -c '转码完成' "$LOG_FILE")
    SMART_SKIP=$(grep -c '智能跳过' "$LOG_FILE")
    EXIST_SKIP=$(grep -c '跳过.*已存在' "$LOG_FILE")
    FAILED=$(grep -c '转码失败' "$LOG_FILE")
    
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
    echo "⚠️  日志文件不存在"
fi

echo ""
echo "================================================"
echo "💾 输出目录大小"
echo "================================================"

if [ -d "$OUTPUT_DIR" ]; then
    du -sh "$OUTPUT_DIR"
    echo "文件数量: $(find "$OUTPUT_DIR" -type f -name "*.mp4" | wc -l | xargs)"
else
    echo "⚠️  输出目录尚未创建"
fi

echo ""
echo "================================================"
