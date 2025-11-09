#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""测试文件大小预估功能"""

def test_size_estimation():
    """测试文件大小预估"""
    
    print("🧪 测试视频文件大小预估")
    print("=" * 60)
    
    # 测试案例
    test_cases = [
        {
            'name': '行车记录片段',
            'duration': 60,  # 60秒
            'current_size': 13 * 1024 * 1024,  # 13 MB
            'current_bitrate': 1.8 * 1000000,  # 1.8 Mbps
            'codec': 'h264',
            'target_bitrate_h264': 3 * 1000000,  # 3 Mbps
        },
        {
            'name': '大视频文件',
            'duration': 3 * 3600 + 29 * 60,  # 3小时29分
            'current_size': 29 * 1024 * 1024 * 1024,  # 29 GB
            'current_bitrate': 19.8 * 1000000,  # 19.8 Mbps
            'codec': 'h264',
            'target_bitrate_h264': 3 * 1000000,  # 3 Mbps
        },
        {
            'name': 'DJI视频',
            'duration': 10 * 60,  # 10分钟
            'current_size': 240 * 1024 * 1024,  # 240 MB
            'current_bitrate': 2.6 * 1000000,  # 2.6 Mbps
            'codec': 'h264',
            'target_bitrate_h264': 3 * 1000000,  # 3 Mbps
        },
    ]
    
    for case in test_cases:
        print(f"\n📹 {case['name']}")
        print("-" * 60)
        
        # 当前信息
        print(f"当前文件大小: {format_size(case['current_size'])}")
        print(f"当前码率: {case['current_bitrate'] / 1000000:.1f} Mbps")
        print(f"时长: {format_duration(case['duration'])}")
        
        # H.264 预估
        estimated_h264 = (case['target_bitrate_h264'] * case['duration'] / 8) * 1.1
        print(f"\nH.264 CRF 23 (3 Mbps):")
        print(f"  预估大小: {format_size(int(estimated_h264))}")
        print(f"  节省空间: {format_size(int(case['current_size'] - estimated_h264))}")
        print(f"  节省率: {(1 - estimated_h264 / case['current_size']) * 100:.1f}%")
        
        # 判断是否应该跳过
        if estimated_h264 >= case['current_size'] * 0.95:
            print(f"  ⏭️  建议跳过（预估大小 >= 原文件的 95%）")
        elif case['current_bitrate'] <= case['target_bitrate_h264']:
            print(f"  ⏭️  建议跳过（当前码率已低于目标）")
        else:
            print(f"  ✅  建议转码")
    
    print("\n" + "=" * 60)

def format_size(size):
    """格式化文件大小"""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size < 1024.0:
            return f"{size:.2f} {unit}"
        size /= 1024.0
    return f"{size:.2f} PB"

def format_duration(seconds):
    """格式化时长"""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    if hours > 0:
        return f"{hours}小时{minutes}分{secs}秒"
    elif minutes > 0:
        return f"{minutes}分{secs}秒"
    else:
        return f"{secs}秒"

if __name__ == '__main__':
    test_size_estimation()
