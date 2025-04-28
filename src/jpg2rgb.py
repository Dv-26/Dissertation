from PIL import Image
import numpy as np

img = Image.open("./test_img.png").convert('RGB')
width, height = img.size
pixels = np.array(img)

with open("./test_img.hex", 'w') as f:
    for y in range(height):
        for x in range(width):
            r, g, b = pixels[y,x]
            f.write(f"{r:02X}{g:02X}{b:02X}\n")

print(f"conversion successful! size: {width}*{height}")
