#!/bin/bash
# VideoForge - 处理 Nextcloud 视频目录 (H.264 编码，兼容 QuickTime)

set -e

SOURCE_DIR="/Volumes/Disk0/DongNan/Nextcloud/视频"
OUTPUT_DIR="/Volumes/Disk0/Processing"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔥 VideoForge - Nextcloud 视频批量转码 (H.264 编码)"
echo "================================================"
echo "源目录: $SOURCE_DIR"
echo "输出目录: $OUTPUT_DIR"
echo "编码格式: H.264 (兼容 QuickTime)"
echo "================================================"
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 处理行车视频目录
echo "📹 处理行车视频目录"
echo "  策略: H.264 中等质量 (CRF 23)，智能跳过已优化视频"
echo ""

python3 "$SCRIPT_DIR/videoforge.py" transcode \
    "$SOURCE_DIR/行车视频" \
    -o "$OUTPUT_DIR/行车视频" \
    --codec h264 \
    --quality medium \
    --skip-existing \
    --smart-skip

echo ""
echo "================================================"
echo "✅ 所有视频处理完成！"
echo "================================================"

# 生成处理报告
echo ""
echo "📊 查看处理日志:"
echo "  主日志: $SCRIPT_DIR/logs/videoforge_$(date +%Y%m%d).log"
echo "  错误日志: $SCRIPT_DIR/logs/errors.log"
echo ""
