#!/bin/bash
# 专门用于处理行车视频的脚本
# 根据分析报告的建议进行转码处理

set -e  # 遇到错误时退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔥 VideoForge - 行车视频处理工具${NC}"
echo "=================================================="

# 配置参数
SOURCE_DIR="/Volumes/Disk0/DongNan/Nextcloud/视频"
TARGET_DIR="/Volumes/Disk0/Processing"
CODEC="h265"
QUALITY="medium"

# 检查源目录
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}❌ 源目录不存在: $SOURCE_DIR${NC}"
    exit 1
fi

# 创建目标目录
mkdir -p "$TARGET_DIR"

echo -e "\n📋 处理配置:"
echo "  源目录: $SOURCE_DIR"
echo "  目标目录: $TARGET_DIR"
echo "  编码格式: $CODEC"
echo "  质量预设: $QUALITY"
echo ""

# 询问用户
read -p "是否先进行预览分析？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}📊 正在分析视频目录...${NC}"
    python videoforge.py analyze "$SOURCE_DIR"
    echo ""
    read -p "按 Enter 继续，或 Ctrl+C 退出..." 
fi

# 询问是否预览
read -p "是否先预览转码计划？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}🔍 预览转码计划（不实际处理）...${NC}"
    python videoforge.py transcode \
        "$SOURCE_DIR" \
        -o "$TARGET_DIR" \
        --codec "$CODEC" \
        --quality "$QUALITY" \
        --skip-existing \
        --dry-run
    echo ""
    read -p "按 Enter 继续实际转码，或 Ctrl+C 退出..." 
fi

# 开始实际转码
echo -e "\n${GREEN}🚀 开始转码处理...${NC}"
echo "提示：这可能需要很长时间，请保持电脑运行"
echo "日志文件: logs/videoforge_$(date +%Y%m%d).log"
echo ""

python videoforge.py transcode \
    "$SOURCE_DIR" \
    -o "$TARGET_DIR" \
    --codec "$CODEC" \
    --quality "$QUALITY" \
    --skip-existing

echo -e "\n${GREEN}✅ 处理完成！${NC}"
echo -e "转码后的视频位于: ${YELLOW}$TARGET_DIR${NC}"
echo ""
echo "提示："
echo "  1. 请检查转码后的视频质量"
echo "  2. 确认无误后再删除原始文件"
echo "  3. 查看日志了解详细信息: logs/"
echo ""
