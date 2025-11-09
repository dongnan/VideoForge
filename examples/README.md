# VideoForge 使用示例

这个目录包含了 VideoForge 的各种实际使用案例脚本。

## 📂 脚本说明

### 1. `process_nextcloud_videos.sh`
批量处理 Nextcloud 视频文件（H.265 编码）

**用途**: 将 Nextcloud 视频目录转码为 H.265 格式，保持原分辨率

**使用方法**:
```bash
bash examples/process_nextcloud_videos.sh
```

**配置**:
- 源目录: `/Volumes/Disk0/DongNan/Nextcloud/视频/`
- 目标目录: `/Volumes/Disk0/Processing`
- 编码: H.265 (HEVC)
- 质量: medium (CRF 23)

---

### 2. `process_nextcloud_videos_h264.sh`
批量处理 Nextcloud 视频文件（H.264 编码，QuickTime 兼容）

**用途**: 将视频转码为 H.264 格式，兼容 QuickTime 播放器

**使用方法**:
```bash
bash examples/process_nextcloud_videos_h264.sh
```

**配置**:
- 编码: H.264 (兼容性更好)
- 质量: medium (CRF 23)
- QuickTime 兼容: ✅

---

### 3. `process_driving_videos.sh`
批量处理行车记录视频

**用途**: 专门处理行车记录仪视频，优化存储空间

**使用方法**:
```bash
bash examples/process_driving_videos.sh
```

**特点**:
- 针对行车记录仪视频优化
- 保持足够质量用于查看细节
- 大幅节省存储空间

---

## 💡 自定义脚本

### 基本模板

```bash
#!/bin/bash
# 自定义转码脚本

cd "$(dirname "$0")/.." || exit

python3 videoforge.py transcode \
    "/path/to/source" \
    -o "/path/to/output" \
    --codec h264 \
    --quality medium \
    --resolution original \
    --smart-skip
```

### 常用配置组合

#### 高质量保留（适合重要视频）
```bash
--codec h265 --quality high --resolution original
```

#### 平衡质量与大小（推荐日常使用）
```bash
--codec h265 --quality medium --resolution original
```

#### 最大压缩（存储空间紧张）
```bash
--codec h265 --quality low --resolution 1080p
```

#### QuickTime 兼容（Mac 用户）
```bash
--codec h264 --quality medium --resolution original
```

---

## 🎯 实际场景

### 场景 1: 归档家庭视频
```bash
# 保持高质量，使用 H.265 节省空间
python3 videoforge.py transcode \
    ~/Movies/家庭视频 \
    -o ~/Movies/归档 \
    --codec h265 \
    --quality high \
    --resolution original \
    --smart-skip
```

### 场景 2: 4K 视频降到 1080p
```bash
# 4K → 1080p，节省约 75% 空间
python3 videoforge.py transcode \
    ~/Movies/4K \
    -o ~/Movies/1080p \
    --codec h265 \
    --quality medium \
    --resolution 1080p \
    --smart-skip
```

### 场景 3: 批量转换为 QuickTime 兼容格式
```bash
# 转为 H.264，确保 QuickTime 可播放
python3 videoforge.py transcode \
    ~/Downloads/Videos \
    -o ~/Movies/Converted \
    --codec h264 \
    --quality medium \
    --resolution original \
    --smart-skip
```

### 场景 4: 混合分辨率统一化
```bash
# 将各种分辨率统一到 1080p
python3 videoforge.py transcode \
    ~/Movies/Mixed \
    -o ~/Movies/Unified \
    --codec h265 \
    --quality medium \
    --resolution 1080p \
    --smart-skip
```

---

## 📊 参数说明

### `--codec` (编码格式)
- `h264`: 兼容性最好，QuickTime 原生支持
- `h265`: 压缩率更高（节省 40-50% 空间），较新设备支持

### `--quality` (质量等级)
- `high`: CRF 20，最高质量，文件较大
- `medium`: CRF 23，推荐，质量与大小平衡
- `low`: CRF 28，最小文件，质量可接受

### `--resolution` (目标分辨率)
- `original`: 保持原分辨率（默认）
- `4K`: 限制到 4K (2160p)
- `2K`: 限制到 2K (1440p)
- `1080p`: 限制到 1080p
- `720p`: 限制到 720p

### `--smart-skip` (智能跳过)
- 启用后会预估转码效果
- 如果转码后不会更小，自动跳过
- **强烈推荐启用**，节省大量时间

---

## 🔍 监控转码进度

### 使用内置监控脚本
```bash
bash check_transcode_status.sh
```

### 实时监控
```bash
watch -n 2 bash check_transcode_status.sh
```

### 查看日志
```bash
tail -f logs/videoforge_$(date +%Y%m%d).log
```

---

## ⚙️ 进阶技巧

### 1. 后台运行
```bash
nohup python3 videoforge.py transcode ... &
```

### 2. 限制到指定文件类型
```bash
python3 videoforge.py transcode ... --extensions mp4,mov
```

### 3. 跳过已存在的文件
```bash
python3 videoforge.py transcode ... --skip-existing
```

### 4. 预览模式（不实际转码）
```bash
python3 videoforge.py transcode ... --dry-run
```

---

## 📝 编写自己的脚本

1. 复制模板脚本
2. 修改源目录和目标目录
3. 调整编码参数
4. 添加权限并运行

```bash
cp examples/process_nextcloud_videos.sh examples/my_script.sh
chmod +x examples/my_script.sh
bash examples/my_script.sh
```

---

**更新时间**: 2025-11-09  
**VideoForge 版本**: v2.2.0
