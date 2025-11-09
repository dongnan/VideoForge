#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试分辨率检测逻辑（包括2K/4K和横竖屏识别）
"""

from videoforge import VideoForge

def test_resolution_tier():
    """测试分辨率等级识别"""
    forge = VideoForge()
    
    test_cases = [
        # (width, height, expected_tier, expected_short_side)
        (1920, 1080, '1080p', 1080),     # 标准横屏 1080p
        (1080, 1920, '1080p', 1080),     # 竖屏 1080p
        (1280, 720, '720p', 720),        # 横屏 720p
        (720, 1280, '720p', 720),        # 竖屏 720p
        (2560, 1440, '2K', 1440),        # 横屏 2K
        (1440, 2560, '2K', 1440),        # 竖屏 2K
        (3840, 2160, '4K', 2160),        # 横屏 4K
        (2160, 3840, '4K', 2160),        # 竖屏 4K
        (640, 480, 'SD', 480),           # 低于 720p
    ]
    
    print("🧪 测试分辨率等级识别\n" + "="*60)
    for width, height, expected_tier, expected_short in test_cases:
        tier, short = forge._get_resolution_tier(width, height)
        status = "✅" if tier == expected_tier and short == expected_short else "❌"
        orientation = "竖屏" if height > width else "横屏"
        print(f"{status} {width}x{height} ({orientation}) → {tier} (短边:{short})")
        assert tier == expected_tier, f"期望 {expected_tier}, 实际 {tier}"
        assert short == expected_short, f"期望 {expected_short}, 实际 {short}"
    
    print(f"\n{'='*60}")
    print("✅ 所有测试通过！")


def show_bitrate_table():
    """显示各分辨率的码率估算表"""
    forge = VideoForge()
    
    resolutions = [
        ('4K', 3840, 2160),
        ('2K', 2560, 1440),
        ('1080p', 1920, 1080),
        ('720p', 1280, 720),
    ]
    
    crfs = [20, 23, 28]
    codecs = ['h264', 'h265']
    
    print("\n\n📊 码率估算表\n" + "="*100)
    
    for codec in codecs:
        print(f"\n### {codec.upper()} 编码 ###")
        print(f"{'分辨率':<10} | {'CRF 20':<20} | {'CRF 23':<20} | {'CRF 28':<20}")
        print("-" * 100)
        
        for name, width, height in resolutions:
            tier, shorter_side = forge._get_resolution_tier(width, height)
            bitrates = []
            
            for crf in crfs:
                # 模拟 should_skip_video 中的码率计算逻辑
                if codec == 'h264':
                    if crf <= 20:
                        base_bitrate = {2160: 20000000, 1440: 10000000, 1080: 5000000, 720: 3500000}
                        target_bitrate = base_bitrate.get(shorter_side, 5000000 * (shorter_side / 1080))
                    elif crf <= 23:
                        base_bitrate = {2160: 12000000, 1440: 6000000, 1080: 3000000, 720: 2000000}
                        target_bitrate = base_bitrate.get(shorter_side, 3000000 * (shorter_side / 1080))
                    else:
                        base_bitrate = {2160: 6000000, 1440: 3000000, 1080: 1500000, 720: 1000000}
                        target_bitrate = base_bitrate.get(shorter_side, 1500000 * (shorter_side / 1080))
                else:  # h265
                    if crf <= 20:
                        base_bitrate = {2160: 12000000, 1440: 6000000, 1080: 3000000, 720: 2000000}
                        target_bitrate = base_bitrate.get(shorter_side, 3000000 * (shorter_side / 1080))
                    elif crf <= 23:
                        base_bitrate = {2160: 7000000, 1440: 3500000, 1080: 1800000, 720: 1200000}
                        target_bitrate = base_bitrate.get(shorter_side, 1800000 * (shorter_side / 1080))
                    else:
                        base_bitrate = {2160: 3500000, 1440: 1800000, 1080: 900000, 720: 600000}
                        target_bitrate = base_bitrate.get(shorter_side, 900000 * (shorter_side / 1080))
                
                bitrates.append(f"{target_bitrate/1000000:.1f} Mbps")
            
            print(f"{name:<10} | {bitrates[0]:<20} | {bitrates[1]:<20} | {bitrates[2]:<20}")
    
    print("="*100)


if __name__ == '__main__':
    test_resolution_tier()
    show_bitrate_table()
