"""Create distinct Android launchers from bundled Kidoza illustration.

Run after flutter create, which generates default mipmap icons.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math

ROOT = Path(__file__).resolve().parents[1]
APPS = [
    ("kids_learn", (253, 114, 180), (255, 212, 112), False),
    ("parent_control", (115, 85, 190), (119, 203, 241), True),
]
DENSITIES = {
    "mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144,
    "xxxhdpi": 192,
}

def make_icon(source, size, primary, secondary, shield):
    scale = 3
    dim = size * scale
    canvas = Image.new("RGBA", (dim, dim), (0, 0, 0, 0))
    px = canvas.load()
    for y in range(dim):
        blend = y / max(dim - 1, 1)
        for x in range(dim):
            variation = x / max(dim - 1, 1) * .16
            t = min(1, blend * .7 + variation)
            rgb = tuple(int(primary[i] * (1 - t) + secondary[i] * t) for i in range(3))
            px[x, y] = rgb + (255,)
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((int(dim*.055), int(dim*.055), int(dim*.945), int(dim*.945)),
                 fill=(255, 255, 255, 230))
    art = Image.open(source).convert("RGBA")
    diameter = int(dim*.77)
    art = art.resize((diameter, diameter), Image.Resampling.LANCZOS)
    mask = Image.new("L", (diameter, diameter), 0)
    ImageDraw.Draw(mask).ellipse((0,0,diameter-1,diameter-1), fill=255)
    art.putalpha(mask)
    canvas.alpha_composite(art, (int(dim*.115),int(dim*.115)))
    if shield:
        badge=(int(dim*.58),int(dim*.57),int(dim*.95),int(dim*.94))
        draw=ImageDraw.Draw(canvas)
        draw.ellipse(badge,fill=(255,255,255,255))
        cx,cy=int(dim*.76),int(dim*.745)
        points=[(cx,cy-int(dim*.125)),(cx+int(dim*.105),cy-int(dim*.085)),
                (cx+int(dim*.09),cy+int(dim*.075)),(cx,cy+int(dim*.145)),
                (cx-int(dim*.09),cy+int(dim*.075)),(cx-int(dim*.105),cy-int(dim*.085))]
        draw.polygon(points,fill=(87,61,159,255))
        draw.line([(cx-int(dim*.045),cy),(cx-int(dim*.01),cy+int(dim*.035)),
                   (cx+int(dim*.055),cy-int(dim*.045))],
                  fill=(255,255,255,255),width=max(2,int(dim*.025)))
    else:
        draw=ImageDraw.Draw(canvas)
        cx,cy=int(dim*.78),int(dim*.75)
        r=int(dim*.11)
        pts=[]
        for i in range(10):
            angle=-math.pi/2+math.pi*i/5
            radius=r if i%2==0 else r*.45
            pts.append((cx+math.cos(angle)*radius,cy+math.sin(angle)*radius))
        draw.polygon(pts,fill=(255,205,38,255),outline=(255,255,255,255))
    return canvas.resize((size,size),Image.Resampling.LANCZOS).convert("RGB")

for folder, primary, secondary, shield in APPS:
    app = ROOT / "apps" / folder
    source = app / "assets" / "kidoza.webp"
    assert source.exists(), source
    res = app / "android" / "app" / "src" / "main" / "res"
    for density, size in DENSITIES.items():
        path = res / ("mipmap-" + density) / "ic_launcher.png"
        path.parent.mkdir(parents=True,exist_ok=True)
        make_icon(source,size,primary,secondary,shield).save(path)
        print("Wrote",path)
