#!/bin/bash
# VideoForge 环境测试脚本

echo "🔍 VideoForge 环境检查"
echo "======================================"

# 检查 Python
echo -n "检查 Python... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ $PYTHON_VERSION"
else
    echo "❌ 未找到 Python3"
    exit 1
fi

# 检查 FFmpeg
echo -n "检查 FFmpeg... "
if command -v ffmpeg &> /dev/null; then
    FFMPEG_VERSION=$(ffmpeg -version | head -n1)
    echo "✅ $FFMPEG_VERSION"
else
    echo "❌ 未找到 FFmpeg"
    echo "请安装: brew install ffmpeg"
    exit 1
fi

# 检查 FFprobe
echo -n "检查 FFprobe... "
if command -v ffprobe &> /dev/null; then
    echo "✅"
else
    echo "❌ 未找到 FFprobe"
    exit 1
fi

# 检查源目录
echo -n "检查源目录... "
SOURCE_DIR="/Volumes/Disk0/DongNan/Nextcloud/视频"
if [ -d "$SOURCE_DIR" ]; then
    FILE_COUNT=$(find "$SOURCE_DIR" -type f \( -name "*.mp4" -o -name "*.MP4" \) | wc -l | xargs)
    echo "✅ 找到 $FILE_COUNT 个视频文件"
else
    echo "⚠️  目录不存在: $SOURCE_DIR"
fi

# 检查目标目录
echo -n "检查目标目录... "
TARGET_DIR="/Volumes/Disk0/Processing"
if [ -d "$TARGET_DIR" ]; then
    echo "✅ 已存在"
else
    echo "⚠️  不存在（将自动创建）"
fi

# 检查磁盘空间
echo -n "检查磁盘空间... "
AVAILABLE_SPACE=$(df -h /Volumes/Disk0 | tail -1 | awk '{print $4}')
echo "可用: $AVAILABLE_SPACE"

echo ""
echo "======================================"
echo "✅ 环境检查完成！"
echo ""
echo "下一步："
echo "  1. 查看快速入门: cat QUICK_START.md"
echo "  2. 运行示例脚本: ./process_driving_videos.sh"
echo "  3. 手动执行命令: python videoforge.py --help"
echo ""
