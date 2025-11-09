#!/bin/bash
# 测试智能跳过功能

echo "🧪 VideoForge 智能跳过功能测试"
echo "======================================"

# 测试目录
TEST_DIR="/Volumes/Disk0/DongNan/Nextcloud/视频/行车视频/2023-05-27_06-06_driving_records"

if [ ! -d "$TEST_DIR" ]; then
    echo "❌ 测试目录不存在: $TEST_DIR"
    exit 1
fi

echo -e "\n📊 第一步：分析测试目录中的视频编码"
echo "--------------------------------------"

# 随机抽取 5 个文件检查编码
echo "随机抽取 5 个视频文件："
cd "$TEST_DIR"
for file in $(ls *.mp4 | head -5); do
    echo -n "  $file: "
    codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    bitrate_mbps=$(echo "scale=1; $bitrate / 1000000" | bc)
    echo "$codec, ${bitrate_mbps} Mbps"
done

echo -e "\n🧪 第二步：测试智能跳过功能（预览模式）"
echo "--------------------------------------"

cd /Volumes/Disk0/CodeBuddy/VideoForge

echo "命令："
echo "python videoforge.py transcode \\"
echo "  \"$TEST_DIR\" \\"
echo "  -o \"/tmp/videoforge_test\" \\"
echo "  --codec h265 \\"
echo "  --quality medium \\"
echo "  --dry-run"

echo -e "\n执行中..."
python videoforge.py transcode \
  "$TEST_DIR" \
  -o "/tmp/videoforge_test" \
  --codec h265 \
  --quality medium \
  --dry-run \
  2>&1 | head -30

echo -e "\n✅ 测试完成！"
echo "======================================"
echo ""
echo "📝 说明："
echo "  - H.264 视频会被标记为需要转码"
echo "  - H.265 且码率 ≤ 3 Mbps 的视频会被智能跳过"
echo "  - 使用 --no-smart-skip 可以禁用此功能"
echo ""
echo "🔍 如需实际测试转码，执行："
echo "  python videoforge.py transcode \"$TEST_DIR\" -o \"/tmp/videoforge_test\" --codec h265 --quality medium"
echo ""
