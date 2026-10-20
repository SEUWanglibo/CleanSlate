"""把方形原图做成 macOS 风格应用图标（圆角方形 + 留白 + 阴影），并生成 AppIcon.icns。"""
import subprocess, sys, tempfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

src, out_icns = Path(sys.argv[1]), Path(sys.argv[2])
CANVAS, BODY, RADIUS = 1024, 824, 185  # Apple 图标网格：824px 主体、约 185px 圆角

art = Image.open(src).convert("RGBA").resize((BODY, BODY), Image.LANCZOS)
mask = Image.new("L", (BODY, BODY), 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, BODY - 1, BODY - 1), RADIUS, fill=255)
art.putalpha(mask)

offset = (CANVAS - BODY) // 2
shadow = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
shadow_mask = Image.new("L", (CANVAS, CANVAS), 0)
ImageDraw.Draw(shadow_mask).rounded_rectangle(
    (offset, offset + 10, offset + BODY, offset + BODY + 10), RADIUS, fill=90)
shadow.putalpha(shadow_mask.filter(ImageFilter.GaussianBlur(14)))

icon = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
icon.alpha_composite(shadow)
icon.alpha_composite(art, (offset, offset))

with tempfile.TemporaryDirectory() as tmp:
    iconset = Path(tmp) / "AppIcon.iconset"
    iconset.mkdir()
    for size in (16, 32, 128, 256, 512):
        icon.resize((size, size), Image.LANCZOS).save(iconset / f"icon_{size}x{size}.png")
        icon.resize((size * 2, size * 2), Image.LANCZOS).save(iconset / f"icon_{size}x{size}@2x.png")
    subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(out_icns)], check=True)
icon.save(out_icns.with_suffix(".png"))
print(f"Wrote {out_icns}")
