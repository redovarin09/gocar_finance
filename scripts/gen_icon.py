from PIL import Image, ImageDraw, ImageFont
import os

SIZE = 1024
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=220, fill=(0, 136, 13, 255))

cx, cy = SIZE // 2, SIZE // 2
cr = SIZE // 3
draw.ellipse([cx-cr, cy-cr, cx+cr, cy+cr], fill=(255, 255, 255, 245))

font_paths = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
]
font = None
for p in font_paths:
    if os.path.exists(p):
        try:
            font = ImageFont.truetype(p, 260)
            break
        except Exception:
            pass
if font is None:
    font = ImageFont.load_default()

text = "GF"
bbox = draw.textbbox((0, 0), text, font=font)
tw, th = bbox[2]-bbox[0], bbox[3]-bbox[1]
draw.text(((SIZE-tw)//2-bbox[0], (SIZE-th)//2-bbox[1]),
          text, fill=(0, 100, 8, 255), font=font)

os.makedirs('assets/icon', exist_ok=True)
img.save('assets/icon/icon.png')
print('Icon generated')
