# 🔥 VideoForge - 视频熔炉

**强大的视频批量处理工具**

VideoForge 是一款专为视频优化的批量处理工具，支持智能转码、合并、压缩等功能。

## ✨ 特性

- 🎯 **智能转码**: 自动选择最优编码参数
- 🧠 **智能跳过**: 自动跳过已是目标编码且码率更低的视频（v1.1+）
- 📦 **批量处理**: 支持整个目录树的递归处理
- 🗂️ **目录映射**: 保持原始目录结构到目标路径
- 🔄 **多种编码**: 支持 H.264、H.265/HEVC
- 📊 **进度跟踪**: 实时显示处理进度和预估时间
- 💾 **空间预估**: 处理前预估节省的空间
- 🛡️ **安全模式**: 不会修改原始文件
- 📝 **详细日志**: 记录所有处理操作

## 🚀 快速开始

### 基础用法

```bash
# 转码单个文件
python videoforge.py transcode input.mp4 -o output.mp4

# 转码整个目录（保持结构）
python videoforge.py transcode /source/path -o /target/path

# 合并多个视频
python videoforge.py merge file1.mp4 file2.mp4 -o merged.mp4
```

### 高级用法

```bash
# 使用 H.265 编码，高质量
python videoforge.py transcode /source -o /target --codec h265 --quality high

# 批量处理，跳过已存在的文件
python videoforge.py transcode /source -o /target --skip-existing

# 仅处理特定扩展名
python videoforge.py transcode /source -o /target --extensions mp4,MP4

# 预览模式（不实际处理）
python videoforge.py transcode /source -o /target --dry-run
```

## 📋 命令参数

### transcode 命令

转码视频文件或目录。

```
python videoforge.py transcode <input> -o <output> [options]

参数:
  input                输入文件或目录路径
  -o, --output        输出文件或目录路径
  
选项:
  --codec             编码格式: h264, h265 (默认: h265)
  --quality           质量: high, medium, low (默认: medium)
  --preset            编码速度: ultrafast, fast, medium, slow (默认: medium)
  --crf               CRF 值 (18-28, 越小质量越高, 默认: 23)
  --resolution        目标分辨率: 1080p, 720p, 原始 (默认: 原始)
  --extensions        文件扩展名过滤 (默认: mp4,MP4,avi,AVI,mov,MOV)
  --skip-existing     跳过已存在的文件
  --smart-skip        智能跳过：跳过已是目标编码且码率更低的视频（默认启用）
  --no-smart-skip     禁用智能跳过
  --dry-run           预览模式，不实际处理
  --threads           并发处理线程数 (默认: 1)
```

### 🧠 智能跳过功能（v1.1+）

智能跳过功能会自动检测视频是否需要转码：

**跳过条件**：
- 视频已经是目标编码格式（如 H.265）
- 当前码率低于或等于目标码率
- 不需要调整分辨率

**使用示例**：
```bash
# 默认启用智能跳过
python videoforge.py transcode input/ -o output/ --codec h265 --quality medium

# 禁用智能跳过（强制重新编码所有视频）
python videoforge.py transcode input/ -o output/ --codec h265 --quality medium --no-smart-skip
```

**实际效果**：
```
📹 处理 [123/1000]: S_20230605085059_1800_0030.mp4
⏭️  智能跳过: S_20230605085059_1800_0030.mp4 (已是 HEVC 且码率 7.5 Mbps ≤ 目标 3.0 Mbps)
```

### merge 命令

合并多个视频文件。

```
python videoforge.py merge <input1> <input2> ... -o <output> [options]

参数:
  input1 input2 ...   输入视频文件列表
  -o, --output        输出文件路径
  
选项:
  --reencode          重新编码（否则直接合并）
  --codec             编码格式: h264, h265
  --quality           质量: high, medium, low
```

### analyze 命令

分析视频文件信息。

```
python videoforge.py analyze <input>

参数:
  input               输入文件或目录路径
```

## 🎨 使用示例

详细示例请查看 [`examples/`](examples/) 目录。

### 示例 1: 转码行车记录视频

将行车记录视频从 H.264 转为 H.265，节省空间：

```bash
# 使用示例脚本
bash examples/process_nextcloud_videos.sh

# 或者直接使用命令
python videoforge.py transcode \
  "/Volumes/Disk0/DongNan/Nextcloud/视频/" \
  -o "/Volumes/Disk0/Processing" \
  --codec h265 \
  --quality medium \
  --skip-existing
```

### 示例 2: 压缩大视频文件

压缩高码率的大视频文件：

```bash
python videoforge.py transcode \
  "/path/to/large_video.mp4" \
  -o "/path/to/compressed_video.mp4" \
  --codec h265 \
  --crf 28
```

### 示例 3: 合并片段视频

将多个小片段合并成一个文件：

```bash
python videoforge.py merge \
  video1.mp4 video2.mp4 video3.mp4 \
  -o merged_output.mp4 \
  --reencode \
  --codec h265
```

## 📊 质量预设说明

| 预设 | CRF | 适用场景 | 码率范围 (1080p) |
|------|-----|---------|-----------------|
| high | 20 | 重要视频、高质量归档 | 4-6 Mbps |
| medium | 23 | 日常行车记录 | 2-4 Mbps |
| low | 28 | 临时存储、大批量 | 1-2 Mbps |

## 🔧 配置文件

创建 `config.json` 自定义默认参数：

```json
{
  "default_codec": "h265",
  "default_quality": "medium",
  "default_preset": "medium",
  "video_extensions": ["mp4", "MP4", "avi", "mov"],
  "skip_existing": true,
  "max_threads": 4
}
```

## 📂 项目结构

```
VideoForge/
├── videoforge.py           # 主程序
├── config.json             # 配置文件（可选）
├── logs/                   # 日志目录（自动生成）
│   ├── videoforge_YYYYMMDD.log  # 每日日志
│   └── errors.log          # 错误日志
├── examples/               # 使用示例脚本
│   ├── README.md
│   ├── process_nextcloud_videos.sh
│   ├── process_nextcloud_videos_h264.sh
│   └── process_driving_videos.sh
├── tests/                  # 测试用例
│   ├── README.md
│   ├── test_resolution_detection.py
│   ├── test_estimation.py
│   ├── test_setup.sh
│   └── test_smart_skip.sh
└── docs/                   # 文档（自动生成）
    ├── 分辨率优化说明.md
    ├── 智能预估优化说明.md
    └── 性能优化总结.md
```

### 📝 日志

日志文件自动保存在 **脚本所在目录** 的 `logs/` 子目录中：
- `logs/videoforge_YYYYMMDD.log`: 每日处理日志
- `logs/errors.log`: 错误日志

无论从哪个目录运行脚本，日志都会保存在 VideoForge 项目目录下。

## ⚠️ 注意事项

1. **原始文件安全**: VideoForge 永不修改原始文件
2. **磁盘空间**: 确保目标磁盘有足够空间
3. **处理时间**: H.265 编码速度较慢，大文件需要较长时间
4. **CPU 占用**: 转码会占用大量 CPU 资源
5. **建议先测试**: 使用 `--dry-run` 预览处理计划

## 🛠️ 系统要求

- Python 3.7+
- FFmpeg 4.0+
- 推荐 8GB+ 内存
- 推荐多核 CPU

## 📦 安装依赖

```bash
pip install -r requirements.txt
```

## 📄 License

MIT License

---

**Made with ❤️ for efficient video management**
