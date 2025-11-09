#!/bin/bash
# VideoForge - 处理 Nextcloud 视频目录
# 根据分析报告的建议，分类处理不同类型的视频

set -e

SOURCE_DIR="/Volumes/Disk0/DongNan/Nextcloud/视频"
OUTPUT_DIR="/Volumes/Disk0/Processing"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔥 VideoForge - Nextcloud 视频批量转码"
echo "================================================"
echo "源目录: $SOURCE_DIR"
echo "输出目录: $OUTPUT_DIR"
echo "================================================"
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 1. 处理行车视频目录（智能跳过已优化的视频）
echo "📹 步骤 1/2: 处理行车视频目录"
echo "  策略: H.265 中等质量 (CRF 23)，智能跳过已优化视频"
echo ""

python3 "$ROOT_DIR/videoforge.py" transcode \
    "$SOURCE_DIR/行车视频" \
    -o "$OUTPUT_DIR/行车视频" \
    --codec h265 \
    --quality medium \
    --skip-existing \
    --smart-skip

echo ""
echo "================================================"

# 2. 处理其他视频目录（如果存在）
if [ -d "$SOURCE_DIR/王晓燕的视频" ]; then
    echo "📹 步骤 2/2: 处理王晓燕的视频目录"
    echo "  策略: H.265 中等质量 (CRF 23)"
    echo ""
    
    python3 "$ROOT_DIR/videoforge.py" transcode \
        "$SOURCE_DIR/王晓燕的视频" \
        -o "$OUTPUT_DIR/王晓燕的视频" \
        --codec h265 \
        --quality medium \
        --skip-existing \
        --smart-skip
fi

echo ""
echo "================================================"
echo "✅ 所有视频处理完成！"
echo "================================================"

# 生成处理报告
echo ""
echo "📊 查看处理日志:"
echo "  主日志: $ROOT_DIR/logs/videoforge_$(date +%Y%m%d).log"
echo "  错误日志: $ROOT_DIR/logs/errors.log"
echo ""
