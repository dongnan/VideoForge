# 📁 VideoForge 项目结构

```
VideoForge/
├── README.md                      # 项目说明文档
├── QUICK_START.md                 # 快速入门指南 ⭐
├── PROJECT_STRUCTURE.md           # 本文件
│
├── videoforge.py                  # 主程序 ⭐
├── config.json                    # 配置文件
├── requirements.txt               # Python 依赖
│
├── process_driving_videos.sh      # 一键处理脚本 ⭐
├── examples.sh                    # 使用示例脚本
├── test_setup.sh                  # 环境检查脚本 ⭐
│
├── logs/                          # 日志目录（自动生成）
│   ├── videoforge_YYYYMMDD.log   # 每日日志
│   └── errors.log                 # 错误日志
│
└── .gitignore                     # Git 忽略文件
```

## 📄 文件说明

### 核心文件

#### `videoforge.py` 🔥
**主程序**，包含所有核心功能：
- 视频转码（单文件/批量）
- 视频合并
- 视频分析
- 进度跟踪
- 日志记录

**主要类**：
- `VideoForge`: 主类，封装所有功能

**主要方法**：
- `transcode_video()`: 转码单个视频
- `transcode_directory()`: 批量转码目录
- `merge_videos()`: 合并多个视频
- `analyze_directory()`: 分析视频目录
- `get_video_info()`: 获取视频信息

#### `config.json`
**配置文件**，可自定义默认参数：
```json
{
  "default_codec": "h265",       // 默认编码格式
  "default_quality": "medium",    // 默认质量
  "default_preset": "medium",     // 默认编码速度
  "video_extensions": [...],      // 支持的文件扩展名
  "skip_existing": true,          // 是否跳过已存在文件
  "max_threads": 1                // 最大并发线程数
}
```

### 脚本文件

#### `process_driving_videos.sh` ⭐
**推荐使用**的一键处理脚本，专门为处理行车视频优化：
- 交互式引导
- 自动配置参数
- 彩色输出
- 错误检查

**用法**：
```bash
./process_driving_videos.sh
```

#### `examples.sh`
**使用示例集合**，包含 10+ 个实用示例：
- 不同场景的转码示例
- 合并视频示例
- 分析视频示例

#### `test_setup.sh` ⭐
**环境检查脚本**，在使用前运行以确保环境正确：
- 检查 Python
- 检查 FFmpeg
- 检查源目录
- 检查磁盘空间

**用法**：
```bash
./test_setup.sh
```

### 文档文件

#### `README.md`
完整的项目文档：
- 功能介绍
- 安装说明
- 详细命令参考
- 使用示例
- 常见问题

#### `QUICK_START.md` ⭐
**快速入门指南**，新手必读：
- 3 步快速开始
- 常见场景示例
- 问题排查
- 参数速查表

## 🚀 使用流程

### 新手推荐流程

```bash
# 1. 进入目录
cd /Volumes/Disk0/CodeBuddy/VideoForge

# 2. 检查环境
./test_setup.sh

# 3. 查看快速入门
cat QUICK_START.md

# 4. 运行一键脚本
./process_driving_videos.sh
```

### 高级用户流程

```bash
# 1. 自定义配置
vim config.json

# 2. 查看示例
cat examples.sh

# 3. 直接使用命令
python videoforge.py transcode <源> -o <目标> [参数]
```

## 🔧 扩展开发

### 添加新功能

在 `videoforge.py` 中添加新方法：

```python
class VideoForge:
    def new_feature(self, ...):
        """新功能说明"""
        # 实现代码
        pass
```

### 添加新命令

在 `main()` 函数中添加新的子解析器：

```python
new_parser = subparsers.add_parser('newcmd', help='新命令')
new_parser.add_argument(...)
```

## 📊 日志文件

### 日志位置

- **每日日志**: `logs/videoforge_YYYYMMDD.log`
- **错误日志**: `logs/errors.log`

### 日志格式

```
2025-11-09 14:30:45 - INFO - 🔄 开始转码: video.mp4
2025-11-09 14:35:12 - INFO - ✅ 转码完成: video.mp4 (29.0 GB → 8.5 GB, 节省 70.7%)
```

### 查看日志

```bash
# 查看今天的日志
tail -f logs/videoforge_$(date +%Y%m%d).log

# 查看错误
cat logs/errors.log

# 统计成功数量
grep "✅ 转码完成" logs/*.log | wc -l
```

## 🎯 预期目录结构

### 处理前

```
/Volumes/Disk0/DongNan/Nextcloud/视频/
└── 行车视频/
    ├── 2023-04-23_04-28_driving_records/
    │   ├── 20230423073303_0060.mp4
    │   └── ...
    ├── 行车记录_2024-04-04.mp4
    └── ...
```

### 处理后

```
/Volumes/Disk0/Processing/
└── 行车视频/
    ├── 2023-04-23_04-28_driving_records/
    │   ├── 20230423073303_0060.mp4  (H.265 编码)
    │   └── ...
    ├── 行车记录_2024-04-04.mp4  (H.265 编码，大幅压缩)
    └── ...
```

**目录结构完全保持一致！** ✅

## 💡 技巧和建议

### 1. 磁盘空间管理

```bash
# 实时监控磁盘空间
watch -n 60 df -h /Volumes/Disk0

# 清理已处理的原文件（谨慎！）
# 先验证转码质量，再执行删除
```

### 2. 提高处理速度

```bash
# 使用更快的预设
python videoforge.py transcode ... --preset fast

# 降低质量要求
python videoforge.py transcode ... --crf 28
```

### 3. 批量验证质量

```bash
# 随机抽取 10 个视频检查
find /Volumes/Disk0/Processing -name "*.mp4" | shuf -n 10 | while read f; do
    echo "播放: $f"
    open "$f"
    read -p "质量OK？(y/n) "
done
```

### 4. 统计信息

```bash
# 统计节省的空间
du -sh /Volumes/Disk0/DongNan/Nextcloud/视频
du -sh /Volumes/Disk0/Processing

# 对比文件数量
find /Volumes/Disk0/DongNan/Nextcloud/视频 -name "*.mp4" | wc -l
find /Volumes/Disk0/Processing -name "*.mp4" | wc -l
```

## ⚠️ 注意事项

1. **原文件安全**: VideoForge 永远不会修改原始文件
2. **磁盘空间**: 确保有足够空间存放转码后的文件
3. **CPU 负载**: 转码过程会占用大量 CPU
4. **时间估算**: H.265 编码速度约为实时播放的 0.5-2 倍
5. **电源管理**: 处理大量文件时禁用自动休眠

## 📞 支持

遇到问题？
1. 查看 `QUICK_START.md` 的常见问题部分
2. 检查 `logs/errors.log`
3. 查看 `examples.sh` 寻找类似用法

---

**Happy Video Processing! 🔥**
