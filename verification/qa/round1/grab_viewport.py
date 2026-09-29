"""Crop the Roblox Studio 3D viewport from a full-desktop ImageGrab."""
from pathlib import Path
import sys
from PIL import ImageGrab

out = Path(sys.argv[1])
# 2880x1800 desktop; Studio 3D view (measured from round1 desktop_test)
box = (690, 175, 2175, 1065)
im = ImageGrab.grab().crop(box)
out.parent.mkdir(parents=True, exist_ok=True)
im.save(out)
print(out, im.size)
