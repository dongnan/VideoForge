# 🚀 VideoForge 快速入门指南

## 第一步：准备工作

### 1. 确保已安装 FFmpeg

```bash
# macOS
brew install ffmpeg

# 检查是否安装成功
ffmpeg -version
```

### 2. 进入 VideoForge 目录

```bash
cd /Volumes/Disk0/CodeBuddy/VideoForge
```

### 3. 创建日志目录（自动创建，无需手动）

```bash
# 程序会自动创建 logs/ 目录
```

---

## 第二步：使用方法

### 🎯 方案 A: 使用一键脚本（推荐新手）

最简单的方式，处理所有行车视频：

```bash
# 添加执行权限
chmod +x process_driving_videos.sh

# 运行脚本
./process_driving_videos.sh
```

脚本会引导你完成：
1. ✅ 分析视频目录（可选）
2. ✅ 预览转码计划（可选）
3. ✅ 开始实际转码

---

### 🎯 方案 B: 手动执行（更灵活）

#### 步骤 1: 先分析视频

```bash
python videoforge.py analyze "/Volumes/Disk0/DongNan/Nextcloud/视频/"
```

这会显示：
- 文件总数和大小
- 编码格式分布
- 分辨率分布
- 总时长

#### 步骤 2: 预览转码（推荐）

```bash
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/" \
  -o "/Volumes/Disk0/Processing" \
  --codec h265 \
  --quality medium \
  --skip-existing \
  --dry-run
```

#### 步骤 3: 开始实际转码

```bash
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/" \
  -o "/Volumes/Disk0/Processing" \
  --codec h265 \
  --quality medium \
  --skip-existing
```

---

## 第三步：针对性处理

### 🎬 只处理大视频文件

如果你只想压缩那两个 29GB 和 15GB 的大文件：

```bash
# 处理第一个大文件
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/行车视频/行车记录_2024-04-04.mp4" \
  -o "/Volumes/Disk0/Processing/行车视频/行车记录_2024-04-04.mp4" \
  --codec h265 \
  --crf 28

# 处理第二个大文件
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/行车视频/行车记录_2024-04-05.mp4" \
  -o "/Volumes/Disk0/Processing/行车视频/行车记录_2024-04-05.mp4" \
  --codec h265 \
  --crf 28
```

预计效果：44 GB → 约 13-18 GB (节省 60-70%)

### 🎬 只处理特定子目录

```bash
# 只处理行车视频目录
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/行车视频" \
  -o "/Volumes/Disk0/Processing/行车视频" \
  --codec h265 \
  --quality medium \
  --skip-existing
```

### 🎬 分批处理

如果硬盘空间有限，可以分批处理：

```bash
# 第一批：2023-04 的视频
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/行车视频/2023-04-23_04-28_driving_records" \
  -o "/Volumes/Disk0/Processing/行车视频/2023-04-23_04-28_driving_records" \
  --codec h265 \
  --quality medium

# 检查结果，确认无误后再处理下一批
```

---

## 第四步：验证结果

### 1. 查看处理统计

转码完成后会自动显示统计信息：
- 处理文件数
- 节省空间
- 失败数量

### 2. 检查日志

```bash
# 查看今天的日志
cat logs/videoforge_$(date +%Y%m%d).log

# 查看错误日志
cat logs/errors.log
```

### 3. 对比文件

```bash
# 检查目标目录
ls -lh /Volumes/Disk0/Processing/

# 对比文件数量
find "/Volumes/Disk0/DongNan/Nextcloud/视频/" -name "*.mp4" | wc -l
find "/Volumes/Disk0/Processing/" -name "*.mp4" | wc -l
```

### 4. 测试播放

随机选择几个转码后的视频，确保：
- ✅ 可以正常播放
- ✅ 画质满意
- ✅ 音频正常

---

## 常见问题

### Q1: 转码速度太慢？

**A**: H.265 编码确实较慢。优化方法：

```bash
# 使用更快的预设（质量稍降）
python videoforge.py transcode ... --preset fast

# 或使用 H.264（速度快但压缩率低）
python videoforge.py transcode ... --codec h264
```

### Q2: 磁盘空间不够？

**A**: 分批处理，每批处理后验证并删除原文件：

```bash
# 1. 处理一个子目录
python videoforge.py transcode <子目录> -o <目标>

# 2. 验证转码质量

# 3. 删除原文件（谨慎！）
rm -rf <原子目录>

# 4. 继续下一批
```

### Q3: 如何暂停和继续？

**A**: 使用 `Ctrl+C` 暂停，再次运行相同命令继续：

```bash
# 使用 --skip-existing 参数会自动跳过已处理的文件
python videoforge.py transcode ... --skip-existing
```

### Q4: 转码后质量不满意？

**A**: 调整质量参数：

```bash
# 提高质量（文件更大）
--quality high  # 或 --crf 20

# 降低质量（文件更小）
--quality low   # 或 --crf 28
```

### Q5: 如何合并视频片段？

**A**: 使用 merge 命令：

```bash
# 直接合并（无损，速度快）
python videoforge.py merge video1.mp4 video2.mp4 video3.mp4 -o output.mp4

# 合并并重新编码（有损，文件更小）
python videoforge.py merge video1.mp4 video2.mp4 -o output.mp4 --reencode --codec h265
```

---

## 最佳实践建议

### ✅ 推荐工作流程

1. **先分析** → 了解视频情况
2. **预览处理** → 检查文件列表和目录结构
3. **小范围测试** → 先处理几个文件测试质量
4. **批量处理** → 确认无误后大批量处理
5. **验证质量** → 随机抽查转码后的视频
6. **备份原文件** → 确认无误后再删除（可选）

### ⚠️ 注意事项

1. **电源管理**：处理大量视频时，确保电脑不会休眠
2. **磁盘空间**：至少预留源文件 50% 的空间
3. **定期检查**：每处理一批就检查一次结果
4. **日志保存**：处理后保存日志以备查询

---

## 参数速查表

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| `--codec` | 编码格式 | `h265`（节省空间）或 `h264`（速度快） |
| `--quality` | 质量预设 | `medium`（平衡）或 `high`（重要视频） |
| `--crf` | 质量因子 | 20（高质量）23（平衡）28（压缩） |
| `--preset` | 编码速度 | `medium`（平衡）或 `fast`（快速） |
| `--skip-existing` | 跳过已存在 | 推荐使用 |
| `--dry-run` | 预览模式 | 首次使用推荐 |

---

## 快速命令备忘

```bash
# 分析
python videoforge.py analyze <目录>

# 预览
python videoforge.py transcode <源> -o <目标> --dry-run

# 转码（推荐参数）
python videoforge.py transcode <源> -o <目标> --codec h265 --quality medium --skip-existing

# 合并
python videoforge.py merge <文件1> <文件2> -o <输出>
```

---

**祝您使用愉快！如有问题，请查看日志文件 📝**
