#!/bin/bash
# VideoForge 使用示例

# ==============================================================================
# 示例 1: 分析视频目录
# ==============================================================================
echo "示例 1: 分析视频目录"
python videoforge.py analyze "/Volumes/Disk0/DongNan/Nextcloud/视频/"

# ==============================================================================
# 示例 2: 转码整个目录（预览模式）
# ==============================================================================
echo -e "\n示例 2: 转码预览（不实际处理）"
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/" \
  -o "/Volumes/Disk0/Processing" \
  --codec h265 \
  --quality medium \
  --dry-run

# ==============================================================================
# 示例 3: 实际转码（推荐参数）
# ==============================================================================
echo -e "\n示例 3: 开始实际转码"
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/" \
  -o "/Volumes/Disk0/Processing" \
  --codec h265 \
  --quality medium \
  --skip-existing

# ==============================================================================
# 示例 4: 只转码行车视频目录
# ==============================================================================
echo -e "\n示例 4: 只转码行车视频"
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/行车视频" \
  -o "/Volumes/Disk0/Processing/行车视频" \
  --codec h265 \
  --quality medium \
  --skip-existing

# ==============================================================================
# 示例 5: 高质量转码（适合重要视频）
# ==============================================================================
echo -e "\n示例 5: 高质量转码"
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/行车视频/2023-05-17 行车记录" \
  -o "/Volumes/Disk0/Processing/行车视频/2023-05-17 行车记录" \
  --codec h265 \
  --quality high \
  --skip-existing

# ==============================================================================
# 示例 6: 压缩大视频文件
# ==============================================================================
echo -e "\n示例 6: 压缩大视频文件"
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/行车视频/行车记录_2024-04-04.mp4" \
  -o "/Volumes/Disk0/Processing/行车视频/行车记录_2024-04-04_compressed.mp4" \
  --codec h265 \
  --crf 28

# ==============================================================================
# 示例 7: 合并视频片段（无损）
# ==============================================================================
echo -e "\n示例 7: 合并视频片段（无损）"
python videoforge.py merge \
  video1.mp4 video2.mp4 video3.mp4 \
  -o merged_output.mp4

# ==============================================================================
# 示例 8: 合并并重新编码
# ==============================================================================
echo -e "\n示例 8: 合并并重新编码"
python videoforge.py merge \
  video1.mp4 video2.mp4 video3.mp4 \
  -o merged_output.mp4 \
  --reencode \
  --codec h265 \
  --quality medium

# ==============================================================================
# 示例 9: 只处理 MP4 文件
# ==============================================================================
echo -e "\n示例 9: 只处理 MP4 文件"
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/" \
  -o "/Volumes/Disk0/Processing" \
  --extensions mp4,MP4 \
  --codec h265 \
  --quality medium \
  --skip-existing

# ==============================================================================
# 示例 10: 转码到 720p（降低分辨率节省空间）
# ==============================================================================
echo -e "\n示例 10: 转码到 720p"
python videoforge.py transcode \
  "/path/to/videos" \
  -o "/path/to/output" \
  --codec h265 \
  --resolution 720p \
  --quality medium
