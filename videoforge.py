#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🔥 VideoForge - 视频熔炉
强大的视频批量处理工具

Author: VideoForge Team
License: MIT
"""

import argparse
import json
import logging
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional, Tuple
import threading
from queue import Queue
import time


class VideoForge:
    """视频熔炉主类"""
    
    # 编码预设
    QUALITY_PRESETS = {
        'high': {'crf': 20, 'preset': 'slow'},
        'medium': {'crf': 23, 'preset': 'medium'},
        'low': {'crf': 28, 'preset': 'fast'}
    }
    
    # 支持的视频扩展名
    DEFAULT_EXTENSIONS = ['.mp4', '.MP4', '.avi', '.AVI', '.mov', '.MOV', '.mkv', '.MKV']
    
    def __init__(self, config_file: Optional[str] = None):
        """初始化 VideoForge"""
        self.config = self._load_config(config_file)
        self._setup_logging()
        self.stats = {
            'total_files': 0,
            'processed': 0,
            'skipped': 0,
            'skipped_smart': 0,  # 智能跳过的数量
            'failed': 0,
            'total_size_before': 0,
            'total_size_after': 0
        }
        
    def _load_config(self, config_file: Optional[str]) -> Dict:
        """加载配置文件"""
        default_config = {
            'default_codec': 'h265',
            'default_quality': 'medium',
            'default_preset': 'medium',
            'video_extensions': self.DEFAULT_EXTENSIONS,
            'skip_existing': False,
            'max_threads': 1
        }
        
        if config_file and os.path.exists(config_file):
            with open(config_file, 'r', encoding='utf-8') as f:
                user_config = json.load(f)
                default_config.update(user_config)
        
        return default_config
    
    def _setup_logging(self):
        """设置日志"""
        log_dir = Path('logs')
        log_dir.mkdir(exist_ok=True)
        
        log_file = log_dir / f"videoforge_{datetime.now().strftime('%Y%m%d')}.log"
        error_log = log_dir / "errors.log"
        
        # 配置日志格式
        formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        # 主日志
        self.logger = logging.getLogger('VideoForge')
        self.logger.setLevel(logging.INFO)
        
        # 文件处理器
        fh = logging.FileHandler(log_file, encoding='utf-8')
        fh.setLevel(logging.INFO)
        fh.setFormatter(formatter)
        
        # 错误日志处理器
        eh = logging.FileHandler(error_log, encoding='utf-8')
        eh.setLevel(logging.ERROR)
        eh.setFormatter(formatter)
        
        # 控制台处理器
        ch = logging.StreamHandler()
        ch.setLevel(logging.INFO)
        ch.setFormatter(formatter)
        
        self.logger.addHandler(fh)
        self.logger.addHandler(eh)
        self.logger.addHandler(ch)
    
    def check_ffmpeg(self) -> bool:
        """检查 FFmpeg 是否可用"""
        try:
            subprocess.run(['ffmpeg', '-version'], 
                         stdout=subprocess.PIPE, 
                         stderr=subprocess.PIPE,
                         check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            self.logger.error("❌ FFmpeg 未安装或不在 PATH 中")
            return False
    
    def get_video_info(self, video_path: str) -> Optional[Dict]:
        """获取视频信息"""
        try:
            cmd = [
                'ffprobe',
                '-v', 'error',
                '-show_format',
                '-show_streams',
                '-print_format', 'json',
                video_path
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            info = json.loads(result.stdout)
            
            # 提取关键信息
            video_stream = next((s for s in info.get('streams', []) 
                               if s.get('codec_type') == 'video'), None)
            
            if not video_stream:
                return None
            
            return {
                'width': video_stream.get('width'),
                'height': video_stream.get('height'),
                'codec': video_stream.get('codec_name'),
                'bit_rate': int(video_stream.get('bit_rate', 0)),
                'duration': float(info.get('format', {}).get('duration', 0)),
                'size': int(info.get('format', {}).get('size', 0)),
                'fps': eval(video_stream.get('r_frame_rate', '0/1'))
            }
        except Exception as e:
            self.logger.error(f"获取视频信息失败 {video_path}: {e}")
            return None
    
    def should_skip_video(self, input_path: str, codec: str, quality: str, 
                         crf: int = None, resolution: str = None) -> Tuple[bool, str]:
        """判断是否应该跳过视频处理
        
        Returns:
            (should_skip, reason): (是否跳过, 跳过原因)
        """
        # 获取视频信息
        info = self.get_video_info(input_path)
        if not info:
            return False, ""
        
        # 获取目标 CRF
        if quality in self.QUALITY_PRESETS and crf is None:
            target_crf = self.QUALITY_PRESETS[quality]['crf']
        else:
            target_crf = crf or 23
        
        # 根据 CRF 估算目标码率 (粗略估算)
        # CRF 20 约 4-6 Mbps, CRF 23 约 2-4 Mbps, CRF 28 约 1-2 Mbps (1080p)
        height = info.get('height', 1080)
        if target_crf <= 20:
            target_bitrate = 5000000 * (height / 1080)  # 5 Mbps
        elif target_crf <= 23:
            target_bitrate = 3000000 * (height / 1080)  # 3 Mbps
        else:
            target_bitrate = 1500000 * (height / 1080)  # 1.5 Mbps
        
        current_codec = info.get('codec', '').lower()
        current_bitrate = info.get('bit_rate', 0)
        
        # 目标编码名称
        target_codec_names = []
        if codec == 'h265':
            target_codec_names = ['hevc', 'h265']
        else:
            target_codec_names = ['h264', 'avc']
        
        # 检查是否已经是目标编码
        is_target_codec = current_codec in target_codec_names
        
        # 检查分辨率是否需要调整
        needs_resolution_change = False
        if resolution and resolution != 'original':
            current_height = info.get('height', 0)
            if resolution == '1080p' and current_height > 1080:
                needs_resolution_change = True
            elif resolution == '720p' and current_height > 720:
                needs_resolution_change = True
        
        # 判断逻辑
        if is_target_codec and current_bitrate > 0 and current_bitrate <= target_bitrate:
            if not needs_resolution_change:
                reason = (f"已是 {current_codec.upper()} 且码率 "
                         f"{current_bitrate/1000000:.1f} Mbps ≤ 目标 {target_bitrate/1000000:.1f} Mbps")
                return True, reason
        
        return False, ""
    
    def transcode_video(self, input_path: str, output_path: str, 
                       codec: str = 'h265', quality: str = 'medium',
                       preset: str = None, crf: int = None,
                       resolution: str = None, 
                       smart_skip: bool = True) -> bool:
        """转码单个视频文件
        
        Args:
            smart_skip: 智能跳过（如果源视频已经是目标编码且码率更低）
        """
        
        # 智能跳过检查
        if smart_skip:
            should_skip, skip_reason = self.should_skip_video(
                input_path, codec, quality, crf, resolution
            )
            if should_skip:
                self.logger.info(
                    f"⏭️  智能跳过: {os.path.basename(input_path)} ({skip_reason})"
                )
                self.stats['skipped'] += 1
                self.stats['skipped_smart'] += 1
                return True  # 返回 True 表示"成功"（跳过也算成功）
        
        # 获取质量预设
        if quality in self.QUALITY_PRESETS:
            quality_preset = self.QUALITY_PRESETS[quality]
            if crf is None:
                crf = quality_preset['crf']
            if preset is None:
                preset = quality_preset['preset']
        else:
            crf = crf or 23
            preset = preset or 'medium'
        
        # 构建 ffmpeg 命令
        codec_lib = 'libx265' if codec == 'h265' else 'libx264'
        
        cmd = [
            'ffmpeg',
            '-i', input_path,
            '-c:v', codec_lib,
            '-crf', str(crf),
            '-preset', preset,
            '-c:a', 'copy',  # 音频直接复制
        ]
        
        # 分辨率调整
        if resolution and resolution != 'original':
            if resolution == '1080p':
                cmd.extend(['-vf', 'scale=-2:1080'])
            elif resolution == '720p':
                cmd.extend(['-vf', 'scale=-2:720'])
        
        # 输出文件
        cmd.extend(['-y', output_path])  # -y 覆盖已存在的文件
        
        try:
            self.logger.info(f"🔄 开始转码: {os.path.basename(input_path)}")
            self.logger.debug(f"命令: {' '.join(cmd)}")
            
            # 执行转码
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            
            # 实时输出进度（简化版）
            for line in process.stderr:
                if 'time=' in line:
                    # 可以解析进度信息
                    pass
            
            process.wait()
            
            if process.returncode == 0:
                # 获取文件大小
                input_size = os.path.getsize(input_path)
                output_size = os.path.getsize(output_path)
                ratio = (1 - output_size / input_size) * 100 if input_size > 0 else 0
                
                self.logger.info(
                    f"✅ 转码完成: {os.path.basename(input_path)} "
                    f"({self._format_size(input_size)} → {self._format_size(output_size)}, "
                    f"节省 {ratio:.1f}%)"
                )
                
                self.stats['total_size_before'] += input_size
                self.stats['total_size_after'] += output_size
                self.stats['processed'] += 1
                
                return True
            else:
                self.logger.error(f"❌ 转码失败: {os.path.basename(input_path)}")
                self.stats['failed'] += 1
                return False
                
        except Exception as e:
            self.logger.error(f"❌ 转码异常 {input_path}: {e}")
            self.stats['failed'] += 1
            return False
    
    def transcode_directory(self, input_dir: str, output_dir: str,
                          codec: str = 'h265', quality: str = 'medium',
                          extensions: List[str] = None,
                          skip_existing: bool = False,
                          dry_run: bool = False,
                          **kwargs) -> Dict:
        """批量转码目录"""
        
        input_path = Path(input_dir)
        output_path = Path(output_dir)
        
        if not input_path.exists():
            self.logger.error(f"❌ 输入目录不存在: {input_dir}")
            return self.stats
        
        # 扩展名过滤
        if extensions is None:
            extensions = self.config['video_extensions']
        else:
            extensions = ['.' + ext.lstrip('.') for ext in extensions]
        
        # 收集所有视频文件
        video_files = []
        for ext in extensions:
            video_files.extend(input_path.rglob(f'*{ext}'))
        
        self.stats['total_files'] = len(video_files)
        
        if self.stats['total_files'] == 0:
            self.logger.warning(f"⚠️  未找到视频文件")
            return self.stats
        
        self.logger.info(f"📊 找到 {self.stats['total_files']} 个视频文件")
        
        if dry_run:
            self.logger.info("🔍 预览模式 (不会实际处理)")
        
        # 处理每个视频
        for idx, video_file in enumerate(video_files, 1):
            # 计算相对路径
            rel_path = video_file.relative_to(input_path)
            target_file = output_path / rel_path
            
            # 修改扩展名为 .mp4
            target_file = target_file.with_suffix('.mp4')
            
            # 创建目标目录
            target_file.parent.mkdir(parents=True, exist_ok=True)
            
            # 检查是否跳过
            if skip_existing and target_file.exists():
                self.logger.info(f"⏭️  跳过 [{idx}/{self.stats['total_files']}]: {rel_path} (已存在)")
                self.stats['skipped'] += 1
                continue
            
            self.logger.info(f"📹 处理 [{idx}/{self.stats['total_files']}]: {rel_path}")
            
            if dry_run:
                self.logger.info(f"   → {target_file.relative_to(output_path)}")
                continue
            
            # 执行转码
            success = self.transcode_video(
                str(video_file),
                str(target_file),
                codec=codec,
                quality=quality,
                **kwargs
            )
            
            if not success:
                self.logger.warning(f"⚠️  处理失败，但继续处理下一个")
        
        # 输出统计信息
        self._print_stats()
        
        return self.stats
    
    def merge_videos(self, input_files: List[str], output_file: str,
                    reencode: bool = False, codec: str = 'h265',
                    quality: str = 'medium') -> bool:
        """合并多个视频文件"""
        
        if len(input_files) < 2:
            self.logger.error("❌ 至少需要 2 个视频文件")
            return False
        
        # 检查所有输入文件是否存在
        for f in input_files:
            if not os.path.exists(f):
                self.logger.error(f"❌ 文件不存在: {f}")
                return False
        
        try:
            if reencode:
                # 重新编码合并
                self.logger.info(f"🔄 合并并重新编码 {len(input_files)} 个视频...")
                
                # 创建临时文件列表
                list_file = Path('temp_filelist.txt')
                with open(list_file, 'w', encoding='utf-8') as f:
                    for video in input_files:
                        f.write(f"file '{os.path.abspath(video)}'\n")
                
                # 获取质量预设
                quality_preset = self.QUALITY_PRESETS.get(quality, self.QUALITY_PRESETS['medium'])
                codec_lib = 'libx265' if codec == 'h265' else 'libx264'
                
                cmd = [
                    'ffmpeg',
                    '-f', 'concat',
                    '-safe', '0',
                    '-i', str(list_file),
                    '-c:v', codec_lib,
                    '-crf', str(quality_preset['crf']),
                    '-preset', quality_preset['preset'],
                    '-c:a', 'copy',
                    '-y', output_file
                ]
                
                subprocess.run(cmd, check=True)
                list_file.unlink()  # 删除临时文件
                
            else:
                # 直接合并（无损）
                self.logger.info(f"🔗 直接合并 {len(input_files)} 个视频（无损）...")
                
                # 创建文件列表
                list_file = Path('temp_filelist.txt')
                with open(list_file, 'w', encoding='utf-8') as f:
                    for video in input_files:
                        f.write(f"file '{os.path.abspath(video)}'\n")
                
                cmd = [
                    'ffmpeg',
                    '-f', 'concat',
                    '-safe', '0',
                    '-i', str(list_file),
                    '-c', 'copy',
                    '-y', output_file
                ]
                
                subprocess.run(cmd, check=True)
                list_file.unlink()
            
            output_size = os.path.getsize(output_file)
            self.logger.info(f"✅ 合并完成: {output_file} ({self._format_size(output_size)})")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ 合并失败: {e}")
            return False
    
    def analyze_directory(self, directory: str, extensions: List[str] = None) -> Dict:
        """分析目录中的视频"""
        
        dir_path = Path(directory)
        if not dir_path.exists():
            self.logger.error(f"❌ 目录不存在: {directory}")
            return {}
        
        if extensions is None:
            extensions = self.config['video_extensions']
        else:
            extensions = ['.' + ext.lstrip('.') for ext in extensions]
        
        # 收集视频文件
        video_files = []
        for ext in extensions:
            video_files.extend(dir_path.rglob(f'*{ext}'))
        
        if not video_files:
            self.logger.warning("⚠️  未找到视频文件")
            return {}
        
        self.logger.info(f"📊 分析 {len(video_files)} 个视频文件...")
        
        # 统计信息
        analysis = {
            'total_files': len(video_files),
            'total_size': 0,
            'codecs': {},
            'resolutions': {},
            'total_duration': 0
        }
        
        for idx, video_file in enumerate(video_files, 1):
            info = self.get_video_info(str(video_file))
            if info:
                analysis['total_size'] += info['size']
                analysis['total_duration'] += info['duration']
                
                # 统计编码
                codec = info['codec']
                analysis['codecs'][codec] = analysis['codecs'].get(codec, 0) + 1
                
                # 统计分辨率
                resolution = f"{info['width']}x{info['height']}"
                analysis['resolutions'][resolution] = analysis['resolutions'].get(resolution, 0) + 1
            
            if idx % 10 == 0:
                print(f"  进度: {idx}/{len(video_files)}", end='\r')
        
        print()  # 换行
        
        # 打印分析结果
        self.logger.info(f"\n{'='*60}")
        self.logger.info(f"📊 视频分析报告")
        self.logger.info(f"{'='*60}")
        self.logger.info(f"文件总数: {analysis['total_files']}")
        self.logger.info(f"总大小: {self._format_size(analysis['total_size'])}")
        self.logger.info(f"总时长: {self._format_duration(analysis['total_duration'])}")
        self.logger.info(f"\n编码格式分布:")
        for codec, count in sorted(analysis['codecs'].items(), key=lambda x: x[1], reverse=True):
            self.logger.info(f"  {codec}: {count} 个")
        self.logger.info(f"\n分辨率分布:")
        for res, count in sorted(analysis['resolutions'].items(), key=lambda x: x[1], reverse=True):
            self.logger.info(f"  {res}: {count} 个")
        self.logger.info(f"{'='*60}\n")
        
        return analysis
    
    def _format_size(self, size: int) -> str:
        """格式化文件大小"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size < 1024.0:
                return f"{size:.2f} {unit}"
            size /= 1024.0
        return f"{size:.2f} PB"
    
    def _format_duration(self, seconds: float) -> str:
        """格式化时长"""
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = int(seconds % 60)
        return f"{hours:02d}:{minutes:02d}:{secs:02d}"
    
    def _print_stats(self):
        """打印统计信息"""
        self.logger.info(f"\n{'='*60}")
        self.logger.info(f"📊 处理统计")
        self.logger.info(f"{'='*60}")
        self.logger.info(f"总文件数: {self.stats['total_files']}")
        self.logger.info(f"已处理: {self.stats['processed']}")
        self.logger.info(f"已跳过: {self.stats['skipped']}")
        if self.stats['skipped_smart'] > 0:
            self.logger.info(f"  - 智能跳过: {self.stats['skipped_smart']} (已是目标编码且码率更低)")
        self.logger.info(f"失败: {self.stats['failed']}")
        
        if self.stats['processed'] > 0:
            saved = self.stats['total_size_before'] - self.stats['total_size_after']
            ratio = (saved / self.stats['total_size_before'] * 100) if self.stats['total_size_before'] > 0 else 0
            
            self.logger.info(f"\n处理前大小: {self._format_size(self.stats['total_size_before'])}")
            self.logger.info(f"处理后大小: {self._format_size(self.stats['total_size_after'])}")
            self.logger.info(f"节省空间: {self._format_size(saved)} ({ratio:.1f}%)")
        
        self.logger.info(f"{'='*60}\n")


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description='🔥 VideoForge - 视频熔炉',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    subparsers = parser.add_subparsers(dest='command', help='命令')
    
    # transcode 命令
    transcode_parser = subparsers.add_parser('transcode', help='转码视频')
    transcode_parser.add_argument('input', help='输入文件或目录')
    transcode_parser.add_argument('-o', '--output', required=True, help='输出文件或目录')
    transcode_parser.add_argument('--codec', choices=['h264', 'h265'], default='h265', help='编码格式')
    transcode_parser.add_argument('--quality', choices=['high', 'medium', 'low'], default='medium', help='质量预设')
    transcode_parser.add_argument('--preset', help='编码速度预设')
    transcode_parser.add_argument('--crf', type=int, help='CRF 值 (18-28)')
    transcode_parser.add_argument('--resolution', choices=['1080p', '720p', 'original'], help='目标分辨率')
    transcode_parser.add_argument('--extensions', help='文件扩展名（逗号分隔）')
    transcode_parser.add_argument('--skip-existing', action='store_true', help='跳过已存在的文件')
    transcode_parser.add_argument('--smart-skip', action='store_true', default=True, help='智能跳过（默认启用）：跳过已经是目标编码且码率更低的视频')
    transcode_parser.add_argument('--no-smart-skip', action='store_false', dest='smart_skip', help='禁用智能跳过')
    transcode_parser.add_argument('--dry-run', action='store_true', help='预览模式')
    
    # merge 命令
    merge_parser = subparsers.add_parser('merge', help='合并视频')
    merge_parser.add_argument('inputs', nargs='+', help='输入视频文件')
    merge_parser.add_argument('-o', '--output', required=True, help='输出文件')
    merge_parser.add_argument('--reencode', action='store_true', help='重新编码')
    merge_parser.add_argument('--codec', choices=['h264', 'h265'], default='h265', help='编码格式')
    merge_parser.add_argument('--quality', choices=['high', 'medium', 'low'], default='medium', help='质量预设')
    
    # analyze 命令
    analyze_parser = subparsers.add_parser('analyze', help='分析视频')
    analyze_parser.add_argument('input', help='输入目录')
    analyze_parser.add_argument('--extensions', help='文件扩展名（逗号分隔）')
    
    # 解析参数
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    # 创建 VideoForge 实例
    forge = VideoForge()
    
    # 检查 ffmpeg
    if not forge.check_ffmpeg():
        sys.exit(1)
    
    # 执行命令
    if args.command == 'transcode':
        input_path = Path(args.input)
        
        # 处理扩展名
        extensions = None
        if args.extensions:
            extensions = [ext.strip() for ext in args.extensions.split(',')]
        
        if input_path.is_file():
            # 单文件转码
            forge.transcode_video(
                args.input,
                args.output,
                codec=args.codec,
                quality=args.quality,
                preset=args.preset,
                crf=args.crf,
                resolution=args.resolution,
                smart_skip=args.smart_skip
            )
        else:
            # 目录转码
            forge.transcode_directory(
                args.input,
                args.output,
                codec=args.codec,
                quality=args.quality,
                preset=args.preset,
                crf=args.crf,
                resolution=args.resolution,
                extensions=extensions,
                skip_existing=args.skip_existing,
                dry_run=args.dry_run,
                smart_skip=args.smart_skip
            )
    
    elif args.command == 'merge':
        forge.merge_videos(
            args.inputs,
            args.output,
            reencode=args.reencode,
            codec=args.codec,
            quality=args.quality
        )
    
    elif args.command == 'analyze':
        extensions = None
        if args.extensions:
            extensions = [ext.strip() for ext in args.extensions.split(',')]
        
        forge.analyze_directory(args.input, extensions=extensions)


if __name__ == '__main__':
    main()
