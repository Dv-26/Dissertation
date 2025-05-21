mport numpy as np
from PIL import Image

def create_y_only_jpeg(output_path):
    # 创建8x8的随机灰度数据
    y_data = np.random.randint(0, 256, (16, 8), dtype=np.uint8)
    # black_array = np.zeros((16, 16), dtype=np.uint8)
    # 转换为PIL图像
    img = Image.fromarray(y_data, mode='L')  # 'L'表示灰度
    
    # 标准亮度量化表
    luma_table = [
        16, 11, 10, 16, 24, 40, 51, 61,
        12, 12, 14, 19, 26, 58, 60, 55,
        14, 13, 16, 24, 40, 57, 69, 56,
        14, 17, 22, 29, 51, 87, 80, 62,
        18, 22, 37, 56, 68, 109, 103, 77,
        24, 35, 55, 64, 81, 104, 113, 92,
        49, 64, 78, 87, 103, 121, 120, 101,
        72, 92, 95, 98, 112, 100, 103, 99
    ]
    
    # 色度量化表（虽然不使用，但仍需提供）
    chroma_table = [
        17, 18, 24, 47, 99, 99, 99, 99,
        18, 21, 26, 66, 99, 99, 99, 99,
        24, 26, 56, 99, 99, 99, 99, 99,
        47, 66, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99
    ]
    
    # 保存为JPEG
    img.save(output_path,
             format='JPEG',
             quality=95,
             subsampling=0,  # 4:4:4 (无子采样)
             qtables=[luma_table, chroma_table])

# 生成图像
create_y_only_jpeg('y_only_8x8.jpg')
print("8x8 Y-only JPEG generated as y_only_8x8.jpg")
